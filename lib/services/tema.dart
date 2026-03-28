import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyTema = 'pitbox_tema';

// notifier global do tema
final temaNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

// carrega o tema salvo
Future<void> carregarTema() async {
  final prefs = await SharedPreferences.getInstance();
  final salvo = prefs.getString(_keyTema);
  if (salvo == 'claro') {
    temaNotifier.value = ThemeMode.light;
  } else if (salvo == 'escuro') {
    temaNotifier.value = ThemeMode.dark;
  } else {
    temaNotifier.value = ThemeMode.system;
  }
}

// salva e aplica o tema
Future<void> definirTema(ThemeMode modo) async {
  temaNotifier.value = modo;
  final prefs = await SharedPreferences.getInstance();
  if (modo == ThemeMode.light) {
    await prefs.setString(_keyTema, 'claro');
  } else if (modo == ThemeMode.dark) {
    await prefs.setString(_keyTema, 'escuro');
  } else {
    await prefs.setString(_keyTema, 'sistema');
  }
}

// cores do tema escuro
class CoresEscuro {
  static const bg = Color(0xFF0D0D0D);
  static const card = Color(0xFF161616);
  static const borda = Color(0xFF222222);
  static const amarelo = Color(0xFFE8FF00);
  static const branco = Color(0xFFF5F5F5);
  static const cinza = Color(0xFF666666);
  static const verde = Color(0xFF44FF88);
  static const vermelho = Color(0xFFFF4444);
  static const inputFundo = Color(0xFF1A1A1A);
  static const inputTexto = Color(0xFFF5F5F5);
}

// cores do tema claro
class CoresClaro {
  static const bg = Color(0xFFF5F5F5);
  static const card = Color(0xFFFFFFFF);
  static const borda = Color(0xFFDDDDDD);
  static const amarelo = Color(0xFFB8CC00);  // amarelo mais escuro pra contraste no claro
  static const branco = Color(0xFF111111);   // texto escuro no claro
  static const cinza = Color(0xFF888888);
  static const verde = Color(0xFF1A8A44);
  static const vermelho = Color(0xFFCC2222);
  static const inputFundo = Color(0xFFFFFFFF);
  static const inputTexto = Color(0xFF111111);
}

// retorna as cores corretas baseado no contexto
class Cores {
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? CoresEscuro.bg : CoresClaro.bg;
  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? CoresEscuro.card : CoresClaro.card;
  static Color borda(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? CoresEscuro.borda : CoresClaro.borda;
  static Color amarelo(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? CoresEscuro.amarelo : CoresClaro.amarelo;
  static Color texto(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? CoresEscuro.branco : CoresClaro.branco;
  static Color cinza(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? CoresEscuro.cinza : CoresClaro.cinza;
  static Color verde(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? CoresEscuro.verde : CoresClaro.verde;
  static Color vermelho(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? CoresEscuro.vermelho : CoresClaro.vermelho;
  static Color inputFundo(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? CoresEscuro.inputFundo : CoresClaro.inputFundo;
  static Color inputTexto(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? CoresEscuro.inputTexto : CoresClaro.inputTexto;
}