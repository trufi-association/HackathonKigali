import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:trufi_core/screens/route_navigation/maps/trufi_map_controller.dart';
import 'package:trufi_core/repositories/location/interfaces/i_location_search_service.dart';
import 'package:trufi_core/repositories/location/models/location_search_model.dart';
import 'package:trufi_core/utils/packge_info_platform.dart';

class PhotonLocationSearchService implements ILocationSearchService {
  final String photonUrl;
  final Map<String, dynamic>? queryParameters;

  const PhotonLocationSearchService({
    required this.photonUrl,
    this.queryParameters = const {},
  });

  @override
  Future<List<TrufiLocation>> fetchLocations(
    String query, {
    int limit = 15,
    String? correlationId,
    String? lang = "es",
  }) async {
    final extraQueryParameters = queryParameters ?? {};
    final Uri request = Uri.parse("$photonUrl/api").replace(
      queryParameters: {
        "q": query,
        // "bbox": "-66.453088,-17.762296,-65.758056,-17.238372",
        ...extraQueryParameters,
      },
    );
    final response = await _fetchRequest(request);
    if (response.statusCode != 200) {
      throw "Not found locations";
    } else {
      // location results
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final trufiLocationList =
          List<Map<String, dynamic>>.from(json["features"])
              .map((e) => LocationSearchResponse.fromJson(e))
              .map((x) => x.toTrufiLocation())
              .toList();

      return trufiLocationList;
    }
  }

  @override
  Future<TrufiLocation> reverseGeodecoding(LatLng location) async {
    final response = await _fetchRequest(
      Uri.parse(
        "$photonUrl/reverse?lon=${location.longitude}&lat=${location.latitude}",
      ),
    );
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body["type"] == "FeatureCollection") {
      final features = body["features"] as List;
      if (features.isNotEmpty) {
        final feature = features.first;
        final properties = feature["properties"];
        return LocationSearchResponse(
          name: properties["name"],
          street: properties["street"] ?? "",
          latLng: location,
        ).toTrufiLocation();
      }
    }
    throw Exception("No data found");
  }

  Future<http.Response> _fetchRequest(Uri request) async {
    final userAgent = await PackageInfoPlatform.getUserAgent();
    return await http.get(request, headers: {"User-Agent": userAgent});
  }
}
