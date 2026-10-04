#!/usr/bin/env python3
"""Retired setup helper; RentRide selected Brevo instead of Gmail SMTP."""

import sys


def main() -> None:
    sys.exit(
        'This Gmail setup helper is retired. RentRide selected Brevo. '
        'Do not enter Gmail credentials here; the Brevo backend setup '
        'will be documented after the hosting choice is made.'
    )


if __name__ == '__main__':
    main()
