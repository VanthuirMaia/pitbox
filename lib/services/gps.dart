import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/queries.dart';

const _keyTurnoId = 'pitbox_turno_id_ativo';
const _taskGps = 'pitbox_gps_task';

// função chamada pelo workmanager em segundo plano
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == _taskGps) {
      final prefs = await SharedPreferences.getInstance();
      final turnoId = prefs.getInt(_keyTurnoId);
      if (turnoId == null) return true;

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );
        await salvarPontoGps(
          turnoId,
          position.latitude,
          position.longitude,
          velocidade: position.speed,
        );
      } catch (e) {
        // silencia erro momentâneo
      }
    }
    return true;
  });
}

// solicita permissões de GPS
Future<bool> solicitarPermissaoGps() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return false;

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return false;
  }

  if (permission == LocationPermission.deniedForever) return false;
  return true;
}

// inicializa o workmanager (chama no main)
Future<void> inicializarServicoBackground() async {
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
}

// inicia rastreamento
Future<bool> iniciarRastreamento(int turnoId) async {
  final temPermissao = await solicitarPermissaoGps();
  if (!temPermissao) return false;

  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_keyTurnoId, turnoId);

  // agenda task periódica a cada 15 minutos (limite mínimo do workmanager)
  await Workmanager().registerPeriodicTask(
    _taskGps,
    _taskGps,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.not_required),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );

  return true;
}

// para rastreamento
Future<void> pararRastreamento() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_keyTurnoId);
  await Workmanager().cancelByUniqueName(_taskGps);
}

// workmanager não tem status em tempo real, verifica pelo SharedPreferences
Future<bool> estaRastreando() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.containsKey(_keyTurnoId);
}