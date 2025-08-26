import 'package:flutter/material.dart';
import 'package:trufi_core/models/plan_entity.dart';
import 'package:trufi_core/pages/home/widgets/travel_bottom_sheet/travel_mode_section.dart/transit_mode_section/itinerary_card/itinerary_path.dart';

class ItineraryCard extends StatelessWidget {
  final PlanItinerary itinerary;
  const ItineraryCard({super.key, required this.itinerary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ItineraryPath(itinerary: itinerary),
                Text(
                  "1:19 AM (Sun) - 1:48 AM (Sun)",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "In 4 min ",
                        style: TextStyle(color: Colors.green[700]),
                      ),
                      TextSpan(text: "from Cine center"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        Divider(),
      ],
    );
  }
}
