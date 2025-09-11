import 'package:flutter/material.dart';
import 'package:trufi_core/pages/home/widgets/routing_map/routing_map_controller.dart';
import 'package:trufi_core/pages/home/widgets/travel_bottom_sheet/travel_mode_section.dart/transit_mode_section/itinerary_card/itinerary_card.dart';

import 'package:latlong2/latlong.dart' as latlng;
class TransitModeSection extends StatelessWidget {
  final RoutingMapComponent routingMapComponent;
  final void Function(bool) onRouteDetailsViewChanged;
  final void Function(List<latlng.LatLng>) onSelectItinerary;
  const TransitModeSection({
    super.key,
    required this.routingMapComponent,
    required this.onRouteDetailsViewChanged,
    required this.onSelectItinerary,
  });

  @override
  Widget build(BuildContext context) {
    final itineraries = routingMapComponent.plan?.itineraries ?? [];
    return Column(
      children: [
        Row(children: []),
        ...itineraries.map((itinerary) {
          return Column(
            children: [
              ItineraryCard(
                itinerary: itinerary,
                onTap: () {
                  routingMapComponent.changeItinerary(itinerary);
                  final points = itinerary.legs
                      .expand((leg) => leg.accumulatedPoints )
                      .toList();
                  onSelectItinerary.call(points);
                  onRouteDetailsViewChanged.call(true);
                },
              ),
              Divider(height: 0),
            ],
          );
        }),
      ],
    );
  }
}
