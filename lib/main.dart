import 'package:flutter/material.dart';
import 'db.dart';
import 'state.dart';
import 'util.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget/build(BuildContext context) {
    return MaterialApp(
      title: 'Flosi',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flosi App')),
      body: const Center(
        child: Text('Welcome to Flosi! SQLite & State Connected ✅'),
      ),
    );
  }
}
