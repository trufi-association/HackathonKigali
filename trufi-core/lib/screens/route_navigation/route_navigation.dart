import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:trufi_core/pages/home/widgets/routing_map/routing_map_controller.dart';
import 'package:trufi_core/pages/home/widgets/search_bar/location_search_bar.dart';
import 'package:trufi_core/pages/home/widgets/travel_bottom_sheet/travel_bottom_sheet.dart';
import 'package:trufi_core/screens/route_navigation/maps/flutter_map.dart';
import 'package:trufi_core/screens/route_navigation/maps/trufi_map_controller.dart';
import 'package:trufi_core/screens/route_navigation/maps/maplibre_gl.dart';
import 'package:trufi_core/screens/route_navigation/map_layers/weather/weather_layer.dart';
import 'package:trufi_core/widgets/bottom_sheet/trufi_bottom_sheet.dart';
class RouteNavigationScreen extends StatefulWidget {
  const RouteNavigationScreen({super.key});

  @override
  State<RouteNavigationScreen> createState() => _RouteNavigationScreenState();
}

class _RouteNavigationScreenState extends State<RouteNavigationScreen> {
  bool showMapLibre = false;

  final mapController = TrufiMapController(
    initialCameraPosition: TrufiCameraPosition(
      target: latlng.LatLng(48.5950, 8.8672),
      zoom: 17,
      bearing: 0,
    ),
  );

  late final RoutingMapComponent routingMapComponent;
  late final WeatherLayer weatherLayer;
  TrufiMarker? selectedMarker;

  @override
  void initState() {
    super.initState();
    routingMapComponent = RoutingMapComponent(mapController);
    weatherLayer = WeatherLayer(mapController);
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (!showMapLibre)
            TrufiMapLibreMap(
              controller: mapController,
              styleString: 'https://tiles.openfreemap.org/styles/liberty',
              onMapClick: (mapLatLng) {
                final nearest = mapController.pickNearestMarkerAt(
                  mapLatLng,
                  hitboxPx: 24.0,
                );
                setState(() {
                  selectedMarker = nearest;
                });
              },
              onMapLongClick: (coord) {
                if (routingMapComponent.origin == null) {
                  routingMapComponent.addOrigin(coord, context);
                } else if (routingMapComponent.destination == null) {
                  routingMapComponent.addDestination(coord, context);
                } else {
                  routingMapComponent.cleanOriginAndDestination();
                }
              },
            ),
          if (showMapLibre)
            TrufiFlutterMap(
              controller: mapController,
              tileUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              onMapClick: (mapLatLng) {
                final nearest = mapController.pickNearestMarkerAt(
                  mapLatLng,
                  hitboxPx: 24.0,
                );
                setState(() {
                  selectedMarker = nearest;
                });
              },
              onMapLongClick: (coord) {
                if (routingMapComponent.origin == null) {
                  routingMapComponent.addOrigin(coord, context);
                } else if (routingMapComponent.destination == null) {
                  routingMapComponent.addDestination(coord, context);
                } else {
                  routingMapComponent.cleanOriginAndDestination();
                }
              },
            ),
          const LocationSearchBar(),
          if (selectedMarker?.buildPanel != null)
            TrufiBottomSheet(child: selectedMarker!.buildPanel!(context)),
          TransitBottomSheet(
            routingMapComponent: routingMapComponent,
            trufiMapController: mapController,
          ),
        ],
      ),
    );
  }
}
