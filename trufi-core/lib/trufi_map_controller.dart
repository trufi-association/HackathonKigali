import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:trufi_core/image_tool.dart';

class TrufiCameraPosition {
  const TrufiCameraPosition({
    required this.target,
    this.zoom = 0.0,
    this.bearing = 0.0,
  });

  final latlng.LatLng target;
  final double zoom;
  final double bearing;

  TrufiCameraPosition copyWith({
    latlng.LatLng? target,
    double? zoom,
    double? bearing,
  }) => TrufiCameraPosition(
    target: target ?? this.target,
    zoom: zoom ?? this.zoom,
    bearing: bearing ?? this.bearing,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrufiCameraPosition &&
          runtimeType == other.runtimeType &&
          target == other.target &&
          zoom == other.zoom &&
          bearing == other.bearing;

  @override
  int get hashCode => target.hashCode ^ zoom.hashCode ^ bearing.hashCode;
}

class TrufiMapController {
  TrufiMapController({required TrufiCameraPosition initialCameraPosition})
    : cameraPositionNotifier = ValueNotifier(initialCameraPosition),
      layersNotifier = ValueNotifier({});

  final ValueNotifier<TrufiCameraPosition> cameraPositionNotifier;
  final ValueNotifier<Map<String, TrufiLayer>> layersNotifier;

  List<TrufiLayer> get visibleLayers =>
      layersNotifier.value.values.where((l) => l.visible).toList();

  bool setCameraPosition(TrufiCameraPosition position) {
    if (position == cameraPositionNotifier.value) return false;
    cameraPositionNotifier.value = position;
    return true;
  }

  bool updateCamera({latlng.LatLng? target, double? zoom, double? bearing}) {
    final next = cameraPositionNotifier.value.copyWith(
      target: target,
      zoom: zoom,
      bearing: bearing != null ? bearing % 360 : null,
    );
    return setCameraPosition(next);
  }

  void mutateLayers() {
    final layers = Map<String, TrufiLayer>.from(layersNotifier.value);
    layersNotifier.value = layers;
  }

  bool addLayer(TrufiLayer layer) {
    final layers = Map<String, TrufiLayer>.from(layersNotifier.value);
    if (layers.containsKey(layer.id)) return false;
    layers[layer.id] = layer;
    layersNotifier.value = layers;
    return true;
  }

  TrufiLayer? getLayerById(String layerId) {
    return layersNotifier.value[layerId];
  }

  bool removeLayer(String layerId) {
    final layers = Map<String, TrufiLayer>.from(layersNotifier.value);
    if (!layers.containsKey(layerId)) return false;
    layers.remove(layerId);
    layersNotifier.value = layers;
    return true;
  }

  bool toggleLayer(String layerId, bool visible) {
    final layers = Map<String, TrufiLayer>.from(layersNotifier.value);
    final layer = layers[layerId];
    if (layer == null || layer.visible == visible) return false;
    layer.visible = visible;
    layersNotifier.value = layers;
    return true;
  }
}

class TrufiMarker {
  TrufiMarker({
    required this.id,
    required this.position,
    required this.widget,
    this.widgetBytes,
    this.layerLevel = 1,
    this.size = const Size(30, 30),
    this.rotation = 0,
    this.visible = true,
    this.alignment,
  });

  final String id;
  final latlng.LatLng position;
  final Widget widget;
  Uint8List? widgetBytes;
  final int layerLevel;
  final Size size;
  final double rotation;
  final bool visible;
  final String? alignment;

  Future<void> generateBytes(BuildContext context) async {
    try {
      widgetBytes = await ImageTool.widgetToBytes(this, context);
    } catch (e, stack) {
      debugPrint('Error generating bytes for marker $id: $e\n$stack');
    }
  }
}

class TrufiLine {
  TrufiLine({
    required this.id,
    required this.position,
    this.color = Colors.black,
    this.layerLevel = 1,
    this.lineWidth = 2,
    this.activeDots = false,
    this.visible = true,
  });

  final String id;
  final List<latlng.LatLng> position;
  final Color color;
  final int layerLevel;
  final double lineWidth;
  final bool activeDots;
  final bool visible;
}

abstract class TrufiLayer {
  TrufiLayer(this.controller, {required this.id, this.visible = true}) {
    controller.addLayer(this);
  }

  final TrufiMapController controller;
  String id;
  bool visible;
  List<TrufiMarker> get entries;
  List<TrufiLine> get lines;
  void mutateLayers() => controller.mutateLayers();
}

class TrufiLocation {
  static const String origin = 'origin_location';
  static const String destination = 'destination_location';
  final String description;
  final latlng.LatLng position;
  final List<String>? alternativeNames;
  final Map<String, String>? localizedNames;
  final String? address;
  final String? type;

  TrufiLocation({
    required this.description,
    required this.position,
    this.alternativeNames,
    this.localizedNames,
    this.address,
    this.type,
  });

  TrufiLocation copyWith({
    String? description,
    latlng.LatLng? position,
    List<String>? alternativeNames,
    Map<String, String>? localizedNames,
    String? address,
    String? type,
  }) {
    return TrufiLocation(
      description: description ?? this.description,
      position: position ?? this.position,
      alternativeNames: alternativeNames ?? this.alternativeNames,
      localizedNames: localizedNames ?? this.localizedNames,
      address: address ?? this.address,
      type: type ?? this.type,
    );
  }

  factory TrufiLocation.fromLocationsJson(Map<String, dynamic> json) {
    return TrufiLocation(
      description: json['name'],
      position: latlng.LatLng(json['coords']['lat'], json['coords']['lng']),
    );
  }

  factory TrufiLocation.fromSearchPlacesJson(List<dynamic> json) {
    return TrufiLocation(
      description: json[0].toString(),
      alternativeNames: json[1].cast<String>() as List<String>?,
      localizedNames: json[2].cast<String, String>() as Map<String, String>?,
      position: latlng.LatLng(json[3][1], json[3][0]),
      address: json[4] as String?,
      type: json[5] as String?,
    );
  }

  // factory TrufiLocation.fromPlanLocation(PlanLocation value) {
  //   return TrufiLocation(
  //     description: value.name,
  //     latitude: value.latitude,
  //     longitude: value.longitude,
  //   );
  // }

  factory TrufiLocation.fromSearch(Map<String, dynamic> json) {
    return TrufiLocation(
      description: json['description'] as String,
      position: latlng.LatLng(json["latitude"], json["longitude"]),
    );
  }

  factory TrufiLocation.fromJson(Map<String, dynamic> json) {
    return TrufiLocation(
      description: json["description"],
      position: latlng.LatLng(json["latitude"], json["longitude"]),
      type: json["type"],
      address: json["address"],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "description": description,
      "latitude": position.latitude,
      "longitude": position.longitude,
      "type": type,
      "address": address ?? '',
    };
  }

  @override
  bool operator ==(Object other) =>
      other is TrufiLocation &&
      other.description == description &&
      other.position.latitude == position.latitude &&
      other.position.longitude == position.longitude &&
      other.type == type;

  @override
  int get hashCode =>
      description.hashCode ^
      position.latitude.hashCode ^
      position.longitude.hashCode;

  @override
  String toString() {
    return '${position.latitude},${position.longitude}';
  }

  bool get isLatLngDefined => position.latitude != 0 && position.longitude != 0;
}
