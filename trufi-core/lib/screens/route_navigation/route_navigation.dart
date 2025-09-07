import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:trufi_core/pages/home/widgets/routing_map/routing_map_controller.dart';
import 'package:trufi_core/pages/home/widgets/search_bar/location_search_bar.dart';
import 'package:trufi_core/screens/route_navigation/map_layers/fit_camera_layer.dart';
import 'package:trufi_core/screens/route_navigation/maps/flutter_map.dart';
import 'package:trufi_core/screens/route_navigation/maps/trufi_map_controller.dart';
import 'package:trufi_core/screens/route_navigation/maps/maplibre_gl.dart';
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
  // late final WeatherStationsLayer weatherLayer;
  late final FitCameraLayer fitCameraLayer;
  TrufiMarker? selectedMarker;

  @override
  void initState() {
    super.initState();
    routingMapComponent = RoutingMapComponent(mapController);
    // weatherLayer = WeatherStationsLayer(mapController);
    fitCameraLayer = FitCameraLayer(mapController);
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlanWithLoading() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoadingDialog(message: 'Calculating route...'),
    );

    try {
      await routingMapComponent.fetchPlan(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch route: $e')));
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final logicalSize = Size(constraints.maxWidth, constraints.maxHeight);
          final dpr = MediaQuery.of(context).devicePixelRatio;

          // 👉 Actualiza viewport solo vía el layer (no toques el controller aquí)
          fitCameraLayer.updateViewport(logicalSize, dpr);
          return Stack(
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
                  onMapLongClick: (coord) async {
                    if (routingMapComponent.origin == null) {
                      routingMapComponent.addOrigin(coord);
                    } else if (routingMapComponent.destination == null) {
                      routingMapComponent.addDestination(coord);
                      await _fetchPlanWithLoading();
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
                  onMapLongClick: (coord) async {
                    if (routingMapComponent.origin == null) {
                      routingMapComponent.addOrigin(coord);
                    } else if (routingMapComponent.destination == null) {
                      routingMapComponent.addDestination(coord);
                      await _fetchPlanWithLoading();
                    } else {
                      routingMapComponent.cleanOriginAndDestination();
                    }
                  },
                ),
              const LocationSearchBar(),
              if (selectedMarker?.buildPanel != null)
                TrufiBottomSheet(child: selectedMarker!.buildPanel!(context)),
              // TransitBottomSheet(
              //   routingMapComponent: routingMapComponent,
              //   trufiMapController: mapController,
              // ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () {
                      fitCameraLayer.fitBoundsOnCamera([
                        latlng.LatLng(48.5940, 8.8665),
                        latlng.LatLng(48.5960, 8.8680),
                        // ...más puntos
                      ]);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  final String message;
  const _LoadingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 16),
              Flexible(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }
}
