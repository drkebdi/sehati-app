import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/glucose_reading.dart';
import '../models/bp_reading.dart';
import '../models/reminder.dart';

class DBService {
  static Database? _db;

  static Future<void> init() async {
    final path = join(await getDatabasesPath(), 'sehati.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE glucose (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            val REAL NOT NULL,
            when_taken TEXT NOT NULL,
            date TEXT NOT NULL,
            time TEXT NOT NULL,
            note TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE bp (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sys REAL NOT NULL,
            dia REAL NOT NULL,
            pulse INTEGER,
            position TEXT,
            date TEXT NOT NULL,
            time TEXT NOT NULL,
            note TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            label TEXT NOT NULL,
            time TEXT NOT NULL,
            when_taken TEXT,
            enabled INTEGER NOT NULL DEFAULT 1,
            notif_id INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE profile (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');

        // Insert default reminders
        await db.insert('reminders', {
          'type': 'glucose', 'label': 'صائم — الصباح',
          'time': '07:00', 'when_taken': 'صائم',
          'enabled': 1, 'notif_id': 1
        });
        await db.insert('reminders', {
          'type': 'glucose', 'label': 'بعد الغداء',
          'time': '14:30', 'when_taken': 'بعد الأكل',
          'enabled': 0, 'notif_id': 2
        });
        await db.insert('reminders', {
          'type': 'bp', 'label': 'الصباح',
          'time': '08:00', 'when_taken': null,
          'enabled': 1, 'notif_id': 3
        });
        await db.insert('reminders', {
          'type': 'bp', 'label': 'المساء',
          'time': '18:00', 'when_taken': null,
          'enabled': 1, 'notif_id': 4
        });
      },
    );
  }

  static Database get db => _db!;

  // ── GLUCOSE ──
  static Future<int> addGlucose(GlucoseReading r) =>
      db.insert('glucose', r.toMap());

  static Future<List<GlucoseReading>> getGlucose() async {
    final maps = await db.query('glucose', orderBy: 'created_at DESC');
    return maps.map(GlucoseReading.fromMap).toList();
  }

  static Future<void> deleteGlucose(int id) =>
      db.delete('glucose', where: 'id = ?', whereArgs: [id]);

  // ── BP ──
  static Future<int> addBP(BPReading r) =>
      db.insert('bp', r.toMap());

  static Future<List<BPReading>> getBP() async {
    final maps = await db.query('bp', orderBy: 'created_at DESC');
    return maps.map(BPReading.fromMap).toList();
  }

  static Future<void> deleteBP(int id) =>
      db.delete('bp', where: 'id = ?', whereArgs: [id]);

  // ── REMINDERS ──
  static Future<List<Reminder>> getReminders() async {
    final maps = await db.query('reminders', orderBy: 'id ASC');
    return maps.map(Reminder.fromMap).toList();
  }

  static Future<void> updateReminder(Reminder r) =>
      db.update('reminders', r.toMap(), where: 'id = ?', whereArgs: [r.id]);

  static Future<int> addReminder(Reminder r) =>
      db.insert('reminders', r.toMap());

  static Future<void> deleteReminder(int id) =>
      db.delete('reminders', where: 'id = ?', whereArgs: [id]);

  // ── PROFILE ──
  static Future<void> setProfile(String key, String value) =>
      db.insert('profile', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);

  static Future<String?> getProfile(String key) async {
    final rows = await db.query('profile', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }
}
