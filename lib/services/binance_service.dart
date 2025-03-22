import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;

class BinanceService {
  // API URLs
  static const String _prodBaseUrl = 'https://api.binance.com';
  static const String _testBaseUrl = 'https://testnet.binance.vision';
  
  // Secure storage keys
  static const String _apiKeySecure = 'binance_api_key';
  static const String _secretKeySecure = 'binance_secret_key';
  
  // Preference keys (non-sensitive data)
  static const String _isTestnetPref = 'binance_is_testnet';
  
  // Secure storage instance
  final _secureStorage = const FlutterSecureStorage(aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ));
  
  // Get the base URL based on environment
  Future<String> get _baseUrl async {
    final isTestnet = await _isTestnetMode();
    return isTestnet ? _testBaseUrl : _prodBaseUrl;
  }
  
  // Save API credentials securely
  Future<void> saveCredentials(String apiKey, String secretKey, {bool isTestnet = false}) async {
    try {
      // Validate inputs
      if (apiKey.trim().isEmpty || secretKey.trim().isEmpty) {
        throw Exception('API key and Secret key cannot be empty');
      }
      
      // Store sensitive data in secure storage
      await _secureStorage.write(key: _apiKeySecure, value: apiKey.trim());
      await _secureStorage.write(key: _secretKeySecure, value: secretKey.trim());
      
      // Store non-sensitive data in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isTestnetPref, isTestnet);
      
      developer.log('Credentials saved successfully', name: 'BinanceService');
    } catch (e) {
      developer.log('Error saving credentials: ${e.toString()}', name: 'BinanceService', error: e);
      throw Exception('Failed to save credentials: ${e.toString()}');
    }
  }
  
  // Get saved API credentials
  Future<Map<String, dynamic>> getCredentials() async {
    try {
      // Get sensitive data from secure storage
      final apiKey = await _secureStorage.read(key: _apiKeySecure);
      final secretKey = await _secureStorage.read(key: _secretKeySecure);
      
      // Get non-sensitive data from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final isTestnet = prefs.getBool(_isTestnetPref) ?? false;
      
      return {
        'apiKey': apiKey,
        'secretKey': secretKey,
        'isTestnet': isTestnet,
      };
    } catch (e) {
      developer.log('Error retrieving credentials: ${e.toString()}', name: 'BinanceService', error: e);
      return {
        'apiKey': null,
        'secretKey': null,
        'isTestnet': false,
      };
    }
  }
  
  // Check if credentials are saved
  Future<bool> hasCredentials() async {
    try {
      final credentials = await getCredentials();
      return credentials['apiKey'] != null && credentials['secretKey'] != null;
    } catch (e) {
      developer.log('Error checking credentials: ${e.toString()}', name: 'BinanceService', error: e);
      return false;
    }
  }
  
  // Check if in testnet mode
  Future<bool> _isTestnetMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isTestnetPref) ?? false;
    } catch (e) {
      developer.log('Error checking testnet mode: ${e.toString()}', name: 'BinanceService', error: e);
      return false;
    }
  }
  
  // Clear saved credentials
  Future<void> clearCredentials() async {
    try {
      // Clear secure storage
      await _secureStorage.delete(key: _apiKeySecure);
      await _secureStorage.delete(key: _secretKeySecure);
      
      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isTestnetPref);
      
      developer.log('Credentials cleared successfully', name: 'BinanceService');
    } catch (e) {
      developer.log('Error clearing credentials: ${e.toString()}', name: 'BinanceService', error: e);
      throw Exception('Failed to clear credentials: ${e.toString()}');
    }
  }
  
  // Generate signature for API request
  String _generateSignature(String queryString, String secretKey) {
    final bytes = utf8.encode(queryString);
    final hmacSha256 = Hmac(sha256, utf8.encode(secretKey));
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }
  
  // Get account information
  Future<Map<String, dynamic>> getAccountInfo() async {
    try {
      final credentials = await getCredentials();
      final apiKey = credentials['apiKey'];
      final secretKey = credentials['secretKey'];
      
      if (apiKey == null || secretKey == null) {
        throw Exception('API credentials not found');
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final queryString = 'timestamp=$timestamp';
      final signature = _generateSignature(queryString, secretKey);
      
      final baseUrl = await _baseUrl;
      
      developer.log('Fetching account info from $baseUrl', name: 'BinanceService');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/v3/account?$queryString&signature=$signature'),
        headers: {'X-MBX-APIKEY': apiKey},
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        developer.log('Account info fetched successfully', name: 'BinanceService');
        return json.decode(response.body);
      } else {
        // Try to parse error message from API
        String errorMessage = 'Failed to get account info: ${response.body}';
        try {
          final errorJson = json.decode(response.body);
          if (errorJson.containsKey('msg')) {
            errorMessage = 'API error: ${errorJson['msg']} (code: ${errorJson['code']})';
          }
        } catch (_) {}
        
        developer.log(errorMessage, name: 'BinanceService', error: response.body);
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log('Error getting account info: ${e.toString()}', name: 'BinanceService', error: e);
      if (e is http.ClientException) {
        throw Exception('Network error: Unable to connect to Binance. Please check your internet connection.');
      } else if (e is TimeoutException) {
        throw Exception('Connection timeout: Binance API is not responding. Please try again later.');
      }
      rethrow;
    }
  }
  
  // Get all balances
  Future<List<Map<String, dynamic>>> getAllBalances() async {
    final accountInfo = await getAccountInfo();
    final balances = List<Map<String, dynamic>>.from(accountInfo['balances']);
    
    // Filter out zero balances
    return balances.where((balance) {
      final free = double.parse(balance['free']);
      final locked = double.parse(balance['locked']);
      return free > 0 || locked > 0;
    }).toList();
  }
  
  // Get available stablecoins
  Future<List<String>> getAvailableStablecoins() async {
    // Common stablecoins on Binance
    const stablecoins = ['USDT', 'BUSD', 'USDC', 'DAI', 'TUSD'];
    
    try {
      final baseUrl = await _baseUrl;
      final response = await http.get(Uri.parse('$baseUrl/api/v3/exchangeInfo'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final symbols = List<Map<String, dynamic>>.from(data['symbols']);
        
        // Filter for active stablecoin trading pairs
        final availableStablecoins = stablecoins.where((stablecoin) {
          return symbols.any((symbol) => 
            symbol['quoteAsset'] == stablecoin && 
            symbol['status'] == 'TRADING');
        }).toList();
        
        return availableStablecoins;
      }
    } catch (e) {
      // If API call fails, return default stablecoins
    }
    
    return stablecoins;
  }
  
  // Sell asset to stablecoin
  Future<Map<String, dynamic>> sellAssetToStablecoin(
    String asset, 
    String stablecoin, 
    String quantity
  ) async {
    final credentials = await getCredentials();
    final apiKey = credentials['apiKey'];
    final secretKey = credentials['secretKey'];
    
    if (apiKey == null || secretKey == null) {
      throw Exception('API credentials not found');
    }
    
    // Validate inputs
    if (asset.isEmpty || stablecoin.isEmpty) {
      throw Exception('Invalid asset or stablecoin');
    }
    
    // Parse and validate quantity
    final double parsedQuantity;
    try {
      parsedQuantity = double.parse(quantity);
      if (parsedQuantity <= 0) {
        throw Exception('Quantity must be greater than zero');
      }
    } catch (e) {
      throw Exception('Invalid quantity format: $quantity');
    }
    
    final symbol = '$asset$stablecoin';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final queryString = 'symbol=$symbol&side=SELL&type=MARKET&quantity=$quantity&timestamp=$timestamp';
    final signature = _generateSignature(queryString, secretKey);
    
    final baseUrl = await _baseUrl;
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v3/order?$queryString&signature=$signature'),
        headers: {
          'X-MBX-APIKEY': apiKey,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
      ).timeout(const Duration(seconds: 15)); // Add timeout
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = response.body;
        try {
          final errorJson = json.decode(errorBody);
          if (errorJson.containsKey('msg')) {
            throw Exception('API error: ${errorJson['msg']}');
          }
        } catch (_) {}
        
        throw Exception('Failed to sell asset: $errorBody');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }
  
  // Sell all assets to a specific stablecoin
  Future<List<Map<String, dynamic>>> sellAllAssetsToStablecoin(String stablecoin) async {
    final balances = await getAllBalances();
    final results = <Map<String, dynamic>>[];
    
    // Skip the target stablecoin
    final assetsToSell = balances.where((balance) => 
      balance['asset'] != stablecoin && 
      balance['asset'] != 'BNB' // Keep some BNB for fees
    ).toList();
    
    for (final asset in assetsToSell) {
      final symbol = asset['asset'];
      final quantity = asset['free'];
      
      try {
        // Skip assets with zero balance
        if (double.parse(quantity) <= 0) {
          results.add({
            'asset': symbol,
            'status': 'skipped',
            'error': 'Zero balance'
          });
          continue;
        }
        
        // Check if trading pair exists
        final pairExists = await _checkTradingPairExists('$symbol$stablecoin');
        if (!pairExists) {
          // Try to sell to BTC first, then BTC to stablecoin
          if (symbol != 'BTC') {
            final btcPairExists = await _checkTradingPairExists('${symbol}BTC');
            if (btcPairExists) {
              try {
                final sellToBtc = await sellAssetToStablecoin(symbol, 'BTC', quantity);
                results.add({
                  'asset': symbol,
                  'status': 'sold to BTC',
                  'result': sellToBtc
                });
                
                // Then sell BTC to stablecoin
                final btcBalance = await _getAssetBalance('BTC');
                if (btcBalance > 0) {
                  final sellBtcToStable = await sellAssetToStablecoin('BTC', stablecoin, btcBalance.toString());
                  results.add({
                    'asset': 'BTC',
                    'status': 'sold to $stablecoin',
                    'result': sellBtcToStable
                  });
                }
              } catch (e) {
                results.add({
                  'asset': symbol,
                  'status': 'failed',
                  'error': 'Failed to sell to BTC: ${e.toString()}'
                });
              }
            } else {
              results.add({
                'asset': symbol,
                'status': 'skipped',
                'error': 'No trading pair available for $symbol'
              });
            }
          } else {
            results.add({
              'asset': symbol,
              'status': 'skipped',
              'error': 'No trading pair with $stablecoin available'
            });
          }
        } else {
          // Direct sell to stablecoin
          try {
            final sellResult = await sellAssetToStablecoin(symbol, stablecoin, quantity);
            results.add({
              'asset': symbol,
              'status': 'sold to $stablecoin',
              'result': sellResult
            });
          } catch (e) {
            results.add({
              'asset': symbol,
              'status': 'failed',
              'error': 'Failed to sell to $stablecoin: ${e.toString()}'
            });
          }
        }
      } catch (e) {
        results.add({
          'asset': symbol,
          'status': 'failed',
          'error': e.toString()
        });
      }
    }
    
    return results;
  }
  
  // Check if trading pair exists
  Future<bool> _checkTradingPairExists(String symbol) async {
    try {
      final baseUrl = await _baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/api/v3/exchangeInfo?symbol=$symbol'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10)); // Add timeout
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if the response contains symbols array
        if (data.containsKey('symbols')) {
          final symbols = List<Map<String, dynamic>>.from(data['symbols']);
          return symbols.isNotEmpty && symbols[0]['status'] == 'TRADING';
        } else if (data.containsKey('symbol')) {
          // Some API versions return a single symbol object
          return data['status'] == 'TRADING';
        }
      } else if (response.statusCode == 400) {
        // 400 typically means invalid symbol
        return false;
      }
      
      return false;
    } catch (e) {
      print('Error checking trading pair $symbol: ${e.toString()}');
      return false;
    }
  }
  
  // Get specific asset balance
  Future<double> _getAssetBalance(String asset) async {
    final balances = await getAllBalances();
    final assetBalance = balances.firstWhere(
      (balance) => balance['asset'] == asset,
      orElse: () => {'free': '0.0'}
    );
    return double.parse(assetBalance['free'] ?? '0.0');
  }
}