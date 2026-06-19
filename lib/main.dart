import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

import 'core/theme.dart';
import 'modules/onboarding/splash_screen.dart';
import 'services/permission_service.dart';
import 'services/p2p_connection_service.dart';
import 'services/gesture_detection_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        Provider<PermissionService>(create: (_) => PermissionService()),
        ChangeNotifierProvider<P2pConnectionService>(create: (_) => P2pConnectionService()),
        ChangeNotifierProvider<GestureDetectionService>(create: (_) => GestureDetectionService()),
      ],
      child: const GesturLinkApp(),
    ),
  );
}


class GesturLinkApp extends StatelessWidget {
  const GesturLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => MaterialApp(
        title: 'GesturLink',
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
