import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class FullDynamicMap extends StatefulWidget {
  const FullDynamicMap({super.key});

  @override
  State<FullDynamicMap> createState() => _FullDynamicMapState();
}

class _FullDynamicMapState extends State<FullDynamicMap> {
  MapLibreMapController? mapController;
  Timer? timer;

  final int nLines = 0;
  final int nFeatureMarkers = 10000;

  final Map<String, List<List<double>>> lineData = {};
  final List<List<double>> featureMarkerCoords = [];

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    mapController = controller;
  }

  void _onStyleLoaded() async {
    if (mapController == null) return;
    final rand = Random();

    // 🔴 Inicializar líneas
    for (int i = 0; i < nLines; i++) {
      final lng = -63.18 + rand.nextDouble() * 0.05;
      final lat = -17.78 + rand.nextDouble() * 0.05;

      lineData["line_$i"] = [
        [lng, lat],
        [lng + 0.0005, lat + 0.0005],
        [lng + 0.001, lat],
      ];
    }

    // 🟢 Inicializar feature markers
    for (int i = 0; i < nFeatureMarkers; i++) {
      featureMarkerCoords.add([
        -63.18 + rand.nextDouble() * 0.05,
        -17.78 + rand.nextDouble() * 0.05,
      ]);
    }

    // 🎨 Generar íconos en memoria
    final greenIcon = await generateCircleMarkerImage(color: Colors.green);
    await mapController!.addImage("green-marker", greenIcon);

    final blueIcon = await generateCircleMarkerImage(color: Colors.blue);
    await mapController!.addImage("blue-marker", blueIcon);

    // 📦 Agregar fuentes y capas

    await mapController!.addGeoJsonSource('lines-source', {
      "type": "FeatureCollection",
      "features": [],
    });
    await mapController!.addLineLayer(
      'lines-source',
      'lines-layer',
      LineLayerProperties(lineColor: '#FF0000', lineWidth: 2.0),
    );

    await mapController!.addGeoJsonSource('feature-markers-source', {
      "type": "FeatureCollection",
      "features": [],
    });
    await mapController!.addSymbolLayer(
      'feature-markers-source',
      'feature-markers-layer',
      SymbolLayerProperties(
        iconImage: 'green-marker',
        iconSize: 1.0,
        iconAllowOverlap: true,
      ),
    );

    // ⏱️ Iniciar animación
    timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateAll());
  }

  void _updateAll() async {
    final rand = Random();

    // 🔴 Mover líneas
    for (final entry in lineData.entries) {
      final last = entry.value.last;
      final newPoint = [
        last[0] + 0.0002 * (rand.nextDouble() - 0.5),
        last[1] + 0.0002 * (rand.nextDouble() - 0.5),
      ];
      entry.value.add(newPoint);
      if (entry.value.length > 20) entry.value.removeAt(0);
    }

    // 🟢 Mover feature markers
    for (int i = 0; i < featureMarkerCoords.length; i++) {
      final coord = featureMarkerCoords[i];
      featureMarkerCoords[i] = [
        coord[0] + 0.0002 * (rand.nextDouble() - 0.5),
        coord[1] + 0.0002 * (rand.nextDouble() - 0.5),
      ];
    }

    // Actualizar fuentes
    await mapController!.setGeoJsonSource('lines-source', _buildLinesGeoJson());
    await mapController!.setGeoJsonSource(
      'feature-markers-source',
      _buildFeatureMarkersGeoJson(),
    );
  }

  Map<String, dynamic> _buildLinesGeoJson() {
    final features = lineData.entries.map((entry) {
      return {
        "type": "Feature",
        "geometry": {"type": "LineString", "coordinates": entry.value},
        "properties": {"id": entry.key},
      };
    }).toList();

    return {"type": "FeatureCollection", "features": features};
  }

  Map<String, dynamic> _buildFeatureMarkersGeoJson() {
    final features = featureMarkerCoords.asMap().entries.map((entry) {
      return {
        "type": "Feature",
        "geometry": {"type": "Point", "coordinates": entry.value},
        "properties": {"id": "feature_${entry.key}"},
      };
    }).toList();

    return {"type": "FeatureCollection", "features": features};
  }

  Future<Uint8List> generateCircleMarkerImage({
    int size = 64,
    Color color = Colors.green,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = color;
    canvas.drawCircle(Offset(size / 2.0, size / 2.0), size / 2.5, paint);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Líneas + Marcadores dinámicos')),
      body: MapLibreMap(
        styleString: 'https://demotiles.maplibre.org/style.json',
        onMapCreated: _onMapCreated,
        onStyleLoadedCallback: _onStyleLoaded,
        initialCameraPosition: const CameraPosition(
          target: LatLng(-17.7833, -63.1806),
          zoom: 13,
        ),
      ),
    );
  }
}
