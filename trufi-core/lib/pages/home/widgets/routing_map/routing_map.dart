import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:trufi_core/pages/home/widgets/routing_map/routing_map_controller.dart';
import 'package:trufi_core/trufi_map_controller.dart';
import 'package:trufi_core/trufi_maplibre_map_geojson.dart';

class RoutingMapLibre extends StatelessWidget {
  const RoutingMapLibre({
    super.key,
    required this.controller,
    required this.routingMapComponent,
    this.onMapClick,
  });
  final TrufiMapController controller;
  final RoutingMapComponent routingMapComponent;
  final OnMapClickCallback? onMapClick;

  @override
  Widget build(BuildContext context) {
    return TrufiMapLibreMap(
      controller: controller,
      trufiLayer: routingMapComponent,
      onMapClick: onMapClick,
      styleString:
          'https://tileserver.kigali.trufi.dev/styles/test-style/style.json',
    );
  }
}
