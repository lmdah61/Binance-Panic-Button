import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gap/gap.dart';

import '../utils/consts.dart';
import '../utils/dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = const FlutterSecureStorage();
  late String _apiKey = '';
  late String _apiSecret = '';

  // Load the keys inside the Text Fields when user enters the screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    try {
      // Load the keys from the secure storage
      _apiKey = await _storage.read(key: API_KEY_STORAGE_ID) ?? '';
      _apiSecret = await _storage.read(key: API_SECRET_STORAGE_ID) ?? '';
      setState(() {});
    } catch (error) {
      showConfirmationDialog(
          context: context, title: 'Error', message: '$error');
    }
  }

  void _saveCredentials() {
    try {
      // Save the keys in the secure storage
      _storage.write(key: API_KEY_STORAGE_ID, value: _apiKey.trim());
      _storage.write(key: API_SECRET_STORAGE_ID, value: _apiSecret.trim());
      setState(() {});
      showConfirmationDialog(
          context: context, title: 'Info', message: 'Changes saved successfully');
    } catch (error) {
      showConfirmationDialog(
          context: context, title: 'Error', message: '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            // Create a text field for the API key
            TextField(
              //obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Api Key',
              ),
              controller: TextEditingController(text: _apiKey),
              // Update the _apiKey variable when the text in the text field changes
              onChanged: (value) {
                _apiKey = value;
              },
            ),
            // Create a text field for the API secret
            TextField(
              //obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Api Secret',
              ),
              controller: TextEditingController(text: _apiSecret),
              // Update the _apiSecret variable when the text in the text field changes
              onChanged: (value) {
                _apiSecret = value;
              },
            ),
            // Add a space between the text fields and the save button
            const Gap(20),
            // Create a save button
            SizedBox(
              width: 100,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  _saveCredentials();
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
