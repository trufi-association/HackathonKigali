import 'package:flutter/material.dart';
import 'package:trufi_core/models/enums/transport_mode.dart';
import 'package:trufi_core/models/plan_entity.dart';
import 'package:trufi_core/widgets/utils.dart';

class ItineraryPath extends StatelessWidget {
  final PlanItinerary itinerary;
  const ItineraryPath({super.key, required this.itinerary});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: itinerary.legs.map((leg) {
        return Row(
          children: [
            Row(children: [LegIcon(leg: leg)]),
          ],
        );
      }).toList(),
    );
  }
}

class LegIcon extends StatelessWidget {
  final PlanItineraryLeg leg;
  const LegIcon({super.key, required this.leg});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        leg.transportMode.getImage(
          color: Theme.of(context).colorScheme.onSurface,
          size: leg.transportMode != TransportMode.walk ? 24 : 20,
        ),
        if (leg.transportMode != TransportMode.walk)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: hexToColor(leg.route?.color),
            ),
            child: Text(
              leg.route?.shortName ?? '',
              style: TextStyle(color: hexToColor(leg.route?.textColor)),
            ),
          ),
      ],
    );
  }
}
