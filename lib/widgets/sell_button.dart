import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/binance_service.dart';
import '../utils/dialog.dart';

class SellButton extends StatefulWidget {
  const SellButton({Key? key}) : super(key: key);

  @override
  State<SellButton> createState() => _SellButtonState();
}

class _SellButtonState extends State<SellButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Get the Binance API instance using Provider
    final binanceService = Provider.of<BinanceService>(context, listen: false);
    // The Button is replaced with a loading indicator when the sell request is running
    return _isLoading
        ? const SizedBox(
            width: 100,
            height: 50,
            child: Center(child: CircularProgressIndicator()))
        : SizedBox(
            width: 100,
            height: 50,
            child: ElevatedButton(
              // When the button is pressed, the sellAll() method from the BinanceService is called
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                });
                try {
                  await binanceService.sellAll();
                  showConfirmationDialog(
                    context: context,
                    title: 'Info',
                    message: 'Successfully sold all crypto',
                  );
                } catch (error) {
                  showConfirmationDialog(
                      context: context, title: 'Error', message: '$error');
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              child: const Text('Sell All'),
            ),
          );
  }
}
