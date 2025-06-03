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

  String openTripPlannerUrl = "https://otp.kigali.trufi.dev/otp/transmodel/v3";
  String searchPhotonEndpoint = "https://kigali.trufi.dev/photon/api/";
  String reverseGeodecodingPhotonEndpoint =
      "https://kigali.trufi.dev/photon/reverse/";
  String mapEndpoint = "https://kigali.trufi.dev/static-maps/trufi-liberty/";
  String faresURL = "https://kigali.trufi.dev/fares";
}
