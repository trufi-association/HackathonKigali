import 'package:flutter/material.dart';
import 'package:trufi_core/pages/home/widgets/routing_map/routing_map_controller.dart';
import 'package:trufi_core/pages/home/widgets/travel_bottom_sheet/travel_mode_section.dart/transit_mode_section/itinerary_card/itinerary_card.dart';

class TransitModeSection extends StatelessWidget {
  final RoutingMapComponent routingMapComponent;
  final void Function(bool) onRouteDetailsViewChanged;
  const TransitModeSection({
    super.key,
    required this.routingMapComponent,
    required this.onRouteDetailsViewChanged,
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
