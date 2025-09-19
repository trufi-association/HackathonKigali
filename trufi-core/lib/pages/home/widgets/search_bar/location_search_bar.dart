import 'package:flutter/material.dart';
import 'package:trufi_core/localization/app_localization.dart';
import 'package:trufi_core/pages/home/widgets/routing_map/routing_map_controller.dart';
import 'package:trufi_core/pages/home/widgets/search_bar/full_screen_search_modal.dart';
import 'package:trufi_core/screens/route_navigation/maps/trufi_map_controller.dart';
import 'package:trufi_core/widgets/base_marker/from_marker.dart';
import 'package:trufi_core/widgets/base_marker/to_marker.dart';

class LocationSearchBar extends StatelessWidget {
  final IRoutingMapComponent routingMapComponent;
  final void Function(TrufiLocation) onSaveFrom;
  final void Function() onClearFrom;
  final void Function(TrufiLocation) onSaveTo;
  final void Function() onClearTo;
  final void Function() onFetchPlan;
  final void Function() onReset;
  final void Function() onSwap;

  const LocationSearchBar({
    super.key,
    required this.routingMapComponent,
    required this.onSaveFrom,
    required this.onClearFrom,
    required this.onSaveTo,
    required this.onClearTo,
    required this.onFetchPlan,
    required this.onReset,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: routingMapComponent.controller.layersNotifier,
      builder: (context, layers, child) {
        return SafeArea(
          child: Material(
            color: Colors.transparent,
            child: (routingMapComponent.destination == null)
                ? _SingleSearchComponent(
                    onSaveTo: onSaveTo,
                    onClearTo: onClearTo,
                  )
                : _RouteSearchComponent(
                    routingMapComponent: routingMapComponent,
                    onSaveFrom: onSaveFrom,
                    onClearFrom: onClearFrom,
                    onSaveTo: onSaveTo,
                    onClearTo: onClearTo,
                    onFetchPlan: onFetchPlan,
                    onReset: onReset,
                    onSwap: onSwap,
                  ),
          ),
        );
      },
    );
  }
}

class _SingleSearchComponent extends StatelessWidget {
  final void Function(TrufiLocation) onSaveTo;
  final void Function() onClearTo;
  const _SingleSearchComponent({
    required this.onSaveTo,
    required this.onClearTo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        final locationSelected = await FullScreenSearchModal.onLocationSelected(
          context,
        );
        if (locationSelected != null) {
          onSaveTo(locationSelected);
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Hero(
        tag: 'search-bar',
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(80),
                spreadRadius: 0,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: theme.colorScheme.onSurface),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Search here',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.menu),
                color: theme.colorScheme.onSurface,
                onPressed: () => _showMenuOptions(context),
                tooltip: 'Menú',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenuOptions(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: theme.colorScheme.surface,
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
                      color: Colors.black.withOpacity(0.35),
                    ),
                  ),
                  Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(
                            'https://trufi.app/wp-content/uploads/2019/02/48.png',
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
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

class _RouteSearchComponent extends StatelessWidget {
  final IRoutingMapComponent routingMapComponent;
  final void Function(TrufiLocation) onSaveFrom;
  final void Function() onClearFrom;
  final void Function(TrufiLocation) onSaveTo;
  final void Function() onClearTo;
  final void Function() onFetchPlan;
  final void Function() onReset;
  final void Function() onSwap;
  const _RouteSearchComponent({
    required this.routingMapComponent,
    required this.onSaveFrom,
    required this.onClearFrom,
    required this.onSaveTo,
    required this.onClearTo,
    required this.onFetchPlan,
    required this.onReset,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dot = Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Container(
        width: 2.5,
        height: 2.5,
        decoration: BoxDecoration(
          color: theme.disabledColor,
          shape: BoxShape.circle,
        ),
      ),
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Divider(height: 2, indent: 32, endIndent: 40),
              Positioned(
                child: SizedBox(
                  width: 24,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [dot, dot, dot],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _TextFieldUI(
                          onTap: () async {
                            final locationSelected =
                                await FullScreenSearchModal.onLocationSelected(
                                  context,
                                  location: routingMapComponent.origin,
                                );
                            if (locationSelected != null) {
                              onSaveFrom(locationSelected);
                            }
                          },
                          location: routingMapComponent.origin,
                          hintText: 'Origin',
                          icon: Container(
                            width: 24,
                            padding: EdgeInsets.all(3.5),
                            child: FromMarker(),
                          ),
                        ),
                        _TextFieldUI(
                          onTap: () async {
                            final locationSelected =
                                await FullScreenSearchModal.onLocationSelected(
                                  context,
                                  location: routingMapComponent.destination,
                                );
                            if (locationSelected != null) {
                              onSaveTo(locationSelected);
                            }
                          },
                          location: routingMapComponent.destination,
                          hintText: 'Where to?',
                          icon: Container(
                            width: 24,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: ToMarker(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        color: theme.colorScheme.onSurface,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () {},
                        tooltip: 'Menú',
                      ),
                      IconButton(
                        icon: const Icon(Icons.swap_vert),
                        color: theme.colorScheme.onSurface,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: onSwap,
                        tooltip: 'Swap',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TextFieldUI extends StatelessWidget {
  final TrufiLocation? location;
  final String hintText;
  final VoidCallback onTap;
  final Container icon;
  const _TextFieldUI({
    this.location,
    required this.onTap,
    required this.icon,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            icon,
            SizedBox(width: 8),
            Expanded(
              child: Container(
                alignment: Alignment.centerLeft,
                child: location != null
                    ? Text(
                        location!.displayName(AppLocalization.of(context)),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : Text(
                        hintText,
                        style: const TextStyle(color: Colors.black54),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
