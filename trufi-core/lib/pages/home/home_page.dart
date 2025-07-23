import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:trufi_core/pages/home/widgets/routing_map/routing_map.dart';
import 'package:trufi_core/pages/home/widgets/routing_map/routing_map_controller.dart';
import 'package:trufi_core/trufi_map_controller.dart';
import 'package:latlong2/latlong.dart' as latlng;

class HomePage extends StatefulWidget {
  static const String route = "/Home";
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final mapController = TrufiMapController(
    initialCameraPosition: TrufiCameraPosition(
      target: latlng.LatLng(-1.949516, 30.069619),
      zoom: 14,
      bearing: 0,
    ),
  );
  late RoutingMapComponent routingMapComponent;
  @override
  void initState() {
    routingMapComponent = RoutingMapComponent(mapController);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RoutingMapLibre(
            controller: mapController,
            routingMapComponent: routingMapComponent,
            onMapClick: (point, coordinates) {
              log("onMapClick");
              if (routingMapComponent.origin == null) {
                routingMapComponent.addOrigin(
                  TrufiLocation(
                    description: "Origin",
                    position: latlng.LatLng(
                      coordinates.latitude,
                      coordinates.longitude,
                    ),
                  ),
                );
              } else if (routingMapComponent.destination == null) {
                routingMapComponent.addDestination(
                  TrufiLocation(
                    description: "Destination",
                    position: latlng.LatLng(
                      coordinates.latitude,
                      coordinates.longitude,
                    ),
                  ),
                );
              } else {
                routingMapComponent.cleanOriginAndDestination();
              }
            },
          ),
          SafeArea(
            bottom: false,
            child: DraggableScrollableSheet(
              initialChildSize: 0.15,
              minChildSize: 0.15,
              maxChildSize: 1,
              builder: (context, scrollController) => Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(top: 8, bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        routingMapComponent.selectNextItinerary();
                      },
                      child: Text("Next itinerary"),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: 50,
                        padding: EdgeInsets.zero,
                        itemBuilder: (_, i) =>
                            Padding(padding: const EdgeInsets.all(2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
