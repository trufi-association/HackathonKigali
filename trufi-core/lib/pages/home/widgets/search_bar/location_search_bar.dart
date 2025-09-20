import 'package:flutter/material.dart';
import 'package:trufi_core/localization/app_localization.dart';
import 'package:trufi_core/pages/home/widgets/search_bar/full_screen_search_modal.dart';
import 'package:trufi_core/pages/home/widgets/search_bar/full_screen_select_location_modal.dart';
import 'package:trufi_core/pages/home/widgets/search_bar/search_bar_utils.dart';
import 'package:trufi_core/pages/saved_places/saved_places.dart';
import 'package:trufi_core/screens/route_navigation/maps/trufi_map_controller.dart';
import 'package:trufi_core/widgets/base_marker/from_marker.dart';
import 'package:trufi_core/widgets/base_marker/to_marker.dart';

class RouteEndpoints {
  final TrufiLocation origin;
  final TrufiLocation destination;

  const RouteEndpoints({required this.origin, required this.destination});
}

class LocationSearchBar extends StatelessWidget {
  final void Function(TrufiLocation) onSaveFrom;
  final void Function() onClearFrom;
  final void Function(TrufiLocation) onSaveTo;
  final void Function() onClearTo;
  final void Function() onFetchPlan;
  final void Function() onReset;
  final void Function() onSwap;
  final TrufiLocation? origin;
  final TrufiLocation? destination;

  const LocationSearchBar({
    super.key,
    required this.onSaveFrom,
    required this.onClearFrom,
    required this.onSaveTo,
    required this.onClearTo,
    required this.onFetchPlan,
    required this.onReset,
    required this.onSwap,
    required this.origin,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: (destination == null)
            ? _SingleSearchComponent(
                onSaveTo: (location) async {
                  final routeEndpoints =
                      await FullScreenSelectLocationModal.showRouteEndpointsPicker(
                        context,
                        onSaveFrom: onSaveFrom,
                        onClearFrom: onClearFrom,
                        onSaveTo: onSaveTo,
                        onClearTo: onClearTo,
                        onFetchPlan: onFetchPlan,
                        onReset: onReset,
                        onSwap: onSwap,
                        origin: origin,
                        destination: location,
                      );
                  if (routeEndpoints != null) {
                    onSaveFrom(routeEndpoints.origin);
                    onSaveTo(routeEndpoints.destination);
                  }
                },
                onClearTo: onClearTo,
              )
            : RouteSearchComponent(
                onSaveFrom: onSaveFrom,
                onClearFrom: onClearFrom,
                onSaveTo: onSaveTo,
                onClearTo: onClearTo,
                onFetchPlan: onFetchPlan,
                onReset: onReset,
                onSwap: onSwap,
                origin: origin,
                destination: destination,
              ),
      ),
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () async {
          final locationSelected =
              await FullScreenSearchModal.onLocationSelected(context);
          if (locationSelected != null) {
            onSaveTo(locationSelected);
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 8),
              child: Icon(Icons.search, color: theme.colorScheme.onSurface),
            ),
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
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(
                            'https://trufi.app/wp-content/uploads/2019/02/48.png',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Trufi Transit',
                          style: theme.textTheme.titleMedium?.copyWith(
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
                leading: Icon(Icons.search, color: theme.colorScheme.onSurface),
                title: Text(
                  'Buscar rutas',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(
                  Icons.bookmark,
                  color: theme.colorScheme.onSurface,
                ),
                title: Text(
                  'Favoritos',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(
                  Icons.history,
                  color: theme.colorScheme.onSurface,
                ),
                title: Text(
                  'Historial',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onTap: () async {
                  await SavedPlacesPage.navigateToSavedPlaces(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.settings,
                  color: theme.colorScheme.onSurface,
                ),
                title: Text(
                  'Configuración',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.info, color: theme.colorScheme.onSurface),
                title: Text(
                  'Acerca de',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
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

class RouteSearchComponent extends StatelessWidget {
  final void Function(TrufiLocation) onSaveFrom;
  final void Function() onClearFrom;
  final void Function(TrufiLocation) onSaveTo;
  final void Function() onClearTo;
  final void Function() onFetchPlan;
  final void Function() onReset;
  final void Function() onSwap;

  final TrufiLocation? origin;
  final TrufiLocation? destination;

  const RouteSearchComponent({
    super.key,
    required this.onSaveFrom,
    required this.onClearFrom,
    required this.onSaveTo,
    required this.onClearTo,
    required this.onFetchPlan,
    required this.onReset,
    required this.onSwap,
    required this.origin,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(14, 0, 0, 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Divider(
                height: 2,
                indent: 28,
                endIndent: 40,
                color: theme.colorScheme.outlineVariant,
              ),
              Positioned(
                child: SearchBarUtils.getDots(
                  theme.colorScheme.onSurfaceVariant,
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
                                  location: origin,
                                );
                            if (locationSelected != null) {
                              onSaveFrom(locationSelected);
                            }
                          },
                          location: origin,
                          hintText: 'Choose start location',
                          icon: Container(
                            width: 24,
                            padding: const EdgeInsets.all(3.5),
                            child: const FromMarker(),
                          ),
                        ),
                        _TextFieldUI(
                          onTap: () async {
                            final locationSelected =
                                await FullScreenSearchModal.onLocationSelected(
                                  context,
                                  location: destination,
                                );
                            if (locationSelected != null) {
                              onSaveTo(locationSelected);
                            }
                          },
                          location: destination,
                          hintText: 'Choose destination location',
                          icon: Container(
                            width: 24,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: const ToMarker(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: IconButton(
                          icon: const Icon(Icons.more_vert),
                          color: theme.colorScheme.onSurface,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          onPressed: onClearTo,
                          tooltip: 'Menú',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: IconButton(
                          icon: const Icon(Icons.swap_vert),
                          color: theme.colorScheme.onSurface,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          onPressed: onSwap,
                          tooltip: 'Swap',
                        ),
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
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            icon,
            const SizedBox(width: 4),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      location?.displayName(AppLocalization.of(context)) ??
                          hintText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: location != null
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (location == null)
                    Icon(
                      Icons.keyboard_arrow_right,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
