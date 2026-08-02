import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../data/models/holding_model.dart';
import '../../data/models/transaction_model.dart';

/// All simulation data lives locally on-device. No backend cost, works offline.
class LocalDbService {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'stockshaala.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE holdings(
            symbol TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            avg_buy_price REAL NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            symbol TEXT NOT NULL,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            price REAL NOT NULL,
            timestamp INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE wallet(
            id INTEGER PRIMARY KEY,
            cash REAL NOT NULL
          )''');
      },
    );
  }

  // ── Wallet ──
  Future<double> getCash(double startingCash) async {
    final db = await database;
    final rows = await db.query('wallet', where: 'id = 1');
    if (rows.isEmpty) {
      await db.insert('wallet', {'id': 1, 'cash': startingCash});
      return startingCash;
    }
    return (rows.first['cash'] as num).toDouble();
  }

  Future<void> setCash(double cash) async {
    final db = await database;
    await db.insert(
      'wallet',
      {'id': 1, 'cash': cash},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Holdings ──
  Future<List<Holding>> getHoldings() async {
    final db = await database;
    final rows = await db.query('holdings');
    return rows.map(Holding.fromMap).toList();
  }

  Future<Holding?> getHolding(String symbol) async {
    final db = await database;
    final rows =
        await db.query('holdings', where: 'symbol = ?', whereArgs: [symbol]);
    if (rows.isEmpty) return null;
    return Holding.fromMap(rows.first);
  }

  Future<void> upsertHolding(Holding h) async {
    final db = await database;
    await db.insert('holdings', h.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteHolding(String symbol) async {
    final db = await database;
    await db.delete('holdings', where: 'symbol = ?', whereArgs: [symbol]);
  }

  // ── Transactions ──
  Future<void> addTransaction(TradeTransaction t) async {
    final db = await database;
    await db.insert('transactions', t.toMap());
  }

  Future<List<TradeTransaction>> getTransactions() async {
    final db = await database;
    final rows = await db.query('transactions', orderBy: 'timestamp DESC');
    return rows.map(TradeTransaction.fromMap).toList();
  }

  Future<int> transactionCount() async {
    final db = await database;
    final c = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM transactions'));
    return c ?? 0;
  }

  /// Wipe all simulation data (used by "Reset Portfolio" & "Delete Account").
  Future<void> resetAll() async {
    final db = await database;
    await db.delete('holdings');
    await db.delete('transactions');
    await db.delete('wallet');
  }
}
