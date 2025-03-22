import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../services/binance_service.dart';
import 'dart:developer' as developer;

class PanicButtonScreen extends StatefulWidget {
  final Function onLogout;
  
  const PanicButtonScreen({super.key, required this.onLogout});

  @override
  State<PanicButtonScreen> createState() => _PanicButtonScreenState();
}

class _PanicButtonScreenState extends State<PanicButtonScreen> {
  final BinanceService _binanceService = BinanceService();
  String? _selectedStablecoin;
  List<String> _stablecoins = ['USDT', 'BUSD', 'USDC'];
  bool _isLoading = true;
  bool _isSelling = false;
  String _statusMessage = '';
  bool _hasError = false;
  List<Map<String, dynamic>> _balances = [];
  List<Map<String, dynamic>> _sellResults = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Check internet connection first
    final hasConnection = await InternetConnectionChecker().hasConnection;
    if (!hasConnection) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'No internet connection. Please check your network settings.';
        _hasError = true;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading account data...';
      _hasError = false;
    });

    try {
      developer.log('Loading account data and stablecoins', name: 'PanicButtonScreen');
      
      // Load available stablecoins
      final stablecoins = await _binanceService.getAvailableStablecoins();
      if (stablecoins.isNotEmpty) {
        _stablecoins = stablecoins;
        _selectedStablecoin = stablecoins.first;
        developer.log('Loaded ${stablecoins.length} stablecoins', name: 'PanicButtonScreen');
      } else {
        developer.log('No stablecoins found, using defaults', name: 'PanicButtonScreen');
      }

      // Load account balances
      _balances = await _binanceService.getAllBalances();
      developer.log('Loaded ${_balances.length} assets with non-zero balance', name: 'PanicButtonScreen');

      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });
    } catch (e) {
      developer.log('Error loading data: ${e.toString()}', name: 'PanicButtonScreen', error: e);
      
      // Format error message for better user experience
      String errorMsg;
      
      if (e.toString().contains('API error')) {
        errorMsg = e.toString();
      } else if (e.toString().contains('Network error')) {
        errorMsg = 'Cannot connect to Binance. Please check your internet connection.';
      } else if (e.toString().contains('Connection timeout')) {
        errorMsg = 'Connection timeout. Binance servers might be busy, please try again later.';
      } else {
        errorMsg = 'Error loading data: ${e.toString()}';
      }
      
      setState(() {
        _isLoading = false;
        _statusMessage = errorMsg;
        _hasError = true;
      });
    }
  }

  // Show details dialog when user taps on a failed or skipped transaction card
  void _showErrorDetailsDialog(BuildContext context, String asset, String errorMessage) {
    final bool isSkipped = errorMessage.contains('skipped') || 
                          errorMessage.contains('Zero balance') || 
                          errorMessage.contains('No trading pair');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isSkipped ? "Skipped" : "Error"} Details: $asset'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSkipped 
                    ? 'This asset was skipped for the following reason:'
                    : 'The transaction failed with the following error:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSkipped ? Colors.amber.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isSkipped ? Colors.amber.shade200 : Colors.red.shade200),
                ),
                child: Text(errorMessage),
              ),
              const SizedBox(height: 16),
              const Text(
                'Possible solutions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (errorMessage.contains('Zero balance'))
                _buildSolutionItem('This asset has zero free balance available for trading.')
              else if (errorMessage.contains('No trading pair'))
                _buildSolutionItem('No direct trading pair exists between this asset and the selected stablecoin.')
              else ...[  
                _buildSolutionItem('Check if the trading pair exists on Binance.'),
                _buildSolutionItem('Ensure you have sufficient balance for the transaction.'),
                _buildSolutionItem('Verify that the asset is not locked or in an order.'),
                _buildSolutionItem('Try again later if it is a temporary API issue.'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper method to build solution items with bullet points
  Widget _buildSolutionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
  
  // Helper method to get status color
  MaterialColor _getStatusColor(String status) {
    if (status.contains('sold')) {
      return Colors.green;
    } else if (status.contains('skipped')) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }
  
  // Helper method to get status icon
  IconData _getStatusIcon(String status) {
    if (status.contains('sold')) {
      return Icons.check;
    } else if (status.contains('skipped')) {
      return Icons.warning_amber_outlined;
    } else {
      return Icons.error_outline;
    }
  }

  Future<void> _sellAllAssets() async {
    // Check if stablecoin is selected
    if (_selectedStablecoin == null) {
      setState(() {
        _statusMessage = 'Please select a stablecoin';
        _hasError = true;
      });
      return;
    }
    
    // Check internet connection first
    final hasConnection = await InternetConnectionChecker().hasConnection;
    if (!hasConnection) {
      setState(() {
        _statusMessage = 'No internet connection. Please check your network settings.';
        _hasError = true;
      });
      return;
    }

    // Show confirmation dialog with more detailed warning
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Confirm Panic Sell'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to sell ALL your assets to $_selectedStablecoin?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('This action:'),
            const SizedBox(height: 8),
            const Text('• Cannot be undone'),
            const Text('• Will sell at market price'),
            const Text('• May result in slippage'),
            const Text('• Will incur trading fees'),
            const SizedBox(height: 16),
            const Text('Proceed only in emergency situations.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Sell Everything'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    setState(() {
      _isSelling = true;
      _statusMessage = 'Selling all assets to $_selectedStablecoin...';
      _hasError = false;
      _sellResults = [];
    });

    try {
      developer.log('Starting sell all assets operation to $_selectedStablecoin', name: 'PanicButtonScreen');
      
      // Execute sell operation
      final results = await _binanceService.sellAllAssetsToStablecoin(_selectedStablecoin!);
      
      // Count successful and failed transactions
      final successCount = results.where((r) => r['status'].toString().contains('sold')).length;
      final failedCount = results.where((r) => r['status'] == 'failed').length;
      final skippedCount = results.where((r) => r['status'] == 'skipped').length;
      
      developer.log('Sell operation completed: $successCount sold, $failedCount failed, $skippedCount skipped', 
          name: 'PanicButtonScreen');
      
      setState(() {
        _isSelling = false;
        _statusMessage = 'Sell operation completed: $successCount assets sold' + 
            (failedCount > 0 ? ', $failedCount failed' : '') + 
            (skippedCount > 0 ? ', $skippedCount skipped' : '');
        _sellResults = results;
      });

      // Refresh balances after selling with a slight delay to allow API to update
      Future.delayed(const Duration(seconds: 2), () {
        _loadData();
      });
    } catch (e) {
      developer.log('Error during sell operation: ${e.toString()}', name: 'PanicButtonScreen', error: e);
      
      // Format error message for better user experience
      String errorMsg;
      
      if (e.toString().contains('API error')) {
        errorMsg = e.toString();
      } else if (e.toString().contains('Network error')) {
        errorMsg = 'Cannot connect to Binance. Please check your internet connection.';
      } else if (e.toString().contains('Connection timeout')) {
        errorMsg = 'Connection timeout. Binance servers might be busy, please try again later.';
      } else {
        errorMsg = 'Error during sell operation: ${e.toString()}';
      }
      
      setState(() {
        _isSelling = false;
        _statusMessage = errorMsg;
        _hasError = true;
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
            onPressed: _isLoading ? null : _loadData,
            tooltip: 'Refresh data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text(
                      'Are you sure you want to logout? This will remove your API credentials from this device.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ) ?? false;

              if (confirmed) {
                await _binanceService.clearCredentials();
                widget.onLogout();
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select target stablecoin:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton2<String>(
                      isExpanded: true,
                      hint: const Text('Select stablecoin'),
                      value: _selectedStablecoin,
                      items: _stablecoins
                          .map((item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ))
                          .toList(),
                      onChanged: _isLoading || _isSelling
                          ? null
                          : (value) {
                              setState(() {
                                _selectedStablecoin = value;
                              });
                            },
                      buttonStyleData: const ButtonStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        height: 50,
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 40,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: (_isLoading || _isSelling) ? null : _sellAllAssets,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _isSelling
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('PANIC SELL ALL ASSETS'),
              ),
            ),
            const SizedBox(height: 16),
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                color: _hasError ? Colors.red.shade100 : Colors.blue.shade100,
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _hasError ? Colors.red.shade900 : Colors.blue.shade900,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Balances:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (!_isLoading && _balances.isNotEmpty)
                  Text(
                    '${_balances.length} assets',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _balances.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_wallet_outlined, 
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text('No assets found',
                                  style: TextStyle(fontSize: 16, color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _balances.length,
                          itemBuilder: (context, index) {
                            final balance = _balances[index];
                            final asset = balance['asset'];
                            final free = double.parse(balance['free']);
                            final locked = double.parse(balance['locked']);
                            final total = free + locked;
                            
                            // Format numbers with appropriate precision
                            String formatBalance(double value) {
                              if (value == 0) return '0';
                              if (value < 0.0001) return value.toStringAsExponential(2);
                              if (value < 1) return value.toStringAsFixed(6);
                              if (value < 1000) return value.toStringAsFixed(4);
                              return value.toStringAsFixed(2);
                            }
                            
                            // Determine asset color based on value
                            Color assetColor;
                            if (asset == _selectedStablecoin) {
                              assetColor = Colors.green.shade700;
                            } else if (['BTC', 'ETH', 'BNB'].contains(asset)) {
                              assetColor = Colors.blue.shade700;
                            } else {
                              assetColor = Colors.blueGrey.shade700;
                            }
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    // Asset icon/circle
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: assetColor.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          asset.length > 2 ? asset.substring(0, 2) : asset,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: assetColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Asset details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            asset,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (locked > 0)
                                            Text(
                                              'Free: ${formatBalance(free)} · Locked: ${formatBalance(locked)}',
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Total balance
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          formatBalance(total),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'Total',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            if (_sellResults.isNotEmpty) ...[  
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sell Results:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_sellResults.length} transactions',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _sellResults.length,
                  itemBuilder: (context, index) {
                    final result = _sellResults[index];
                    final isSuccess = result['status'] != 'failed';
                    final asset = result['asset'];
                    
                    // Determine asset color based on value
                    Color assetColor;
                    if (['BTC', 'ETH', 'BNB'].contains(asset)) {
                      assetColor = Colors.blue.shade700;
                    } else {
                      assetColor = Colors.blueGrey.shade700;
                    }
                    
                    return InkWell(
                      onTap: () {
                        // Show dialog for failed transactions and skipped assets
                        if (result.containsKey('error')) {
                          _showErrorDetailsDialog(context, asset, result['error']);
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Asset icon/circle
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(result['status']).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    _getStatusIcon(result['status']),
                                    color: _getStatusColor(result['status']),
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Asset details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      asset,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      result['status'],
                                      style: TextStyle(
                                        color: _getStatusColor(result['status']).shade700,
                                        fontWeight: isSuccess ? FontWeight.normal : FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Error or skipped details if any
                              if (result.containsKey('error'))
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.orange),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Tap for details',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}