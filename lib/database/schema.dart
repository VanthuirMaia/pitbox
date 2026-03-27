import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Database? _db;

// abre ou cria o banco local
Future<Database> getDb() async {
  if (_db != null) return _db!;
  
  final caminho = await getDatabasesPath();
  final path = join(caminho, 'pitbox.db');
  
  _db = await openDatabase(
    path,
    version: 1,
    onCreate: _criarTabelas,
  );
  
  return _db!;
}

// cria todas as tabelas na primeira execução
Future<void> _criarTabelas(Database db, int version) async {
  await db.execute('''
    CREATE TABLE turno (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      inicio_em TEXT NOT NULL,
      fim_em TEXT,
      km_inicial REAL,
      km_final REAL,
      ganho_bruto REAL DEFAULT 0,
      status TEXT DEFAULT 'ativo',
      sincronizado INTEGER DEFAULT 0
    )
  ''');

  await db.execute('''
    CREATE TABLE rota (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      turno_id INTEGER NOT NULL,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      capturado_em TEXT NOT NULL,
      velocidade REAL,
      FOREIGN KEY (turno_id) REFERENCES turno(id)
    )
  ''');

  await db.execute('''
    CREATE TABLE abastecimento (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      turno_id INTEGER,
      data TEXT NOT NULL,
      litros REAL NOT NULL,
      valor_total REAL NOT NULL,
      posto TEXT,
      tipo_combustivel TEXT DEFAULT 'gasolina',
      sincronizado INTEGER DEFAULT 0
    )
  ''');

  await db.execute('''
    CREATE TABLE manutencao (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      data TEXT NOT NULL,
      descricao TEXT NOT NULL,
      valor REAL NOT NULL,
      km_atual REAL,
      oficina TEXT,
      sincronizado INTEGER DEFAULT 0
    )
  ''');

  await db.execute('''
    CREATE TABLE alimentacao (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      turno_id INTEGER,
      data TEXT NOT NULL,
      descricao TEXT,
      valor REAL NOT NULL,
      sincronizado INTEGER DEFAULT 0
    )
  ''');
}