import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:trufi_core/trufi_map_controller.dart';

class MovingLineMapComponent extends TrufiLayer {
  static const String layerId = 'moving-line-map-component';
  final Random _random = Random();
  final int nMarkers;
  final int nLines;
  final Duration updateInterval;

  // 📌 Coordenada base: Kigali
  final latlng.LatLng baseCoord = const latlng.LatLng(-1.949516, 30.069619);
final Widget widget=Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ));
  Timer? _timer;
  final List<TrufiMarker> _markers = [];
  final List<TrufiLine> _lines = [];

  MovingLineMapComponent(
    super.controller, {
    this.nMarkers = 100,
    this.nLines = 10,
    this.updateInterval = const Duration(seconds: 1),
  }) : super(id: layerId,layerLevel: 1) {
    _initFeatures();
    _startUpdates();
  }

  /// Inicializa los marcadores y líneas alrededor de baseCoord
  void _initFeatures() {
    const double offsetRange = 0.02; // +- ~2km

    // Marcadores
    for (int i = 0; i < nMarkers; i++) {
      final position = latlng.LatLng(
        baseCoord.latitude + (_random.nextDouble() - 0.5) * offsetRange,
        baseCoord.longitude + (_random.nextDouble() - 0.5) * offsetRange,
      );
      _markers.add(
        TrufiMarker(
          id: "marker_$i",
          position: position,
          widget: widget,
          size: const Size(14, 14),
        ),
      );
    }

    // Líneas
    for (int i = 0; i < nLines; i++) {
      final start = latlng.LatLng(
        baseCoord.latitude + (_random.nextDouble() - 0.5) * offsetRange,
        baseCoord.longitude + (_random.nextDouble() - 0.5) * offsetRange,
      );
      _lines.add(
        TrufiLine(
          id: "line_$i",
          position: List.generate(
            6,
            (j) => latlng.LatLng(
              start.latitude + j * 0.001,
              start.longitude + j * 0.001,
            ),
          ),
          color: Colors.red,
          lineWidth: 3,
        ),
      );
    }
  }

  /// Inicia actualizaciones periódicas
  void _startUpdates() {
    _timer?.cancel();
    _timer = Timer.periodic(updateInterval, (_) => _updateFeatures());
  }

  /// Actualiza marcadores y líneas con movimiento aleatorio
  void _updateFeatures() {
    const double moveRange = 0.001; // +- ~100m

    // Mover marcadores
    for (var i = 0; i < _markers.length; i++) {
      final m = _markers[i];
      _markers[i] = TrufiMarker(
        id: m.id,
        position: latlng.LatLng(
          m.position.latitude + (_random.nextDouble() - 0.5) * moveRange,
          m.position.longitude + (_random.nextDouble() - 0.5) * moveRange,
        ),
        widget: m.widget,
        size: m.size,
      );
    }

    // Mover líneas
    for (var line in List.of(_lines)) {
      final last = line.position.last;
      final newPoint = latlng.LatLng(
        last.latitude + (_random.nextDouble() - 0.5) * moveRange,
        last.longitude + (_random.nextDouble() - 0.5) * moveRange,
      );

      final updatedPoints = [...line.position, newPoint];
      if (updatedPoints.length > 20) updatedPoints.removeAt(0);

      _lines[_lines.indexOf(line)] = TrufiLine(
        id: line.id,
        position: updatedPoints,
        color: line.color,
        lineWidth: line.lineWidth,
      );
    }

    mutateLayers();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  List<TrufiMarker> get entries => _markers;

  @override
  List<TrufiLine> get lines => _lines;
}
