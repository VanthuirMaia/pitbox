import 'schema.dart';

// ── TURNO ──────────────────────────────────────────────

Future<int> iniciarTurno({double? kmInicial}) async {
  final db = await getDb();
  final agora = DateTime.now().toIso8601String();
  return await db.insert('turno', {
    'inicio_em': agora,
    'km_inicial': kmInicial,
    'status': 'ativo',
  });
}

Future<void> finalizarTurno(int turnoId, {double? kmFinal, double? ganhoBruto}) async {
  final db = await getDb();
  final agora = DateTime.now().toIso8601String();
  await db.update(
    'turno',
    {
      'fim_em': agora,
      'km_final': kmFinal,
      'ganho_bruto': ganhoBruto ?? 0,
      'status': 'finalizado',
    },
    where: 'id = ?',
    whereArgs: [turnoId],
  );
}

Future<Map<String, dynamic>?> buscarTurnoAtivo() async {
  final db = await getDb();
  final result = await db.query(
    'turno',
    where: 'status = ?',
    whereArgs: ['ativo'],
    limit: 1,
  );
  return result.isNotEmpty ? result.first : null;
}

Future<List<Map<String, dynamic>>> listarTurnos({int limite = 30}) async {
  final db = await getDb();
  return await db.query(
    'turno',
    where: 'status = ?',
    whereArgs: ['finalizado'],
    orderBy: 'inicio_em DESC',
    limit: limite,
  );
}

// ── ROTA GPS ───────────────────────────────────────────

Future<void> salvarPontoGps(int turnoId, double lat, double lng, {double? velocidade}) async {
  final db = await getDb();
  await db.insert('rota', {
    'turno_id': turnoId,
    'latitude': lat,
    'longitude': lng,
    'capturado_em': DateTime.now().toIso8601String(),
    'velocidade': velocidade,
  });
}

Future<List<Map<String, dynamic>>> buscarRotaTurno(int turnoId) async {
  final db = await getDb();
  return await db.query(
    'rota',
    where: 'turno_id = ?',
    whereArgs: [turnoId],
    orderBy: 'capturado_em ASC',
  );
}

// ── ABASTECIMENTO ──────────────────────────────────────

Future<void> registrarAbastecimento({
  int? turnoId,
  required double litros,
  required double valorTotal,
  String? posto,
  String tipoCombustivel = 'gasolina',
}) async {
  final db = await getDb();
  await db.insert('abastecimento', {
    'turno_id': turnoId,
    'data': DateTime.now().toIso8601String(),
    'litros': litros,
    'valor_total': valorTotal,
    'posto': posto,
    'tipo_combustivel': tipoCombustivel,
  });
}

Future<List<Map<String, dynamic>>> listarAbastecimentos({int limite = 50}) async {
  final db = await getDb();
  return await db.query('abastecimento', orderBy: 'data DESC', limit: limite);
}

// ── MANUTENÇÃO ─────────────────────────────────────────

Future<void> registrarManutencao({
  required String descricao,
  required double valor,
  double? kmAtual,
  String? oficina,
}) async {
  final db = await getDb();
  await db.insert('manutencao', {
    'data': DateTime.now().toIso8601String(),
    'descricao': descricao,
    'valor': valor,
    'km_atual': kmAtual,
    'oficina': oficina,
  });
}

Future<List<Map<String, dynamic>>> listarManutencoes({int limite = 50}) async {
  final db = await getDb();
  return await db.query('manutencao', orderBy: 'data DESC', limit: limite);
}

// ── ALIMENTAÇÃO ────────────────────────────────────────

Future<void> registrarAlimentacao({
  int? turnoId,
  String? descricao,
  required double valor,
}) async {
  final db = await getDb();
  await db.insert('alimentacao', {
    'turno_id': turnoId,
    'data': DateTime.now().toIso8601String(),
    'descricao': descricao,
    'valor': valor,
  });
}

Future<List<Map<String, dynamic>>> listarAlimentacao({int limite = 50}) async {
  final db = await getDb();
  return await db.query('alimentacao', orderBy: 'data DESC', limit: limite);
}

// ── GASTOS DO DIA ──────────────────────────────────────

Future<Map<String, double>> totalGastosDia(String data) async {
  final db = await getDb();

  final combustivel = await db.rawQuery(
    "SELECT COALESCE(SUM(valor_total), 0) as total FROM abastecimento WHERE date(data) = ?",
    [data],
  );
  final manutencao = await db.rawQuery(
    "SELECT COALESCE(SUM(valor), 0) as total FROM manutencao WHERE date(data) = ?",
    [data],
  );
  final alimentacao = await db.rawQuery(
    "SELECT COALESCE(SUM(valor), 0) as total FROM alimentacao WHERE date(data) = ?",
    [data],
  );

  final c = (combustivel.first['total'] as num).toDouble();
  final m = (manutencao.first['total'] as num).toDouble();
  final a = (alimentacao.first['total'] as num).toDouble();

  return {'combustivel': c, 'manutencao': m, 'alimentacao': a, 'total': c + m + a};
}

// ── RESUMO DO PERÍODO ──────────────────────────────────

Future<Map<String, dynamic>> resumoPeriodo(String dataInicio, String dataFim) async {
  final db = await getDb();
  final result = await db.rawQuery('''
    SELECT 
      COUNT(*) as total_turnos,
      COALESCE(SUM(ganho_bruto), 0) as ganho_total,
      COALESCE(SUM(km_final - km_inicial), 0) as km_total,
      COALESCE(
        SUM((julianday(fim_em) - julianday(inicio_em)) * 24), 0
      ) as horas_total
    FROM turno 
    WHERE status = 'finalizado'
      AND date(inicio_em) BETWEEN ? AND ?
  ''', [dataInicio, dataFim]);

  return result.first;
}