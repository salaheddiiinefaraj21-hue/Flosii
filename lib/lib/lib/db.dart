import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

const List<String> defaultCats = [
  'النقل', 'الكرا', 'الفواتير', 'الصحة', 'الملابس', 'الترفيه', 'أخرى'
];

final RegExp _dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');

class Txn {
  final int? id;
  final String type; // 'in' or 'out'
  final String title; // place/service for income, category for expense
  final double amount;
  final String date; // YYYY-MM-DD
  final String note;
  const Txn({
    this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.date,
    this.note = '',
  });
  bool get isIn => type == 'in';
  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'type': type,
        'title': title,
        'amount': amount,
        'date': date,
        'note': note,
      };
  factory Txn.fromMap(Map<String, Object?> m) => Txn(
        id: m['id'] as int?,
        type: m['type'] as String,
        title: m['title'] as String,
        amount: (m['amount'] as num).toDouble(),
        date: m['date'] as String,
        note: (m['note'] as String?) ?? '',
      );
}

class Cat {
  final int id;
  final String name;
  const Cat(this.id, this.name);
}

class Service {
  final int? id;
  final String name;
  final double price;
  const Service({this.id, required this.name, required this.price});
}

class Loan {
  final int? id;
  final String who;
  final String kind; // 'l' = I lent, 'b' = I borrowed
  final double amount;
  final String date;
  final String? paidDate;
  final String note;
  const Loan({
    this.id,
    required this.who,
    required this.kind,
    required this.amount,
    required this.date,
    this.paidDate,
    this.note = '',
  });
  bool get paid => paidDate != null;
  bool get iLent => kind == 'l';
  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'who': who,
        'kind': kind,
        'amount': amount,
        'date': date,
        'paid_date': paidDate,
        'note': note,
      };
  factory Loan.fromMap(Map<String, Object?> m) => Loan(
        id: m['id'] as int?,
        who: m['who'] as String,
        kind: m['kind'] as String,
        amount: (m['amount'] as num).toDouble(),
        date: m['date'] as String,
        paidDate: m['paid_date'] as String?,
        note: (m['note'] as String?) ?? '',
      );
}

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();
  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'flosi.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (d, v) async {
        await d.execute(
            "CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT NOT NULL, title TEXT NOT NULL, amount REAL NOT NULL, date TEXT NOT NULL, note TEXT NOT NULL DEFAULT '')");
        await d.execute(
            "CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)");
        await d.execute(
            "CREATE TABLE services(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, price REAL NOT NULL)");
        await d.execute(
            "CREATE TABLE loans(id INTEGER PRIMARY KEY AUTOINCREMENT, who TEXT NOT NULL, kind TEXT NOT NULL, amount REAL NOT NULL, date TEXT NOT NULL, paid_date TEXT, note TEXT NOT NULL DEFAULT '')");
        final b = d.batch();
        for (final c in defaultCats) {
          b.insert('categories', {'name': c});
        }
        await b.commit(noResult: true);
      },
    );
  }

  // ---- transactions
  Future<List<Txn>> allTxns() async {
    final d = await db;
    final rows = await d.query('transactions', orderBy: 'date DESC, id DESC');
    return rows.map(Txn.fromMap).toList();
  }

  Future<void> saveTxn(Txn t) async {
    final d = await db;
    if (t.id == null) {
      await d.insert('transactions', t.toMap());
    } else {
      await d.update('transactions', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
    }
  }

  Future<void> deleteTxn(int id) async {
    final d = await db;
    await d.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ---- categories
  Future<List<Cat>> allCats() async {
    final d = await db;
    final rows = await d.query('categories', orderBy: 'id');
    return rows.map((r) => Cat(r['id'] as int, r['name'] as String)).toList();
  }

  Future<void> addCat(String name) async {
    final d = await db;
    await d.insert('categories', {'name': name},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> deleteCat(int id) async {
    final d = await db;
    await d.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ---- services
  Future<List<Service>> allServices() async {
    final d = await db;
    final rows = await d.query('services', orderBy: 'name');
    return rows
        .map((r) => Service(
            id: r['id'] as int?,
            name: r['name'] as String,
            price: (r['price'] as num).toDouble()))
        .toList();
  }

  Future<void> saveService(Service s) async {
    final d = await db;
    final m = {'name': s.name, 'price': s.price};
    if (s.id == null) {
      await d.insert('services', m);
    } else {
      await d.update('services', m, where: 'id = ?', whereArgs: [s.id]);
    }
  }

  Future<void> deleteService(int id) async {
    final d = await db;
    await d.delete('services', where: 'id = ?', whereArgs: [id]);
  }

  // ---- loans
  Future<List<Loan>> allLoans() async {
    final d = await db;
    final rows = await d.query('loans', orderBy: 'date DESC, id DESC');
    return rows.map(Loan.fromMap).toList();
  }

  Future<void> saveLoan(Loan l) async {
    final d = await db;
    if (l.id == null) {
      await d.insert('loans', l.toMap());
    } else {
      await d.update('loans', l.toMap(), where: 'id = ?', whereArgs: [l.id]);
    }
  }

  Future<void> deleteLoan(int id) async {
    final d = await db;
    await d.delete('loans', where: 'id = ?', whereArgs: [id]);
  }

  // ---- backup / restore
  Future<String> exportJson() async {
    final t = await allTxns();
    final c = await allCats();
    final s = await allServices();
    final l = await allLoans();
    return jsonEncode({
      'app': 'flosi',
      'version': 1,
      'exported': DateTime.now().toIso8601String(),
      'transactions': t.map((x) => x.toMap()).toList(),
      'categories': c.map((x) => x.name).toList(),
      'services': s.map((x) => {'name': x.name, 'price': x.price}).toList(),
      'loans': l.map((x) => x.toMap()).toList(),
    });
  }

  /// Replaces all data with the content of [raw]. Accepts the Flosi app
  /// backup format and the older Flosi web version backup format.
  /// Returns the number of transactions imported.
  Future<int> importJson(String raw) async {
    Object? data;
    try {
      data = jsonDecode(raw.trim());
    } catch (_) {
      throw const FormatException('النص ما صحيحش، لصق النسخة كاملة.');
    }
    if (data is! Map) {
      throw const FormatException('هادي ماشي نسخة ديال Flosi.');
    }
    final map = Map<String, dynamic>.from(data);

    final txns = <Txn>[];
    final loans = <Loan>[];
    final services = <Service>[];
    List<String>? cats;
    var webFormat = false;

    try {
      if (map['transactions'] is List) {
        for (final x in map['transactions'] as List) {
          final m = Map<String, dynamic>.from(x as Map);
          txns.add(Txn(
            type: m['type'] == 'out' ? 'out' : 'in',
            title: m['title'] as String,
            amount: (m['amount'] as num).toDouble(),
            date: m['date'] as String,
            note: (m['note'] as String?) ?? '',
          ));
        }
        for (final x in (map['loans'] as List?) ?? const []) {
          final m = Map<String, dynamic>.from(x as Map);
          loans.add(Loan(
            who: m['who'] as String,
            kind: m['kind'] == 'b' ? 'b' : 'l',
            amount: (m['amount'] as num).toDouble(),
            date: m['date'] as String,
            paidDate: m['paid_date'] as String?,
            note: (m['note'] as String?) ?? '',
          ));
        }
        for (final x in (map['services'] as List?) ?? const []) {
          final m = Map<String, dynamic>.from(x as Map);
          services.add(Service(
              name: m['name'] as String, price: (m['price'] as num).toDouble()));
        }
        cats = ((map['categories'] as List?) ?? const [])
            .map((e) => e as String)
            .toList();
      } else if (map['e'] is List) {
        webFormat = true;
        for (final x in map['e'] as List) {
          final m = Map<String, dynamic>.from(x as Map);
          txns.add(Txn(
            type: m['t'] == 'out' ? 'out' : 'in',
            title: m['n'] as String,
            amount: (m['a'] as num).toDouble(),
            date: m['d'] as String,
            note: (m['o'] as String?) ?? '',
          ));
        }
        for (final x in (map['l'] as List?) ?? const []) {
          final m = Map<String, dynamic>.from(x as Map);
          final paid = m['p'] as String?;
          loans.add(Loan(
            who: m['w'] as String,
            kind: m['k'] == 'b' ? 'b' : 'l',
            amount: (m['a'] as num).toDouble(),
            date: m['d'] as String,
            paidDate: (paid == null || paid.isEmpty) ? null : paid,
            note: (m['o'] as String?) ?? '',
          ));
        }
      } else {
        throw const FormatException('هادي ماشي نسخة ديال Flosi.');
      }
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('النسخة ناقصة ولا فيها معلومات غلط.');
    }

    for (final t in txns) {
      if (!_dateRe.hasMatch(t.date) || t.amount <= 0 || t.title.trim().isEmpty) {
        throw const FormatException('كاين تسجيل فيه معلومات غلط.');
      }
    }
    for (final l in loans) {
      if (!_dateRe.hasMatch(l.date) || l.amount <= 0 || l.who.trim().isEmpty) {
        throw const FormatException('كاين سلف فيه معلومات غلط.');
      }
    }

    final d = await db;
    await d.transaction((tx) async {
      await tx.delete('transactions');
      await tx.delete('loans');
      final b = tx.batch();
      for (final t in txns) {
        b.insert('transactions', t.toMap());
      }
      for (final l in loans) {
        b.insert('loans', l.toMap());
      }
      if (!webFormat) {
        await tx.delete('services');
        await tx.delete('categories');
        for (final s in services) {
          b.insert('services', {'name': s.name, 'price': s.price});
        }
        for (final c in cats ?? const <String>[]) {
          b.insert('categories', {'name': c},
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      } else {
        for (final t in txns.where((t) => t.type == 'out')) {
          b.insert('categories', {'name': t.title},
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
      await b.commit(noResult: true);
    });
    return txns.length;
  }
}
