/// Google OAuth client IDs for Sign in with Google → Vlens IdToken verification.
class GoogleOAuthConfig {
  GoogleOAuthConfig._();

  /// Android OAuth client (package: com.tanmeyah.app).
  /// In Google Cloud Console, add both debug + release SHA-1 fingerprints:
  /// - debug:  1C:4B:3A:BA:37:B9:66:39:C0:FB:B4:E8:0F:7F:7B:96:3B:A3:21:79
  /// - release: F1:88:FD:81:10:40:E6:C0:88:0D:7A:1F:44:00:6D:AE:DF:6E:10:DB
  static const String androidClientId =
      '310544200746-7p5d6c9arnml28ifvum06ci9hvsm77bt.apps.googleusercontent.com';

  /// iOS OAuth client (bundle: com.tanmeyah.customerApp).
  static const String iosClientId =
      '310544200746-ipahem5reva3j927ppjdjmlt4htjhoq2.apps.googleusercontent.com';

  /// Audience for IdToken (`serverClientId`) — must be a Web OAuth client
  /// (`client_type: 3` in google-services.json). Android Credential Manager
  /// rejects Android/iOS client IDs here with [28444].
  static const String serverClientId =
      '310544200746-ffrarg4oea0rcl81fao5mnvkvtn5k1c7.apps.googleusercontent.com';

  /// iOS URL scheme (`REVERSED_CLIENT_ID`) — must exist in host Info.plist.
  static const String iosReversedClientId =
      'com.googleusercontent.apps.310544200746-ipahem5reva3j927ppjdjmlt4htjhoq2';
}
