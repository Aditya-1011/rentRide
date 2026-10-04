import 'dart:convert';

import 'otp_route_args.dart';

/// Preserve OTP navigation data when GoRouter refreshes after Firebase sign-in.
/// The entered OTP and authentication tokens are never included in route data.
class AuthRouteExtraCodec extends Codec<Object?, Object?> {
  const AuthRouteExtraCodec();

  @override
  Converter<Object?, Object?> get encoder => const _AuthExtraEncoder();

  @override
  Converter<Object?, Object?> get decoder => const _AuthExtraDecoder();
}

class _AuthExtraEncoder extends Converter<Object?, Object?> {
  const _AuthExtraEncoder();

  @override
  Object? convert(Object? input) {
    if (input is OtpRouteArgs) {
      return {
        'type': 'otp',
        'destination': input.destination,
        'verificationId': input.verificationId,
        'channel': input.channel.name,
        'returnTo': input.returnTo,
        'linkToCurrentAccount': input.linkToCurrentAccount,
      };
    }
    return input;
  }
}

class _AuthExtraDecoder extends Converter<Object?, Object?> {
  const _AuthExtraDecoder();

  @override
  Object? convert(Object? input) {
    if (input is Map && input['type'] == 'otp') {
      final destination = input['destination'];
      final verificationId = input['verificationId'];
      final channel = input['channel'];
      if (destination is! String ||
          verificationId is! String ||
          !['email', 'phone'].contains(channel)) {
        return null;
      }
      return OtpRouteArgs(
        destination: destination,
        verificationId: verificationId,
        channel: channel == 'email' ? OtpChannel.email : OtpChannel.phone,
        returnTo: input['returnTo'] is String
            ? input['returnTo'] as String
            : null,
        linkToCurrentAccount: input['linkToCurrentAccount'] == true,
      );
    }
    return input;
  }
}
