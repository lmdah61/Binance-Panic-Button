import 'dart:convert';

import 'package:binance_api_dart/binance_api_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/crypto.dart';
import '../utils/consts.dart';

class BinanceService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();

  late BinanceApi _binanceApi;
  bool _isInitialized = false;
  bool _isConfigured = false;

  BinanceService() {
    try {
      _binanceApi = BinanceApi(baseUrl: BASE_URL, apiKey: '', privateKey: '');
      _isInitialized = true;
    } catch (error) {
      _isInitialized = false;
      throw Exception('Failed initializing the Binance API. Error: $error');
    }
  }

  // Set the keys on binanceAPI from the safe storage
  updateAPIKeys() async {
    try {
      _binanceApi.apiKey = await _storage.read(key: API_KEY_STORAGE_ID) ?? '';
      _binanceApi.privateKey =
          await _storage.read(key: API_SECRET_STORAGE_ID) ?? '';
      if (_binanceApi.apiKey != '' && _binanceApi.privateKey != '') {
        _isConfigured = true;
      } else {
        _isConfigured = false;
      }
    } catch (error) {
      throw Exception(
          'Failed to configure your Binance API Keys. Error: $error');
    }
  }

  // Get a list of all your coins
  Future<List<Crypto>> getCoinsList() async {
    // check if the API is initialized and configured with the keys set by the user
    if (!_isInitialized || !_isConfigured) {
      throw Exception("Binance API is not properly initialized or configured");
    }

    // set the request parameter
    Map<String, String> getParameters = {};
    getParameters['recvWindow'] = '10000';

    try {
      // send a GET request to the "/api/v3/account" endpoint
      final accountInfoResponse =
          await _binanceApi.getHttp('/api/v3/account', getParameters);
      // check if the request was successful
      if (accountInfoResponse.statusCode == 200) {
        // parse the json response
        final accountInfo = json.decode(accountInfoResponse.body);
        final List<dynamic> assetsJson = accountInfo?["balances"];
        // map json to a list of Coins
        final assets = assetsJson.map((asset) {
          try {
            return Crypto.fromJson(asset);
          } catch (error) {
            throw Exception(
                'Failed to parse json response of assets. Error: $error');
          }
        }).toList();
        return assets;
      } else {
        // parse the json error response
        final Map<String, dynamic> errorResponse =
            jsonDecode(accountInfoResponse.body);
        final int error = errorResponse['code'];
        final String errorMessage = errorResponse['msg'];
        throw Exception(
            'Failed to access your portfolio. Error code: $error, Error message: $errorMessage');
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<bool> sellAsset(Crypto asset) async {
    if (!_isInitialized || !_isConfigured) {
      throw Exception('Binance API is not properly initialized or configured');
    }

    if (asset.free == "0.00000000") {
      throw Exception(
          'Error selling ${asset.asset} quantity must be greater than zero');
    }

    // set the request parameters
    Map<String, String> postParameters = {};
    postParameters['recvWindow'] = '10000';
    postParameters['symbol'] = '${asset.asset}$TARGET_STABLE_COIN';
    postParameters['quantity'] = asset.free;
    postParameters['side'] = 'SELL';
    postParameters['type'] = 'MARKET';

    try {
      final sellResponse =
          await _binanceApi.postHttp('/api/v3/order', postParameters);
      if (sellResponse.statusCode != 200) {
        // parse the json error response
        var error = jsonDecode(sellResponse.body)['code'];
        var errorMessage = jsonDecode(sellResponse.body)['msg'];
        throw Exception(
            'Failed to sell ${asset.free} of ${asset.asset}. Error code: $error, Error message: $errorMessage');
      }
      return true;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> sellAll() async {
    // Refresh new api values
    await updateAPIKeys();

    if (!_isInitialized || !_isConfigured) {
      throw Exception('Binance API is not properly initialized or configured');
    }

    try {
      // Get a list of all your coins
      final assets = await getCoinsList();

      // Sell them
      for (var asset in assets) {
        if (asset.free != "0.00000000" && !STABLE_COINS.contains(asset.asset)) {
          await sellAsset(asset);
        }
      }
    } catch (error) {
      rethrow;
    }
  }
}
