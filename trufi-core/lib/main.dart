import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:trufi_core/map.dart';
import 'package:trufi_core/map_controller.dart';
import 'package:trufi_core/map_stage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Custom Draggable Sheet',
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TrufiMapController mapController = TrufiMapController(
    initialCamera: TrufiCameraPosition(
      position: latlng.LatLng(-1.949516, 30.069619),
      zoom: 10,
    ),
  );
  final TrufiMapStateController stateController = TrufiMapStateController(
    initialMarkers: [
      Marker(
        width: 40,
        height: 40,
        point: latlng.LatLng(-1.949516, 30.069619),
        child: const Icon(Icons.location_on, color: Colors.red),
      ),
      Marker(
        width: 40,
        height: 40,
        point: latlng.LatLng(-1.948000, 30.065000),
        child: const Icon(Icons.location_on, color: Colors.green),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          TrufiMap(
            mapController: mapController,
            stateController: stateController,
          ),
          SafeArea(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
              ),
              height: 48,
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Search here',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      // Aquí es donde abrirás el Drawer, Modal, etc.
                      _showMenuOptions(context);
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.blueAccent,
              onPressed: _addRandomMarker,
              child: const Icon(Icons.add_location),
            ),
          ),

          SafeArea(
            bottom: false,
            child: DraggableScrollableSheet(
              initialChildSize: 0.15,
              minChildSize: 0.15,
              maxChildSize: 1,
              builder: (context, scrollController) {
                return Container(
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
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.all(0),
                          children: [
                            Column(
                              children: [
                                ...List.generate(
                                  50,
                                  (index) => Padding(
                                    padding: EdgeInsetsGeometry.all(2),
                                    child: _buildRouteOption(
                                      "50",
                                      "Avenida Carlos Medinaceli y Avenida Jaime Mendoza",
                                      "8 min",
                                      "2.0 km",
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 1),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addRandomMarker() {
    final center = mapController.initialCamera.position;
    final random = Random();

    // Genera un pequeño desplazamiento aleatorio
    final dx = (random.nextDouble() - 0.5) * 0.1;
    final dy = (random.nextDouble() - 0.5) * 0.1;

    final newLat = center.latitude + dx;
    final newLng = center.longitude + dy;

    final newMarker = Marker(
      width: 40,
      height: 40,
      point: latlng.LatLng(newLat, newLng),
      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
    );

    stateController.addMarker(newMarker);
  }

  void _showMenuOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fondo de cabecera con imagen
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Image.network(
                      'https://www.trufi-association.org/wp-content/uploads/2021/11/Delhi-autorickshaw-CC-BY-NC-ND-ai_enlarged-tweaked-1800x1200px.jpg',
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ),
                  Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(
                            'https://trufi.app/wp-content/uploads/2019/02/48.png',
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Trufi Transit',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Menú de opciones
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Buscar rutas'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark),
                title: const Text('Favoritos'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Historial'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configuración'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Acerca de'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

Widget _buildRouteOption(
  String routeNumber,
  String stop,
  String duration,
  String distance,
) {
  return Container(
    // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.grey.shade900,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "30 min",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              "03:41 - 04:10",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _stepIcon(Icons.directions_walk, "6"),
            _arrowIcon(),
            _busChip("150A"),
            _busChip("150B"),
            _arrowIcon(),
            _stepIcon(Icons.directions_walk, "4"),
            _arrowIcon(),
            _busChip("24", color: Colors.green),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "03:46 from 941 Santa Fe Av.",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    ),
  );
}

Widget _stepIcon(IconData icon, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.grey.shade800,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.white)),
      ],
    ),
  );
}

Widget _busChip(String route, {Color color = const Color(0xFF00796B)}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      route,
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}

Widget _arrowIcon() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Icon(Icons.chevron_right, color: Colors.white70, size: 20),
  );
}
