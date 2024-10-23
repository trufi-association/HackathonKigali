import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:stadtnavi_core/base/pages/home/services/custom_search_location/location_model.dart';
import 'package:stadtnavi_core/consts.dart';

import 'package:trufi_core/base/models/trufi_place.dart';
import 'package:trufi_core/base/pages/home/services/exception/fetch_online_exception.dart';
import 'package:trufi_core/base/pages/saved_places/repository/search_location_repository.dart';

class KigaliOnlineSearchLocation implements SearchLocationRepository {
  static const String searchEndpoint = 'https://kigali.trufi.dev/photon/api/';

  final Map<String, dynamic>? queryParameters;

  const KigaliOnlineSearchLocation({
    this.queryParameters = const {},
  });
  @override
  Future<List<TrufiPlace>> fetchLocations(
    String query, {
    int limit = 15,
    String? correlationId,
    String? lang = "en",
  }) async {
    final extraQueryParameters = queryParameters ?? {};
    final Uri request = Uri.parse(
      ApiConfig().searchPhotonEndpoint,
    ).replace(
        queryParameters: {"q": query, "lang": lang, ...extraQueryParameters});
    final response = await _fetchRequest(request);
    if (response.statusCode != 200) {
      throw "Not found locations";
    } else {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final dataJson = List<Map<String, dynamic>>.from(json["features"]);
      final trufiLocationList = dataJson
          .map((x) => LocationModel.fromJson(x).toTrufiLocation())
          .toList();
      return trufiLocationList;
    }
  }

  Future<http.Response> _fetchRequest(Uri request) async {
    try {
      return await http.get(
        request,
      );
    } on Exception catch (e) {
      throw FetchOnlineRequestException(e);
    }
  }

  @override
  Future<LocationDetail> reverseGeodecoding(LatLng location) async {
    final response = await http.get(
      Uri.parse(
        "${ApiConfig().reverseGeodecodingPhotonEndpoint}?lat=${location.latitude}&lon=${location.longitude}",
      ),
      headers: {},
    );
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    final features = body["features"] as List;
    final feature = features.first;
    final properties = feature["properties"];
    final String? street = properties["street"]?.toString();
    final String? houseNumbre = properties["housenumber"]?.toString();
    final String? postalcode = properties["district"]?.toString();
    final String? locality = properties["country"]?.toString();
    String streetHouse = "";
    if (street != null) {
      if (houseNumbre != null) {
        streetHouse = "$street $houseNumbre,";
      } else {
        streetHouse = "$street,";
      }
    }
    return LocationDetail(
      properties?["name"]?.toString() ?? 'Not name',
      "$streetHouse $postalcode $locality",
      location,
    );
  }
}
