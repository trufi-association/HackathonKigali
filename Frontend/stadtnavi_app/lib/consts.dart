class ApiConfig {
  ApiConfig._privateConstructor() {
    _checkDateAndUpdateDomain();
  }

  static final ApiConfig _instance = ApiConfig._privateConstructor();

  factory ApiConfig() {
    return _instance;
  }

  String baseDomain = "kigali.trufi.dev";

  void _checkDateAndUpdateDomain() {
    var currentDate = DateTime.now();
    var switchDate = DateTime(2023, 12, 28);
    if (currentDate.isAfter(switchDate)) {
      baseDomain = "kigali.trufi.dev";
    }
  }

  String get openTripPlannerUrl =>
      "https://$baseDomain/otp/index/graphql";
  String get faresURL => "https://$baseDomain/fares";
}
