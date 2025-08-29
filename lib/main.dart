import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen_webrtc_only.dart';
import 'services/webrtc_service_advanced.dart';

void main() {
  runApp(const WebRTCMirroringApp());
}

class WebRTCMirroringApp extends StatelessWidget {
  const WebRTCMirroringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WebRTCServiceAdvanced()),
      ],
      child: MaterialApp(
        title: 'WebRTC MirrorLink Pro',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F1419),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0F1419),
            elevation: 0,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
