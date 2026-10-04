#!/usr/bin/env python3
"""Prepare local Brevo credentials; no sends, purchases, or cloud writes.

Run in your own terminal. API keys are collected with getpass, not arguments.
Only GET /account and GET /senders are used to check the key and sender.
"""

import argparse
import getpass
import json
import os
from pathlib import Path
import re
import secrets
import sys
import tempfile
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parent.parent
SECRET_FILE = ROOT / 'functions' / '.secret.local'
ENV_FILE = ROOT / 'functions' / '.env.rental-app-ad355'
EMAIL = re.compile(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')


class SetupError(Exception):
    pass


class NoRedirect(urllib.request.HTTPRedirectHandler):
    # Never forward an API key to a redirect destination.
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def read_values(path):
    if path.is_symlink():
        raise SetupError('Refusing to access a configuration symlink.')
    if not path.exists():
        return {}
    values = {}
    for line in path.read_text().splitlines():
        if line.strip() and not line.lstrip().startswith('#') and '=' in line:
            key, value = line.split('=', 1)
            values[key.strip()] = value.strip()
    return values


def atomic_write(path, values):
    if path.is_symlink():
        raise SetupError('Refusing to overwrite a configuration symlink.')
    fd, name = tempfile.mkstemp(prefix='.brevo-setup-', dir=path.parent)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, 'w') as stream:
            for key, value in values.items():
                if '\n' in key + value or '\r' in key + value:
                    raise SetupError('Configuration values must be single lines.')
                stream.write(f'{key}={value}\n')
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def brevo_get(endpoint, key):
    request = urllib.request.Request(
        'https://api.brevo.com/v3/' + endpoint,
        headers={'api-key': key, 'accept': 'application/json'}, method='GET',
    )
    try:
        with urllib.request.build_opener(NoRedirect).open(request, timeout=20) as response:
            result = json.loads(response.read())
        if not isinstance(result, dict):
            raise SetupError('Brevo returned an unexpected response. Try again later.')
        return result
    except urllib.error.HTTPError as error:
        # Inspect only known error categories; never print raw provider data.
        try:
            body = json.loads(error.read())
            message = str(body.get('message', '')).lower() if isinstance(body, dict) else ''
        except (ValueError, OSError):
            message = ''
        if 'ip' in message and any(word in message for word in ('unrecogn', 'unauthoriz', 'whitelist', 'authoriz', 'blocked')):
            raise SetupError('Brevo blocked this connection’s IP address. Review the Brevo security email or authorized IP settings, approve your own connection, and retry.') from None
        if error.code == 401:
            raise SetupError('Brevo rejected the API key (HTTP 401). Confirm it is active and copy its full value from API keys & MCP.') from None
        if error.code == 403:
            raise SetupError('Brevo denied API access (HTTP 403). Review authorized IP settings, API permissions, and account restrictions.') from None
        raise SetupError(f'Brevo account check failed (HTTP {error.code}). No message was sent.') from None
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
        raise SetupError('Could not reach Brevo. Check your connection and try again.') from None


def check_sender(key, sender):
    account = brevo_get('account', key)
    senders = brevo_get('senders', key).get('senders', [])
    match = next((item for item in senders if isinstance(item, dict)
                  and str(item.get('email', '')).lower() == sender.lower()), None)
    if match is None:
        raise SetupError('That email is not listed as a sender in this Brevo account. Add and verify it in Brevo first.')
    if match.get('active') is not True:
        raise SetupError('The sender is not active yet. Complete its verification in Brevo first.')
    print('API access and active email sender confirmed. No email or SMS was sent.')
    relay = account.get('relay', {})
    if isinstance(relay, dict) and relay.get('enabled') is False:
        print('Brevo reports transactional relay disabled. Resolve account activation with Brevo before live email setup.')
    plans = account.get('plan', [])
    if isinstance(plans, list):
        print('Free email plan reported: ' + ('yes' if any(isinstance(p, dict) and p.get('type') == 'free' for p in plans) else 'not confirmed; check your Brevo account'))


