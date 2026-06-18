import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'modules/onboarding/splash_screen.dart';
import 'services/permission_service.dart';
import 'services/ble_controller_service.dart';
import 'services/ble_receiver_service.dart';
import 'services/gesture_detection_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        Provider<PermissionService>(create: (_) => PermissionService()),
        ChangeNotifierProvider<BleControllerService>(create: (_) => BleControllerService()),
        ChangeNotifierProvider<BleReceiverService>(create: (_) => BleReceiverService()),
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
    return MaterialApp(
      title: 'GesturLink',
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
