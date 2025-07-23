import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:trufi_core/image_tool.dart';
import 'package:trufi_core/models/enums/custom_icons.dart';
import 'package:trufi_core/trufi_map_controller.dart';

class TrufiMapLibreMap extends StatefulWidget {
  const TrufiMapLibreMap({
    super.key,
    required this.controller,
    required this.trufiLayer,
    required this.styleString,
    required this.onMapClick,
  });

  final TrufiMapController controller;
  final TrufiLayer trufiLayer;
  final String styleString;
  final OnMapClickCallback? onMapClick;

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
    print("Paint-----");
    final ctl = _mapCtl;
    if (ctl == null) return;

    for (final layer in visibleLayers) {
      final sourceId = layer.id;
      final layerId = 'layer_$sourceId';

      final features = <Map<String, dynamic>>[];
      final lineFeatures = <Map<String, dynamic>>[];

      for (final marker in layer.entries.where((m) => m.visible)) {
        final markerHash = marker.hashCode;
        final wasRendered = _renderedMarkerHashes.containsKey(marker.id);
        final hashUnchanged =
            wasRendered && _renderedMarkerHashes[marker.id] == markerHash;

        final imageId = 'marker_${marker.id}_$markerHash';

        if (!hashUnchanged) {
          _renderedMarkerHashes[marker.id] = markerHash;
          final bytes = await _widgetToBytes(marker);
          await ctl.addImage(imageId, bytes);
        }

        features.add({
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [
              marker.position.longitude,
              marker.position.latitude,
            ],
          },
          'properties': {
            'icon': imageId,
            'id': marker.id,
            if (marker.alignment == 'top')
              'offset': [0.0, -marker.size.height / 2],
            'layerLevel': marker.layerLevel,
          },
        });
      }

      for (final line in layer.lines.where((l) => l.visible)) {
        final coordinates = line.position
            .map((e) => [e.longitude, e.latitude])
            .toList();

        lineFeatures.add({
          'type': 'Feature',
          'geometry': {'type': 'LineString', 'coordinates': coordinates},
          'properties': {
            'id': line.id,
            'color': decodeFillColor(line.color),
            'width': line.lineWidth,
            'layerLevel': line.layerLevel,
            'dotted': line.activeDots,
          },
        });
      }

      final geojson = {
        'type': 'FeatureCollection',
        'features': [...features, ...lineFeatures],
      };

      final existingSources = await ctl.getSourceIds();
      final sourceExists = existingSources.contains(sourceId);
      if (!sourceExists) {
        await ctl.addGeoJsonSource(sourceId, geojson);

        await ctl.addLineLayer(
          sourceId,
          'line_${layerId}_round',
          LineLayerProperties(
            lineColor: ['get', 'color'],
            lineWidth: ['get', 'width'],
            lineSortKey: ['get', 'layerLevel'],
            lineDasharray: [0.5, 1.5],
            lineJoin: 'round',
            lineCap: 'round',
          ),
          filter: [
            '==',
            ['get', 'dotted'],
            true,
          ],
        );
        await ctl.addLineLayer(
          sourceId,
          'line_$layerId',
          LineLayerProperties(
            lineColor: ['get', 'color'],
            lineWidth: ['get', 'width'],
            lineSortKey: ['get', 'layerLevel'],
            lineJoin: 'round',
            lineCap: 'round',
          ),
          filter: [
            '==',
            ['get', 'dotted'],
            false,
          ],
          enableInteraction: false,
        );
        await ctl.addSymbolLayer(
          sourceId,
          layerId,
          SymbolLayerProperties(
            iconImage: ['get', 'icon'],
            iconSize: 1.0,
            iconAllowOverlap: true,
            iconOffset: ['get', 'offset'],
            symbolSortKey: ['get', 'layerLevel'],
          ),
          enableInteraction: false,
        );
      } else {
        await ctl.setGeoJsonSource(sourceId, geojson);
      }
    }

    // Limpieza de marcadores eliminados
    final currentIds = visibleLayers
        .expand((layer) => layer.entries)
        .where((m) => m.visible)
        .map((m) => m.id)
        .toSet();
    final toRemove = _renderedMarkerHashes.keys.toSet().difference(currentIds);
    for (final id in toRemove) {
      _renderedMarkerHashes.remove(id);
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
      onMapClick: (points, latlng) {
        print("main onMapClick");
        widget.onMapClick?.call(points, latlng);
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