def status(check=False):
    values = read_values(SECRET_FILE)
    env = read_values(ENV_FILE)
    ready = bool(values.get('BREVO_API_KEY')) and len(values.get('OTP_HASH_KEY', '')) >= 32
    sender = env.get('OTP_EMAIL_SENDER', '')
    print('Local secrets prepared: ' + ('yes' if ready else 'no'))
    print('Email sender: ' + (sender or 'not configured'))
    print('Delivery enabled locally: ' + env.get('OTP_DELIVERY_ENABLED', 'false'))
    print('SMS enabled locally: ' + env.get('OTP_SMS_ENABLED', 'false'))
    print('This local status does not check cloud deployment or cloud secrets.')
    if check:
        if not ready or not EMAIL.fullmatch(sender):
            raise SetupError('Run the interactive setup first.')
        check_sender(values['BREVO_API_KEY'], sender)


def configure(sender=None):
    # getpass must not fall back to an echoed stdin read in an agent/tool console.
    if not sys.stdin.isatty() or not sys.stderr.isatty():
        raise SetupError('Run this command in your own interactive terminal. Never pass the API key as an argument or through chat.')
    env = read_values(ENV_FILE)
    if any(env.get(k, 'false').lower() == 'true' for k in ('OTP_DELIVERY_ENABLED', 'OTP_SMS_ENABLED')):
        raise SetupError('Delivery is already enabled in the local configuration. Review it before rerunning setup.')
    sender = (sender or input('Email address verified as a Brevo sender: ')).strip().lower()
    if len(sender) > 254 or not EMAIL.fullmatch(sender):
        raise SetupError('Enter a valid sender email address.')
    print('Paste your Brevo API key at the hidden prompt. Nothing appears while typing.')
    key = getpass.getpass('Brevo API key (hidden): ').strip()
    if not re.fullmatch(r'[A-Za-z0-9._-]{20,}', key):
        raise SetupError('The API key format is invalid. Use the API key, not an SMTP password.')
    check_sender(key, sender)
    values = read_values(SECRET_FILE)
    pepper = values.get('OTP_HASH_KEY')
    if pepper and len(pepper) < 32:
        raise SetupError('The existing OTP signing key is too short; review it before replacing it.')
    values['BREVO_API_KEY'] = key
    values['OTP_HASH_KEY'] = pepper or secrets.token_hex(32)
    env['OTP_EMAIL_SENDER'] = sender
    env.setdefault('OTP_SMS_SENDER', 'RentRide')
    env['OTP_DELIVERY_ENABLED'] = 'false'
    env['OTP_SMS_ENABLED'] = 'false'
    atomic_write(SECRET_FILE, values)
    atomic_write(ENV_FILE, env)
    print('Local setup saved with owner-only file permissions.')
    print('Delivery and SMS remain disabled. No cloud secret, deployment, or purchase was made.')
    print('Tell Codex: local Brevo setup completed. Do not share the secret file or API key.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sender', help='Verified sender email address (never an API key).')
    parser.add_argument('--status', action='store_true', help='Show sanitized local setup status.')
    parser.add_argument('--check', action='store_true', help='With --status, perform read-only Brevo account/sender checks.')
    args = parser.parse_args()
    if args.check and not args.status:
        parser.error('--check requires --status')
    try:
        if args.status:
            status(args.check)
        else:
            configure(args.sender)
    except SetupError as error:
        print(f'Setup stopped: {error}', file=sys.stderr)
        return 1
    except (KeyboardInterrupt, EOFError):
        print('\nSetup cancelled.', file=sys.stderr)
        return 1
    except Exception:
        # Never print a traceback that may expose provider responses or inputs.
        print('Setup stopped unexpectedly. Check local file permissions and retry. No deployment was performed.', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
