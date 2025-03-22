# Binance Panic Button

A Flutter application that provides a one-click solution to quickly sell all your cryptocurrency assets to a stablecoin during market crashes or emergencies.

![Binance Panic Button](https://img.shields.io/badge/Binance-Panic%20Button-red)
![Flutter](https://img.shields.io/badge/Flutter-3.7+-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## 🚨 Purpose

Crypto markets can be extremely volatile. When a market crash happens, you might want to quickly convert all your assets to stablecoins to preserve value. This app provides a simple, one-tap solution to do exactly that - sell all your assets to your preferred stablecoin with a single button press.

## ✨ Features

- **One-Click Panic Sell**: Convert all your assets to a stablecoin with a single tap
- **Stablecoin Selection**: Choose your preferred stablecoin (USDT, BUSD, USDC, etc.)
- **Real-time Balance Display**: View all your current asset balances
- **Secure API Integration**: Your API keys are stored securely using encrypted storage
- **Testnet Support**: Practice with Binance Testnet before using on the main network
- **Detailed Transaction Results**: See which assets were sold successfully, which failed, and why
- **Offline Detection**: Automatic network connectivity checks

## 📱 Screenshots

![Screenshot_20250322_163815](https://github.com/user-attachments/assets/627eda31-52dc-44dd-b00f-ab023702a281)
![Screenshot_20250322_163906](https://github.com/user-attachments/assets/eb770e6d-ca34-4b25-9514-69c8d3faabd7)

## 🔧 Installation

### Prerequisites

- Flutter SDK (version 3.7 or higher)
- Dart SDK (version 3.0 or higher)
- A Binance account with API access

### Getting Started

1. Clone this repository
   ```
   git clone https://github.com/yourusername/binance_panic_button.git
   ```

2. Navigate to the project directory
   ```
   cd binance_panic_button
   ```

3. Install dependencies
   ```
   flutter pub get
   ```

4. Run the app
   ```
   flutter run
   ```

## 🔑 Setting Up Binance API Keys

1. Log in to your Binance account
2. Navigate to API Management (under your profile)
3. Create a new API key
4. **Important**: Enable trading permissions for your API key
5. For security reasons, it's recommended to:
   - Restrict API access to specific IP addresses
   - Disable withdrawal permissions
   - Enable 2FA on your Binance account

## 🛡️ Security Considerations

- Your API keys are stored securely using Flutter Secure Storage with encryption
- The app never stores your keys on a remote server
- API keys are only used for trading operations, not withdrawals
- Consider using Binance Testnet first to verify the app's functionality

## 📖 How to Use

1. **Login**: Enter your Binance API and Secret keys
2. **Select Stablecoin**: Choose which stablecoin you want to convert your assets to
3. **View Balances**: See your current asset holdings
4. **Panic Sell**: When needed, press the red "PANIC SELL ALL ASSETS" button
5. **Review Results**: Check which assets were sold successfully and which weren't

## ⚠️ Important Notes

- The app performs market sells, which may result in slippage during high volatility
- Some assets might not have direct trading pairs with your selected stablecoin
- The app will attempt to sell through BTC as an intermediary when direct pairs aren't available
- Small balances might be skipped due to Binance's minimum trade size requirements

## 🔍 Troubleshooting

- **API Connection Issues**: Verify your API keys and ensure they have trading permissions
- **Failed Transactions**: Check if the trading pair exists or if you have sufficient balance
- **Network Errors**: Ensure you have a stable internet connection

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the issues page.

## 📧 Contact

If you have any questions or feedback, please open an issue on GitHub.

---

*Disclaimer: This app is not affiliated with Binance. Use at your own risk. The developers are not responsible for any financial losses incurred while using this application.*
