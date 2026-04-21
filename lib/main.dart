import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/gps.dart';
import 'services/tema.dart';
import 'database/queries.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await inicializarServicoBackground();
  await migrarBanco();
  await carregarTema();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const PitBoxApp());
}

class PitBoxApp extends StatelessWidget {
  const PitBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: temaNotifier,
      builder: (context, modo, _) {
        return MaterialApp(
          title: 'PitBox',
          debugShowCheckedModeBanner: false,
          themeMode: modo,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('pt', 'BR'),
          ],
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: CoresClaro.bg,
            colorScheme: ColorScheme.fromSeed(
              seedColor: CoresClaro.amarelo,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: CoresEscuro.bg,
            colorScheme: ColorScheme.fromSeed(
              seedColor: CoresEscuro.amarelo,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}