# Binance Panic Button

A Flutter app I built to give you a one-click solution to quickly sell all your crypto assets to a stablecoin when the market goes south. We've all been there - watching our portfolios tank while frantically trying to sell everything. This app solves that problem.

![Binance Panic Button](https://img.shields.io/badge/Binance-Panic%20Button-red)
![Flutter](https://img.shields.io/badge/Flutter-3.7+-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## 🚨 Why I Built This

After losing money in one too many flash crashes, I got tired of manually selling each asset while prices kept dropping. This app lets you hit one button and convert everything to your favorite stablecoin - no more panic selling each coin individually while watching your portfolio melt.

## ✨ What It Does

- **One-Tap Panic Sell**: Dump all your assets to a stablecoin with a single button press
- **Pick Your Safe Haven**: Choose which stablecoin you want (USDT, BUSD, USDC, etc.)
- **See What You've Got**: Real-time display of all your current balances
- **Your Keys Stay Safe**: Secure encrypted storage for your API keys
- **Practice Mode**: Test with Binance Testnet before risking real money
- **Know What Happened**: Detailed results showing what sold, what didn't, and why
- **Works Offline**: Checks if you're connected before attempting trades

## 📱 Screenshots

<img src="https://github.com/user-attachments/assets/627eda31-52dc-44dd-b00f-ab023702a281" width="300">
<img src="https://github.com/user-attachments/assets/eb770e6d-ca34-4b25-9514-69c8d3faabd7" width="300">

## 🔧 Getting Started

### What You'll Need

- Flutter SDK (3.7+)
- Dart SDK (3.0+)
- A Binance account with API access

### Installation

1. Clone this repo
   ```
   git clone https://github.com/yourusername/binance_panic_button.git
   ```

2. Go to the project folder
   ```
   cd binance_panic_button
   ```

3. Get the dependencies
   ```
   flutter pub get
   ```

4. Run it
   ```
   flutter run
   ```

## 🔑 Setting Up Your Binance API Keys

1. Log into Binance
2. Go to API Management (in your profile)
3. Create a new API key
4. **Important**: Make sure to enable trading permissions
5. For your own safety:
   - Restrict API access to your IP address
   - Don't enable withdrawal permissions
   - Use 2FA on your Binance account

## 🛡️ Security Stuff

I take security seriously:
- Your API keys are stored with encryption using Flutter Secure Storage
- Nothing gets sent to any remote servers
- The app only uses your keys for trading, not withdrawals
- Try the Testnet version first if you're nervous

## 📖 How to Use It

1. **Login**: Enter your Binance API and Secret keys
2. **Pick a Stablecoin**: Choose which one you want to convert to
3. **Check Your Balances**: See what you're holding
4. **Hit the Button**: When things go south, smash that red "PANIC SELL ALL ASSETS" button
5. **See What Happened**: Check which assets sold successfully

## ⚠️ Things to Know

- The app does market sells, so expect some slippage in crazy markets
- Some coins might not have direct trading pairs with your stablecoin
- For those, the app will try to sell through BTC as an intermediary
- Tiny balances might get skipped due to Binance's minimum trade requirements

## 🔍 Troubleshooting

- **Can't Connect**: Double-check your API keys and make sure they have trading permissions
- **Failed Sales**: Check if the trading pair exists or if you have enough balance
- **Network Issues**: Make sure you have a decent internet connection

## 📄 License

This project is under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Want to help make this better? Contributions, issues, and feature requests are welcome! Just check out the issues page.

## ⚡ Support My Work

If you find this app useful and want to buy me a coffee, you can send some sats to my lightning address:

**opulentmenu06@walletofsatoshi.com**

## 📧 Contact

Questions or feedback? Just open an issue on GitHub.

---

*Disclaimer: This app isn't affiliated with Binance. Use at your own risk. I'm not responsible for any money you might lose while using it.*
