enum OtpChannel { phone, email }

class OtpRouteArgs {
  const OtpRouteArgs({
    required this.destination,
    required this.verificationId,
    this.channel = OtpChannel.phone,
    this.returnTo,
    this.linkToCurrentAccount = false,
  });

  final String destination;
  final String verificationId;
  final OtpChannel channel;
  final String? returnTo;
  final bool linkToCurrentAccount;
  bool get isEmail => channel == OtpChannel.email;
}
