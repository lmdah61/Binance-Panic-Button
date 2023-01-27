import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../widgets/sell_button.dart';
import 'settings_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('Binance Panic Button App'),
        actions: <Widget>[
          // Button to access the settings screen
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          )
        ],
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Text(
              "Click the button below to sell all your coins from Binance",
            ),
            Gap(20),
            SellButton(),
          ],
        ),
      ),
    );
  }
}
