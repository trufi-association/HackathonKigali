import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:trufi_core/trufi_map_controller.dart' as trufi;

class TrufiFlutterMap extends StatefulWidget {
  const TrufiFlutterMap({
    super.key,
    required this.controller,
    required this.tileUrl,
    required this.onMapClick,
  });

  final trufi.TrufiMapController controller;
  final String tileUrl;
  final void Function(latlng.LatLng) onMapClick;

  @override
  State<TrufiFlutterMap> createState() => _TrufiFlutterMapState();
}

class _TrufiFlutterMapState extends State<TrufiFlutterMap> {
  final fm.MapController _mapCtl = fm.MapController();
  bool _mapReady = false;
  bool _suppressSync = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.cameraPositionNotifier.addListener(_cameraListener);
      widget.controller.layersNotifier.addListener(_layersListener);
    });
  }

  @override
  void dispose() {
    widget.controller.cameraPositionNotifier.removeListener(_cameraListener);
    widget.controller.layersNotifier.removeListener(_layersListener);
    super.dispose();
  }

  // Controller → FlutterMap
  void _cameraListener() {
    if (!_mapReady) return;
    final camera = widget.controller.cameraPositionNotifier.value;
    _suppressSync = true;
    _mapCtl.moveAndRotate(camera.target, camera.zoom, camera.bearing);
  }

  void _layersListener() {
    setState(() {});
  }

  // FlutterMap → Controller (incluye visibleRegion convertido)
  void _onPositionChanged(fm.MapCamera pos, bool hasGesture) {
    if (_suppressSync) {
      _suppressSync = false;
      return;
    }

    // visible bounds del viewport (flutter_map)
    final fb = pos.visibleBounds; // puede ser null en los primeros frames
    trufi.LatLngBounds? vr;
    vr = trufi.LatLngBounds(
      fb.southWest, // ya es latlng.LatLng
      fb.northEast,
    );

    widget.controller.updateCamera(
      target: pos.center,
      zoom: pos.zoom,
      bearing: pos.rotation,
      visibleRegion: vr,
    );
  }

  @override
  Widget build(BuildContext context) {
    final camera = widget.controller.cameraPositionNotifier.value;
    final visibleLayers = widget.controller.visibleLayers;

    return fm.FlutterMap(
      mapController: _mapCtl,
      options: fm.MapOptions(
        initialCenter: camera.target,
        initialZoom: camera.zoom,
        initialRotation: camera.bearing,
        backgroundColor: Colors.transparent,
        interactionOptions: const fm.InteractionOptions(
          flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
        ),
        onMapReady: () {
          setState(() => _mapReady = true);
          _mapCtl.moveAndRotate(camera.target, camera.zoom, camera.bearing);
        },
        onPositionChanged: _onPositionChanged,
        onTap: (_, position) => widget.onMapClick(position),
      ),
      children: [
        Opacity(opacity: 1, child: fm.TileLayer(urlTemplate: widget.tileUrl)),

        // Markers de cada TrufiLayer
        for (final layer in visibleLayers)
          fm.MarkerLayer(
            markers: [
              for (final marker in layer.entries.where((e) => e.visible))
                fm.Marker(
                  point: marker.position,
                  width: marker.size.width,
                  height: marker.size.height,
                  rotate: true,
                  alignment: Alignment.center,
                  child: marker.widget,
                ),
            ],
          ),

        // (Opcional) Si quieres líneas también en FlutterMap:
        fm.PolylineLayer(
          polylines: [
            for (final layer in visibleLayers)
              for (final line in layer.lines)
                fm.Polyline(
                  points: line.position,
                  strokeWidth: line.lineWidth.toDouble(),
                  color: line.color,
                ),
          ],
        ),
      ],
    );
  }
}
