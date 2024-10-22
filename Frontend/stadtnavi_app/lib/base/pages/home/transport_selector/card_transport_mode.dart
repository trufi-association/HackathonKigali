import 'package:flutter/material.dart';

class CardTransportMode extends StatelessWidget {
  final Widget icon;
  final Widget? secondaryIcon;
  final String title;
  final String subtitle;
  final void Function() onTap;

  const CardTransportMode({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.secondaryIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Row(
            children: [
              SizedBox(
                height: 27,
                width: 27,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (secondaryIcon != null)
                      Positioned(
                        right: -1,
                        top: -2,
                        child: secondaryIcon!,
                      ),
                    Positioned.fill(child: icon),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme. bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme. bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w300),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
