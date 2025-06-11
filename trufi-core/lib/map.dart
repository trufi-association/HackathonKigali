import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart' as latlng;
import 'package:maplibre_gl/maplibre_gl.dart' as maplibre;
import 'package:trufi_core/map_controller.dart';
import 'package:trufi_core/map_stage.dart';

class TrufiMap extends StatefulWidget {
  const TrufiMap({
    super.key,
    required this.mapController,
    required this.stateController,
  });
  final TrufiMapController mapController;
  final TrufiMapStateController stateController;
  @override
  State<TrufiMap> createState() => _TrufiMapState();
}

class _TrufiMapState extends State<TrufiMap> {
  final MapController mapController = MapController();
  MapLibreMapController? mapLibreController;
  late TrufiCameraPosition initialCamera;
  late StreamSubscription<TrufiCameraPosition> cameraPositionSubscription;
  late VoidCallback stateListener = () => setState(() {});
  @override
  void initState() {
    super.initState();
    initialCamera = widget.mapController.initialCamera;
    cameraPositionSubscription = widget.mapController.cameraPositionStream
        .listen((camera) {
          mapController.moveAndRotate(
            camera.position,
            camera.zoom,
            camera.bearing,
          );
        });
    widget.stateController.addListener(stateListener);
  }

  @override
  void dispose() {
    cameraPositionSubscription.cancel();

    widget.stateController.removeListener(stateListener);
    super.dispose();
  }

  void _syncMapLibreWithFlutterMap(
    latlng.LatLng center,
    double zoom,
    double bearing,
  ) async {
    double normalizedBearing = (360 - bearing) % 360;
    final start = DateTime.now();
    await mapLibreController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(center.latitude, center.longitude),
          zoom: zoom,
          bearing: normalizedBearing,
        ),
      ),
    );

    final end = DateTime.now();
    print('moveCamera took ${end.difference(start).inMilliseconds} ms');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapLibreMap(
          onMapCreated: (controller) {
            mapLibreController = controller;
          },
          styleString:
              'https://tileserver.kigali.trufi.dev/styles/test-style/style.json',
          initialCameraPosition: CameraPosition(
            target: maplibre.LatLng(
              initialCamera.position.latitude,
              initialCamera.position.longitude,
            ),
            zoom: initialCamera.zoom,
            bearing: initialCamera.bearing,
          ),
          gestureRecognizers: {},
          compassEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
        ),
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            backgroundColor: Colors.transparent,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            initialCenter: initialCamera.position,
            initialZoom: initialCamera.zoom,
            initialRotation: initialCamera.bearing,
            onPositionChanged: (MapCamera position, hasGesture) {
              if (hasGesture) {
                _syncMapLibreWithFlutterMap(
                  position.center,
                  position.zoom - 1,
                  position.rotation,
                );
              }
            },
            onMapEvent: (event) {
              if (event is MapEventMove) {
                _syncMapLibreWithFlutterMap(
                  event.camera.center,
                  event.camera.zoom - 1,
                  event.camera.rotation,
                );
              }
            },
          ),
          children: [MarkerLayer(markers: widget.stateController.markers)],
        ),
      ],
    );
  }
}
