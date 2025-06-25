import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;

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

  bool addLayer(TrufiLayer layer) {
    final layers = Map<String, TrufiLayer>.from(layersNotifier.value);
    if (layers.containsKey(layer.id)) return false;
    layers[layer.id] = layer;
    layersNotifier.value = layers;
    return true;
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
    layers[layerId] = TrufiLayer(
      id: layer.id,
      visible: visible,
      entries: layer.entries,
    );
    layersNotifier.value = layers;
    return true;
  }

  bool addMarkerToLayer(String layerId, TrufiMarker marker) {
    final layers = Map<String, TrufiLayer>.from(layersNotifier.value);
    final layer = layers[layerId];
    if (layer == null) return false;
    layers[layerId] = TrufiLayer(
      id: layer.id,
      visible: layer.visible,
      entries: [...layer.entries, marker],
    );
    layersNotifier.value = layers;
    return true;
  }
}

class TrufiMarker {
  TrufiMarker({
    required this.id,
    required this.position,
    required this.widget,
    this.size = const Size(30, 30),
    this.rotation = 0,
    this.visible = true,
  });

  final String id;
  final latlng.LatLng position;
  final Widget widget;
  final Size size;
  final double rotation;
  final bool visible;
}

class TrufiLayer {
  TrufiLayer({
    required this.id,
    this.visible = true,
    List<TrufiMarker>? entries,
  }) : entries = entries ?? <TrufiMarker>[];

  final String id;
  final bool visible;
  final List<TrufiMarker> entries;
}
