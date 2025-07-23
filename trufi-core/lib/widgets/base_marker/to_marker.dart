import 'package:flutter/material.dart';

class ToMarker extends StatelessWidget {
  final double height;
  const ToMarker({super.key, this.height = 24});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: Colors.transparent,
      child: FittedBox(
        fit: BoxFit.fitHeight,
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 5),
              width: 7,
              height: 7,
              color: Colors.white,
            ),
            const Icon(Icons.location_on, size: 23, color: Colors.white),
            Icon(Icons.location_on, color: const Color(0xffd81b60), size: 20),
          ],
        ),
      ),
    );
  }
}
