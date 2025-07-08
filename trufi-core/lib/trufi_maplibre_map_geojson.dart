import 'dart:async';
import 'dart:math';
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
    required this.styleString,
    required this.onMapClick,
  });

  final TrufiMapController controller;
  final String styleString;
  final void Function(Point<double>, LatLng) onMapClick;

  @override
  State<TrufiMapLibreMap> createState() => _TrufiMapLibreMapState();
}

class _TrufiMapLibreMapState extends State<TrufiMapLibreMap> {
  MapLibreMapController? _mapCtl;
  bool _mapReady = false;
  bool _suppressSync = false;

  // Stores the hash of each rendered marker by its ID
  final Map<String, int> _renderedMarkerHashes = <String, int>{};

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

    const sourceId = 'trufi_markers_source';
    const layerId = 'trufi_markers_layer';

    final features = <Map<String, dynamic>>[];

    for (final layer in visibleLayers) {
      for (final marker in layer.entries.where((m) => m.visible)) {
        final markerHash = marker.hashCode;
        final wasRendered = _renderedMarkerHashes.containsKey(marker.id);
        final hashUnchanged =
            wasRendered && _renderedMarkerHashes[marker.id] == markerHash;

        if (hashUnchanged) {
          debugPrint("✔️ Marker '${marker.id}' reused (unchanged).");
          continue;
        }

        _renderedMarkerHashes[marker.id] = markerHash;

        final bytes = await _widgetToBytes(marker);
        final imageId =
            'marker_${marker.id}_${markerHash}'; // usa hash para evitar conflicto

        await ctl.addImage(imageId, bytes); // sobrescribe si ya existe

        features.add({
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [
              marker.position.longitude,
              marker.position.latitude,
            ],
          },
          'properties': {'icon': imageId, 'id': marker.id},
        });
      }
    }

    // eliminar IDs antiguos
    final visibleIds = visibleLayers
        .expand((layer) => layer.entries)
        .where((m) => m.visible)
        .map((m) => m.id)
        .toSet();

    final toRemove = _renderedMarkerHashes.keys.toSet().difference(visibleIds);
    for (final id in toRemove) {
      _renderedMarkerHashes.remove(id);
    }

    final geojson = {'type': 'FeatureCollection', 'features': features};

    try {
      await ctl.setGeoJsonSource(sourceId, geojson);
    } catch (_) {
      // si falla, asumimos que no existe aún y la creamos
      await ctl.addSource(sourceId, GeojsonSourceProperties(data: geojson));

      await ctl.addLayer(
        sourceId,
        layerId,
        const SymbolLayerProperties(
          iconImage: '{icon}',
          iconSize: 1,
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
        ),
      );
    }
  }

  // Removes any existing symbol with the given marker ID
  Future<void> _removeMarkerById(String id) async {
    final ctl = _mapCtl;
    if (ctl == null) return;
    final toRemove =
        ctl.symbols?.where((s) => s.data?["id"] == id).toList() ?? [];
    if (toRemove.isNotEmpty) {
      await ctl.removeSymbols(toRemove);
    }
  }

  Future<Uint8List> _widgetToBytes(TrufiMarker marker) {
    final mediaQuery = MediaQuery.of(context);
    return ImageTool.widgetToPng(
      marker.widget,
      devicePixelRatio: mediaQuery.devicePixelRatio,
      size: marker.size,
    );
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
        await _syncLayers(widget.controller.visibleLayers);
      },
      onCameraIdle: _handleCameraIdle,
      onMapClick: widget.onMapClick,
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
