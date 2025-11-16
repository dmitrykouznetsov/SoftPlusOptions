import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:softplus_options/storage/strategy.dart';
import 'package:softplus_options/ui/layout_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // shared_preferences used in combination with riverpod
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    // Wrap in riverpod stuff
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(sharedPreferences)],
      child: App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Option Strategy Payoff',
      theme: ThemeData(
        // Light theme only for now
        // TODO: dark theme
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: LayoutWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
