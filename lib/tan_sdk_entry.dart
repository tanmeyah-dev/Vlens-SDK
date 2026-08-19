import 'package:core/components/text/app_text.dart';
import 'package:core/style/app_colors.dart';
import 'package:core/utils/ui.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tan_sdk/utils/required_location_helper.dart';

import 'presenter/email_screen/scene/email_screen_scene.dart';
import 'presenter/home/scene/home_scene.dart';
import 'presenter/login_screen/scene/login_screen_scene.dart';
import 'presenter/login_screen/model/login_screen_nav_args.dart';
import 'presenter/validate_user/scene/validate_user_scene.dart';
import 'presenter/splash/scene/splash_scene.dart';
import 'presenter/register_screen/scene/register_screen_scene.dart';
import 'presenter/register_screen/model/register_screen_nav_args.dart';
import 'routes/route_path.dart';
import 'utils/sdk_navigator.dart';

/// Terracotta accent used on the location gate modal (matches product design).
const Color _kLocationGateAccent = Color(0xFFC95B50);

/// [pubspec.yaml] `name:` — required so assets resolve when the SDK runs inside a host app.
const String _tanSdkPackageName = 'tan_sdk';

/// Public SDK entry widget that owns the internal flow navigator.
///
/// Host apps should render this widget instead of wiring SDK routes manually.
/// Location services and permission must be granted and a GPS fix obtained
/// before the SDK flow is shown (Android: GPS on + permission; iOS: permission + fix).
///
/// [phoneNumber] is optional. When provided (e.g. from the host app's logged-in
/// user cache), it is prefilled on the validate-user screen.
///
/// [vlenseStatus] is optional. When `200`, the SDK opens the login screen
/// and after a successful login navigates to [RequestDocumentsScene].
///
/// [onCompleted] is optional. Host apps can use it to leave the SDK
/// (for example, open the CMA main screen).
class TanSdkEntry extends StatefulWidget {
  final String? phoneNumber;
  final String? vlenseStatus;
  final VoidCallback? onCompleted;

  const TanSdkEntry({
    super.key,
    this.phoneNumber,
    this.vlenseStatus,
    this.onCompleted,
  });

  @override
  State<TanSdkEntry> createState() => _TanSdkEntryState();
}

class _TanSdkEntryState extends State<TanSdkEntry> with WidgetsBindingObserver {
  bool _checking = true;
  RequiredLocationResult? _failure;

  @override
  void initState() {
    super.initState();
    SdkNavigator.onCompleted = widget.onCompleted;
    WidgetsBinding.instance.addObserver(this);
    _runLocationGate();
  }

  @override
  void didUpdateWidget(covariant TanSdkEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onCompleted != widget.onCompleted) {
      SdkNavigator.onCompleted = widget.onCompleted;
    }
  }

  @override
  void dispose() {
    if (SdkNavigator.onCompleted == widget.onCompleted) {
      SdkNavigator.onCompleted = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        mounted &&
        !_checking &&
        _failure != null) {
      _runLocationGate();
    }
  }

  Future<void> _runLocationGate() async {
    setState(() {
      _checking = true;
      _failure = null;
    });
    final result = await RequiredLocationHelper.acquire();
    if (!mounted) return;
    if (result.hasCoordinates) {
      setState(() {
        _checking = false;
        _failure = null;
      });
    } else {
      setState(() {
        _checking = false;
        _failure = result;
      });
    }
  }

  Future<void> _openSystemLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> _openBlockedSettings(LocationGateIssue issue) async {
    switch (issue) {
      case LocationGateIssue.serviceDisabled:
      case LocationGateIssue.positionError:
        await _openSystemLocationSettings();
        break;
      default:
        await _openAppSettings();
        break;
    }
  }

  Widget _buildSdkNavigator(MediaQueryData? mediaQuery) {
    final navigator = Navigator(
      key: SdkNavigator.key,
      initialRoute: RoutePath.splash,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case RoutePath.splash:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => SplashScene(
                phoneNumber: widget.phoneNumber,
                vlenseStatus: widget.vlenseStatus,
              ),
            );
          case RoutePath.validateUser:
            final phoneFromArgs = settings.arguments is String
                ? (settings.arguments as String).trim()
                : null;
            final phoneNumber = (phoneFromArgs != null && phoneFromArgs.isNotEmpty)
                ? phoneFromArgs
                : widget.phoneNumber?.trim();
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => ValidateUser(
                initialPhoneNumber:
                    phoneNumber != null && phoneNumber.isNotEmpty
                        ? phoneNumber
                        : null,
              ),
            );
          case RoutePath.loginScreen:
            final args = settings.arguments;
            String? phoneFromArgs;
            String? vlenseStatus = widget.vlenseStatus;
            if (args is LoginScreenNavArgs) {
              phoneFromArgs = args.phoneNumber;
              vlenseStatus = args.vlenseStatus ?? vlenseStatus;
            } else if (args is String && args.trim().isNotEmpty) {
              phoneFromArgs = args.trim();
            }
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => LoginScreenScene(
                initialPhoneNumber: phoneFromArgs ?? widget.phoneNumber,
                vlenseStatus: vlenseStatus,
              ),
            );
          case RoutePath.emailScreen:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const EmailScreenScene(),
            );
          case RoutePath.registerScreen:
            final args = settings.arguments;
            String? verifiedEmail;
            String? oauthTokenVerificationRequestId;
            String? emailOtpRequestId;
            if (args is RegisterScreenNavArgs) {
              verifiedEmail = args.verifiedEmail?.trim();
              oauthTokenVerificationRequestId =
                  args.oauthTokenVerificationRequestId?.trim();
              emailOtpRequestId = args.emailOtpRequestId?.trim();
            } else if (args is String) {
              verifiedEmail = args.trim();
            }
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => RegisterScreen(
                verifiedEmail:
                    verifiedEmail != null && verifiedEmail.isNotEmpty
                        ? verifiedEmail
                        : null,
                oauthTokenVerificationRequestId:
                    oauthTokenVerificationRequestId,
                emailOtpRequestId:
                    emailOtpRequestId != null && emailOtpRequestId.isNotEmpty
                        ? emailOtpRequestId
                        : null,
              ),
            );
          case RoutePath.home:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const HomeScene(),
            );
          default:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => SplashScene(
                phoneNumber: widget.phoneNumber,
                vlenseStatus: widget.vlenseStatus,
              ),
            );
        }
      },
    );

    if (mediaQuery == null) {
      return navigator;
    }

    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: const TextScaler.linear(1.0),
      ),
      child: navigator,
    );
  }

  Widget _buildBlockedScaffold(RequiredLocationResult failure) {
    final issue = failure.issue;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final imageHeight =
                        (constraints.maxHeight * 0.42).clamp(160.0, 300.0);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: imageHeight,
                                  width: double.infinity,
                                  child: Image.asset(
                                    AppAssets.locationPermission,
                                    package: _tanSdkPackageName,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                const Text(
                                  'يرجى تفعيل خاصية تحديد\nالموقع',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    height: 1.45,
                                    color: _kLocationGateAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kLocationGateAccent,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => _openBlockedSettings(issue),
                        child: const Text('الإعدادات'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);

    if (_checking) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.white,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 24),
                AppText(
                  'جاري التحقق من الموقع…',
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final failure = _failure;
    if (failure != null && !failure.hasCoordinates) {
      return _buildBlockedScaffold(failure);
    }

    return _buildSdkNavigator(mediaQuery);
  }
}
