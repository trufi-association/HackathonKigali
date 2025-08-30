import 'package:flutter/material.dart';
import 'package:trufi_core/pages/home/widgets/search_bar/full_screen_search_modal.dart';
// import 'package:trufi_core/pages/home/widgets/search_bar/full_screen_search_modal_gpt-5.dart';
// import 'package:trufi_core/pages/home/widgets/search_bar/full_screen_search_modal_gpt-5-thin.dart';

class LocationSearchBar extends StatelessWidget {
  const LocationSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (_, __, ___) => const FullScreenSearchModal(),
          ),
        ),
        child: Hero(
          tag: 'search-bar',
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(120),
                    spreadRadius: 0.2,
                    blurRadius: 2,
                    offset: Offset(0, 0),
                  ),
                ],
                borderRadius: BorderRadius.circular(24),
              ),
              height: 48,
              child: Row(
                children: [
                  const Icon(Icons.search),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search here',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => _showMenuOptions(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
                        const CircleAvatar(
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
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Buscar rutas'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.bookmark),
                title: const Text('Favoritos'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Historial'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configuración'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Acerca de'),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
