import 'package:flutter/material.dart';
import 'package:trufi_core/pages/home/widgets/routing_map/routing_map_controller.dart';
import 'package:trufi_core/pages/home/widgets/travel_bottom_sheet/travel_mode_section.dart/transit_mode_section/itinerary_card/itinerary_card.dart';

class TransitModeSection extends StatelessWidget {
  final RoutingMapComponent routingMapComponent;
  const TransitModeSection({super.key, required this.routingMapComponent});

  @override
  Widget build(BuildContext context) {
    final itineraries = routingMapComponent.plan?.itineraries ?? [];
    return Column(
      children: [
        Row(children: []),
        ...itineraries.map((itinerary) {
          return Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            child: ItineraryCard(itinerary:itinerary)
          );
        }),
      ],
    );
  }
}
