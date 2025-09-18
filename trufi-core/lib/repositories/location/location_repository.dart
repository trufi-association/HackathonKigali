import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:trufi_core/consts.dart';
import 'package:trufi_core/repositories/location/interfaces/i_location_search_service.dart';
import 'package:trufi_core/repositories/location/interfaces/i_location_service.dart';
import 'package:trufi_core/repositories/location/models/defaults_location.dart';
import 'package:trufi_core/repositories/location/services/hive_local_service.dart';
import 'package:trufi_core/repositories/location/services/photon_location_search_service.dart';
import 'package:trufi_core/screens/route_navigation/maps/trufi_map_controller.dart';

class LocationRepository {
  final ILocationService locationService = HiveLocationService();

  final ILocationSearchService locationSearchService =
      PhotonLocationSearchService(photonUrl: ApiConfig().searchPhotonEndpoint);

  LocationRepository()
    : myPlaces = ValueNotifier([]),
      myDefaultPlaces = ValueNotifier([]),
      historyPlaces = ValueNotifier([]),
      favoritePlaces = ValueNotifier([]),
      searchResult = ValueNotifier([]),
      isLoading = ValueNotifier(false);

  final ValueNotifier<List<TrufiLocation>> myPlaces;
  final ValueNotifier<List<TrufiLocation>> myDefaultPlaces;
  final ValueNotifier<List<TrufiLocation>> historyPlaces;
  final ValueNotifier<List<TrufiLocation>> favoritePlaces;
  final ValueNotifier<List<TrufiLocation>> searchResult;
  final ValueNotifier<bool> isLoading;

  Timer _debounceTimer = Timer(const Duration(milliseconds: 300), () {});

  Future<void> fetchLocations(
    String query, {
    String? correlationId,
    int limit = 30,
  }) async {
    _debounceTimer.cancel();
    isLoading.value = true;

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (query.isNotEmpty) {
        final results = await locationSearchService.fetchLocations(
          query,
          limit: limit,
        );
        searchResult.value = results;
        isLoading.value = false;
      } else {
        isLoading.value = false;
      }
    });
  }

  Future<TrufiLocation> reverseGeodecoding(LatLng location) =>
      locationSearchService.reverseGeodecoding(location);

  Future<void> initLoad() async {
    await locationService.loadRepository();
    List<TrufiLocation> myDefaultPlacesTemp = await locationService
        .getMyDefaultPlaces();
    if (myDefaultPlacesTemp.isEmpty) {
      myDefaultPlaces.value = [
        DefaultLocationEnum.defaultHome.initLocation,
        DefaultLocationEnum.defaultWork.initLocation,
      ];
    }
    myPlaces.value = await locationService.getMyPlaces();
    favoritePlaces.value = await locationService.getFavoritePlaces();
    historyPlaces.value = await locationService.getHistoryPlaces();
    myDefaultPlaces.value = myDefaultPlacesTemp;
    await locationService.saveMyDefaultPlaces(myDefaultPlacesTemp);
  }

  Future<void> insertMyPlace(TrufiLocation location) async {
    myPlaces.value = [...myPlaces.value, location];
    await locationService.saveMyPlaces(myPlaces.value);
  }

  Future<void> insertHistoryPlace(TrufiLocation location) async {
    historyPlaces.value = [
      ..._deleteAllItem(historyPlaces.value, location),
      location,
    ];
    await locationService.saveHistoryPlaces(historyPlaces.value);
  }

  Future<void> insertFavoritePlace(TrufiLocation location) async {
    favoritePlaces.value = [...favoritePlaces.value, location];
    await locationService.saveFavoritePlaces(favoritePlaces.value);
  }

  Future<void> updateMyPlace(TrufiLocation old, TrufiLocation location) async {
    myPlaces.value = [..._updateItem(myPlaces.value, old, location)];
    await locationService.saveMyPlaces(myPlaces.value);
  }

  Future<void> updateMyDefaultPlace(
    TrufiLocation old,
    TrufiLocation location,
  ) async {
    myDefaultPlaces.value = [
      ..._updateItem(myDefaultPlaces.value, old, location),
    ];
    await locationService.saveMyDefaultPlaces(myDefaultPlaces.value);
  }

  Future<void> updateHistoryPlace(
    TrufiLocation old,
    TrufiLocation location,
  ) async {
    historyPlaces.value = [..._updateItem(historyPlaces.value, old, location)];
    await locationService.saveHistoryPlaces(historyPlaces.value);
  }

  Future<void> updateFavoritePlace(
    TrufiLocation old,
    TrufiLocation location,
  ) async {
    favoritePlaces.value = [
      ..._updateItem(favoritePlaces.value, old, location),
    ];
    await locationService.saveFavoritePlaces(favoritePlaces.value);
  }

  List<TrufiLocation> _updateItem(
    List<TrufiLocation> list,
    TrufiLocation oldLocation,
    TrufiLocation newLocation,
  ) {
    final tempList = [...list];
    final int index = tempList.indexOf(oldLocation);
    if (index != -1) {
      tempList.replaceRange(index, index + 1, [newLocation]);
    }
    return tempList;
  }

  Future<void> deleteMyPlace(TrufiLocation location) async {
    myPlaces.value = [..._deleteItem(myPlaces.value, location)];
    await locationService.saveMyPlaces(myPlaces.value);
  }

  Future<void> deleteHistoryPlace(TrufiLocation location) async {
    historyPlaces.value = [..._deleteItem(historyPlaces.value, location)];
    await locationService.saveHistoryPlaces(historyPlaces.value);
  }

  Future<void> deleteFavoritePlace(TrufiLocation location) async {
    favoritePlaces.value = [..._deleteItem(favoritePlaces.value, location)];
    await locationService.saveFavoritePlaces(favoritePlaces.value);
  }

  List<TrufiLocation> sortedByFavorites(List<TrufiLocation> locations) {
    locations.sort((a, b) {
      return _sortByFavoriteLocations(a, b, favoritePlaces.value);
    });
    return locations;
  }

  int _sortByFavoriteLocations(
    TrufiLocation a,
    TrufiLocation b,
    List<TrufiLocation> favorites,
  ) {
    final bool aIsAvailable = favorites.contains(a);
    final bool bIsAvailable = favorites.contains(b);
    return aIsAvailable == bIsAvailable
        ? 0
        : aIsAvailable
        ? -1
        : 1;
  }

  List<TrufiLocation> _deleteItem(
    List<TrufiLocation> list,
    TrufiLocation location,
  ) {
    final tempList = [...list];
    tempList.remove(location);
    return tempList;
  }

  List<TrufiLocation> _deleteAllItem(
    List<TrufiLocation> list,
    TrufiLocation location,
  ) {
    final tempList = [...list];
    return tempList.where((value) => value != location).toList();
  }
}
