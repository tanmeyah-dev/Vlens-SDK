import 'package:flutter/material.dart';

late GlobalKey<NavigatorState> navigatorKey;
late BuildContext appContext;

coreInit(Core core) {
  navigatorKey = core.getNavigatorKey();
  appContext = core.getContext();
}

coreInit2(BuildContext context) {
  appContext = context;
}

abstract class Core {
  BuildContext getContext();

  GlobalKey<NavigatorState> getNavigatorKey();
}

