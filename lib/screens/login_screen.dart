import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../services/binance_service.dart';
import 'dart:developer' as developer;

class LoginScreen extends StatefulWidget {
  final Function onLogin;
  
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _secretKeyController = TextEditingController();
  final BinanceService _binanceService = BinanceService();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasError = false;
  bool _obscureSecret = true;
  bool _isTestnet = false;
  bool _hasInternetConnection = true;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
  }
  
  Future<void> _checkInternetConnection() async {
    final hasConnection = await InternetConnectionChecker().hasConnection;
    setState(() {
      _hasInternetConnection = hasConnection;
      if (!hasConnection) {
        _errorMessage = 'No internet connection. Please check your network settings.';
      }
    });
  }

  Future<void> _login() async {
    // Clear previous errors
    setState(() {
      _errorMessage = '';
    });
    
    // Check internet connection
    if (!_hasInternetConnection) {
      await _checkInternetConnection();
      if (!_hasInternetConnection) {
        setState(() {
          _errorMessage = 'No internet connection. Please check your network settings.';
          _hasError = true;
        });
        return;
      }
    }
    
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      developer.log('Attempting login with API key', name: 'LoginScreen');
      
      // Save credentials
      await _binanceService.saveCredentials(
        _apiKeyController.text.trim(),
        _secretKeyController.text.trim(),
        isTestnet: _isTestnet,
      );

      // Test connection by fetching account info
      await _binanceService.getAccountInfo();
      
      developer.log('Login successful', name: 'LoginScreen');

      // If successful, call the onLogin callback
      widget.onLogin();
    } catch (e) {
      developer.log('Login failed: ${e.toString()}', name: 'LoginScreen', error: e);
      
      // Format error message for better user experience
      String errorMsg = 'Login failed: ';
      
      if (e.toString().contains('API error')) {
        errorMsg += e.toString();
      } else if (e.toString().contains('Network error')) {
        errorMsg = 'Cannot connect to Binance. Please check your internet connection.';
      } else if (e.toString().contains('Connection timeout')) {
        errorMsg = 'Connection timeout. Binance servers might be busy, please try again later.';
      } else if (e.toString().contains('Invalid API-key')) {
        errorMsg = 'Invalid API key. Please check your credentials.';
      } else {
        errorMsg += e.toString();
      }
      
      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Binance Panic Button'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _checkInternetConnection,
            tooltip: 'Check connection',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Enter your Binance API credentials',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.security, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: const Text(
                                  'Make sure your API key has trading permissions enabled and does NOT have withdrawal permissions.',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                _hasInternetConnection ? Icons.wifi : Icons.wifi_off,
                                color: _hasInternetConnection ? Colors.green : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _hasInternetConnection 
                                    ? 'Internet connection available' 
                                    : 'No internet connection',
                                style: TextStyle(
                                  color: _hasInternetConnection ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // API Key field
                  TextFormField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: 'Enter your Binance API key',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.vpn_key),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your API key';
                      }
                      if (value.length < 10) {
                        return 'API key seems too short';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Secret Key field
                  TextFormField(
                    controller: _secretKeyController,
                    decoration: InputDecoration(
                      labelText: 'Secret Key',
                      hintText: 'Enter your Binance Secret key',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureSecret ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureSecret = !_obscureSecret;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureSecret,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your Secret key';
                      }
                      if (value.length < 10) {
                        return 'Secret key seems too short';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Testnet option
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _isTestnet,
                            activeColor: Theme.of(context).primaryColor,
                            onChanged: (value) {
                              setState(() {
                                _isTestnet = value ?? false;
                              });
                            },
                          ),
                          const Text(
                            'Use Binance Testnet',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Check this if you are using Binance Testnet API credentials',
                            child: Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                          ),
                          if (_isTestnet) ...[  
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '(Recommended for testing)',
                                style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Login button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !_hasInternetConnection) ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 3,
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('CONNECTING...', style: TextStyle(fontSize: 16)),
                              ],
                            )
                          : const Text('LOGIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  // Error message
                  if (_errorMessage.isNotEmpty) ...[  
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Login Error',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Security note at bottom
                  const SizedBox(height: 32),
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shield, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                'Security Information',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• Your API credentials are stored securely on your device only.',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '• Never share your API Secret Key with anyone.',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '• For maximum security, create API keys with trading permissions only.',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}