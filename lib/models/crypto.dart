class Crypto {
  late  String asset; // the asset (BNB, BTC, ETH...))
  late  String free; // the free amount
  late  String locked; // the locked amount

  Crypto({required this.asset, required this.free, required this.locked});

  // This factory constructor is used to fill the variables with data from a json object
  factory Crypto.fromJson(Map<String, dynamic> json) {
    return Crypto(
      asset: json['asset'],
      free: json['free'],
      locked: json['locked'],
    );
  }

  // getters for the variables
  String getAsset() => asset;
  String getFree() => free;
  String getLocked() => locked;

  // setters for the variables
  void setAsset(String newAsset) => asset = newAsset;
  void setFree(String newFree) => free = newFree;
  void setLocked(String newLocked) => locked = newLocked;
}