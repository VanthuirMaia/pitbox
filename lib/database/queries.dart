import 'schema.dart';

// ── TURNO ──────────────────────────────────────────────

Future<int> iniciarTurno({double? kmInicial, String? plataforma}) async {
  final db = await getDb();
  final agora = DateTime.now().toIso8601String();
  return await db.insert('turno', {
    'inicio_em': agora,
    'km_inicial': kmInicial,
    'status': 'ativo',
    'plataforma': plataforma,
  });
}

Future<void> finalizarTurno(int turnoId, {double? kmFinal, double? ganhoBruto, int? totalCorridas}) async {
  final db = await getDb();
  final agora = DateTime.now().toIso8601String();
  await db.update(
    'turno',
    {
      'fim_em': agora,
      'km_final': kmFinal,
      'ganho_bruto': ganhoBruto ?? 0,
      'status': 'finalizado',
      'total_corridas': totalCorridas,
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
      COALESCE(SUM(
        CASE WHEN km_final IS NOT NULL AND km_inicial IS NOT NULL 
        THEN km_final - km_inicial ELSE 0 END
      ), 0) as km_total,
      COALESCE(SUM(
        CASE WHEN fim_em IS NOT NULL 
        THEN (strftime('%s', fim_em) - strftime('%s', inicio_em)) / 3600.0
        ELSE 0 END
      ), 0) as horas_total
    FROM turno 
    WHERE status = 'finalizado'
      AND date(inicio_em) BETWEEN ? AND ?
  ''', [dataInicio, dataFim]);

  return result.first;
}

// migração: adiciona colunas novas sem perder dados
Future<void> migrarBanco() async {
  final db = await getDb();
  try {
    await db.execute('ALTER TABLE turno ADD COLUMN plataforma TEXT');
  } catch (_) {}
  try {
    await db.execute('ALTER TABLE turno ADD COLUMN total_corridas INTEGER');
  } catch (_) {}
  try {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS turno_plataforma (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        turno_id INTEGER NOT NULL,
        plataforma TEXT NOT NULL,
        corridas INTEGER DEFAULT 0,
        ganho REAL DEFAULT 0,
        FOREIGN KEY (turno_id) REFERENCES turno(id)
      )
    ''');
  } catch (_) {}
}

// salva ganho por plataforma
Future<void> salvarGanhoPorPlataforma(int turnoId, String plataforma, int corridas, double ganho) async {
  final db = await getDb();
  await db.insert('turno_plataforma', {
    'turno_id': turnoId,
    'plataforma': plataforma,
    'corridas': corridas,
    'ganho': ganho,
  });
}

// busca ganhos por plataforma de um turno
Future<List<Map<String, dynamic>>> buscarGanhosPorPlataforma(int turnoId) async {
  final db = await getDb();
  return await db.query(
    'turno_plataforma',
    where: 'turno_id = ?',
    whereArgs: [turnoId],
  );
}

// cancela o turno ativo sem salvar
Future<void> cancelarTurno(int turnoId) async {
  final db = await getDb();
  await db.delete('turno', where: 'id = ?', whereArgs: [turnoId]);
  await db.delete('rota', where: 'turno_id = ?', whereArgs: [turnoId]);
}

// exclui turno finalizado e todos os dados relacionados
Future<void> excluirTurno(int turnoId) async {
  final db = await getDb();
  await db.delete('turno_plataforma', where: 'turno_id = ?', whereArgs: [turnoId]);
  await db.delete('rota', where: 'turno_id = ?', whereArgs: [turnoId]);
  await db.delete('turno', where: 'id = ?', whereArgs: [turnoId]);
}

// busca turno por id
Future<Map<String, dynamic>?> buscarTurnoPorId(int id) async {
  final db = await getDb();
  final result = await db.query('turno', where: 'id = ?', whereArgs: [id], limit: 1);
  return result.isNotEmpty ? result.first : null;
}

// atualiza turno finalizado
Future<void> atualizarTurno(int turnoId, {
  String? inicioEm,
  String? fimEm,
  double? kmInicial,
  double? kmFinal,
  double? ganhoBruto,
  int? totalCorridas,
}) async {
  final db = await getDb();
  final dados = <String, dynamic>{};
  if (inicioEm != null) dados['inicio_em'] = inicioEm;
  if (fimEm != null) dados['fim_em'] = fimEm;
  if (kmInicial != null) dados['km_inicial'] = kmInicial;
  if (kmFinal != null) dados['km_final'] = kmFinal;
  if (ganhoBruto != null) dados['ganho_bruto'] = ganhoBruto;
  if (totalCorridas != null) dados['total_corridas'] = totalCorridas;
  if (dados.isEmpty) return;
  await db.update('turno', dados, where: 'id = ?', whereArgs: [turnoId]);
}

// deleta ganhos por plataforma de um turno para re-inserir
Future<void> limparGanhosPorPlataforma(int turnoId) async {
  final db = await getDb();
  await db.delete('turno_plataforma', where: 'turno_id = ?', whereArgs: [turnoId]);
}