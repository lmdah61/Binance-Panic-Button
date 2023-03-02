const String BASE_URL = 'api.binance.com';

const String API_KEY_STORAGE_ID = 'api_key';

const String API_SECRET_STORAGE_ID = 'api_secret';

const String TARGET_STABLE_COIN = 'USDT'; // Everything will be sold to USDT

// A list of all the stable coins from binance. These coins won't be touched.
const Set<String> STABLE_COINS = {
  "USDT",
  "USDC",
  "BUSD",
  "TUSD",
  "PAX",
  "GUSD",
  "DAI",
  "HUSD",
  "EURS",
  "USDN"
};
