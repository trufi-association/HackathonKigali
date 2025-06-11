import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class TrufiMapStateController extends ChangeNotifier {
  final List<Marker> _markers;

  TrufiMapStateController({List<Marker>? initialMarkers})
      : _markers = initialMarkers ?? [];

  List<Marker> get markers => List.unmodifiable(_markers);

  void addMarker(Marker marker) {
    _markers.add(marker);
    notifyListeners();
  }

  void removeMarker(Marker marker) {
    _markers.remove(marker);
    notifyListeners();
  }

  void clearMarkers() {
    _markers.clear();
    notifyListeners();
  }
}
