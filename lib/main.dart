import 'package:binance_panic_button/screens/main_screen.dart';
import 'package:binance_panic_button/services/binance_service.dart';
import 'package:binance_panic_button/utils/themes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  final binanceService = BinanceService();

  runApp(
    ChangeNotifierProvider(
      // Crete a Provider with a Binance API instance
      create: (context) => binanceService,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      title: 'Binance Panic Button App',
      home: const MainScreen(),
    );
  }
}
