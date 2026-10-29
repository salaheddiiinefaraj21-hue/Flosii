import 'package:flutter/foundation.dart';
import 'db.dart';

double sum(Iterable<Txn> list, String type) {
  double s = 0;
  for (final t in list) {
    if (t.type == type) s += t.amount;
  }
  return s;
}

class AppState extends ChangeNotifier {
  final AppDb _db = AppDb.instance;
  List<Txn> txns = [];
  List<Cat> cats = [];
  List<Service> services = [];
  List<Loan> loans = [];
  bool ready = false;

  Future<void> load() async {
    txns = await _db.allTxns();
    cats = await _db.allCats();
    services = await _db.allServices();
    loans = await _db.allLoans();
    ready = true;
    notifyListeners();
  }

  Future<void> saveTxn(Txn t) async {
    await _db.saveTxn(t);
    await load();
  }

  Future<void> deleteTxn(int id) async {
    await _db.deleteTxn(id);
    await load();
  }

  Future<bool> addCat(String name) async {
    final n = name.trim();
    if (n.isEmpty || cats.any((c) => c.name == n)) return false;
    await _db.addCat(n);
    await load();
    return true;
  }

  Future<void> deleteCat(int id) async {
    await _db.deleteCat(id);
    await load();
  }

  Future<void> saveService(Service s) async {
    await _db.saveService(s);
    await load();
  }

  Future<void> deleteService(int id) async {
    await _db.deleteService(id);
    await load();
  }

  Future<void> saveLoan(Loan l) async {
    await _db.saveLoan(l);
    await load();
  }

  Future<void> deleteLoan(int id) async {
    await _db.deleteLoan(id);
    await load();
  }

  Future<String> export() => _db.exportJson();

  Future<int> import(String raw) async {
    final n = await _db.importJson(raw);
    await load();
    return n;
  }
}

final AppState appState = AppState();
