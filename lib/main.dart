import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/gps.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // inicializa serviço de background
  await inicializarServicoBackground();
  
  // força orientação portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // barra de status escura
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF0D0D0D),
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const PitBoxApp());
}

class PitBoxApp extends StatelessWidget {
  const PitBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PitBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8FF00),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}