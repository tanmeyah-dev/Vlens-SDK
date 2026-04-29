import 'package:flutter/material.dart';

import 'presenter/email_input/scene/email_input_scene.dart';
import 'presenter/home/scene/home_scene.dart';
import 'presenter/loginscreen/scene/loginscreen_scene.dart';
import 'presenter/mobile_number/scene/mobile_number_scene.dart';
import 'presenter/splash/scene/splash_scene.dart';
import 'presenter/username_security_code/scene/username_security_code_scene.dart';
import 'routes/route_path.dart';

/// Public SDK entry widget that owns the internal flow navigator.
///
/// Host apps should render this widget instead of wiring SDK routes manually.
class TanSdkEntry extends StatelessWidget {
  const TanSdkEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final navigator = Navigator(
      initialRoute: RoutePath.splash,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case RoutePath.splash:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const SplashScene(),
            );
          case RoutePath.mobileNumber:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const MobileNumberScene(),
            );
          case RoutePath.loginScreen:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const LoginScreenScene(),
            );
          case RoutePath.emailInput:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const EmailInputScene(),
            );
          case RoutePath.usernameSecurityCode:
            final verifiedEmail = settings.arguments is String
                ? (settings.arguments as String).trim()
                : null;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => RegisterScene(
                verifiedEmail:
                    verifiedEmail != null && verifiedEmail.isNotEmpty
                        ? verifiedEmail
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
              builder: (_) => const SplashScene(),
            );
        }
      },
    );

    if (mediaQuery == null) {
      return navigator;
    }

    // Keep SDK flow layout stable for third-party pages with fixed vertical constraints.
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: const TextScaler.linear(1.0),
      ),
      child: navigator,
    );
  }
}
