import 'package:flutter/material.dart';
import 'package:trufi_core/models/plan_entity.dart';

class ItineraryCard extends StatelessWidget {
  final PlanItinerary itinerary;
  const ItineraryCard({super.key, required this.itinerary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "29",
                  style: theme.textTheme.headlineMedium?.copyWith(height: 1),
                ),
                Text("min"),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "1:19 AM (Sun) - 1:48 AM (Sun)",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  ...itinerary.legs.map((leg) {
                    return Text(leg.mode);
                  }),
                ],
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
    );
  }
}
