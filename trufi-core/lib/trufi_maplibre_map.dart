import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:trufi_core/image_tool.dart';
import 'package:trufi_core/trufi_map_controller.dart';

class TrufiMapLibreMap extends StatefulWidget {
  const TrufiMapLibreMap({
    super.key,
    required this.controller,
    required this.routingMapComponent,
    required this.styleString,
  });
  final TrufiMapController controller;
  final RoutingMapComponent routingMapComponent;
  final String styleString;

  @override
  State<TrufiMapLibreMap> createState() => _TrufiMapLibreMapState();
}

class _TrufiMapLibreMapState extends State<TrufiMapLibreMap> {
  MapLibreMapController? _mapCtl;
  bool _mapReady = false;
  bool _suppressSync = false;
  final Set<String> _renderedMarkerIds = <String>{};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.cameraPositionNotifier.addListener(_cameraListener);
      widget.controller.layersNotifier.addListener(_layersListener);
    });
  }

  void _cameraListener() {
    final camera = widget.controller.cameraPositionNotifier.value;
    if (_mapReady && _mapCtl != null) {
      _suppressSync = true;
      _mapCtl!.animateCamera(
        CameraUpdate.newCameraPosition(_toCameraPosition(camera)),
      );
    }
  }

  void _layersListener() {
    final visibleLayers = widget.controller.visibleLayers;
    if (_mapReady && _mapCtl != null) {
      _syncLayers(visibleLayers);
    }
  }

  @override
  void dispose() {
    widget.controller.cameraPositionNotifier.removeListener(_cameraListener);
    widget.controller.layersNotifier.removeListener(_layersListener);
    super.dispose();
  }

  Future<void> _handleCameraIdle() async {
    if (_suppressSync) {
      _suppressSync = false;
      return;
    }
    final ctl = _mapCtl;
    if (ctl == null) return;
    final cam = await ctl.cameraPosition!;
    widget.controller.updateCamera(
      target: latlng.LatLng(cam.target.latitude, cam.target.longitude),
      zoom: toLeafletZoom(cam.zoom),
      bearing: toLeafletBearing(cam.bearing),
    );
  }

  Future<void> _syncLayers(List<TrufiLayer> visibleLayers) async {
    final ctl = _mapCtl;
    if (ctl == null) return;

    final newMarkerIds = <String>{};
    final markersToAdd = <({TrufiMarker marker, Uint8List imageBytes})>[];

    for (final layer in visibleLayers) {
      for (final marker in layer.entries.where((m) => m.visible)) {
        newMarkerIds.add(marker.id);
        if (!_renderedMarkerIds.contains(marker.id)) {
          final bytes = await _widgetToBytes(marker);
          markersToAdd.add((marker: marker, imageBytes: bytes));
        }
      }
    }

    // Remove old markers
    final idsToRemove = _renderedMarkerIds.difference(newMarkerIds);
    for (final id in idsToRemove) {
      try {
        await ctl.removeSymbols(ctl.symbols?.where((s) => s.data?["id"] == id).toList() ?? []);
      } catch (_) {}
    }

    for (final entry in markersToAdd) {
      final marker = entry.marker;
      final bytes = entry.imageBytes;
      final id = 'marker_${marker.id}';

      await ctl.addImage(id, bytes);
      await ctl.addSymbol(
        SymbolOptions(
          geometry: LatLng(marker.position.latitude, marker.position.longitude),
          iconImage: id,
          iconSize: marker.size.width / 30.0,
          iconRotate: marker.rotation,
        ),
        {'id': marker.id},
      );
    }

    _renderedMarkerIds
      ..clear()
      ..addAll(newMarkerIds);
  }

  Future<Uint8List> _widgetToBytes(TrufiMarker marker) {
    final sizedWidget = SizedBox(
      width: marker.size.width,
      height: marker.size.height,
      child: marker.widget,
    );
    return ImageTool.widgetToPng(sizedWidget);
  }

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      initialCameraPosition: _toCameraPosition(
        widget.controller.cameraPositionNotifier.value,
      ),
      styleString: widget.styleString,
      trackCameraPosition: true,
      compassEnabled: false,
      onMapCreated: (ctl) async {
        _mapCtl = ctl;
        _mapReady = true;
        await _syncLayers(
          widget.controller.visibleLayers,
        );
      },
      onCameraIdle: _handleCameraIdle,
      onMapClick: (_, coord) {
        widget.controller.updateCamera(
          target: latlng.LatLng(coord.latitude, coord.longitude),
        );
      },
    );
  }

  CameraPosition _toCameraPosition(TrufiCameraPosition cam) => CameraPosition(
    target: LatLng(cam.target.latitude, cam.target.longitude),
    zoom: toMapLibreZoom(cam.zoom),
    bearing: toMapLibreBearing(cam.bearing),
  );

  double toMapLibreZoom(double leafletZoom) => leafletZoom - 1.0;
  double toLeafletZoom(double mapLibreZoom) => mapLibreZoom + 1.0;

  double toMapLibreBearing(double leafletBearing) =>
      (360 - leafletBearing) % 360;
  double toLeafletBearing(double mapLibreBearing) =>
      (360 - mapLibreBearing) % 360;
}
