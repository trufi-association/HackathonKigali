import 'package:flutter/material.dart';
import 'package:trufi_core/repositories/location/location_repository.dart';
import 'package:trufi_core/screens/route_navigation/maps/trufi_map_controller.dart';
import 'package:trufi_core/utils/icon_utils/icons.dart';
import 'package:trufi_core/widgets/maps/choose_location/choose_location.dart';

class FullScreenSearchModal extends StatefulWidget {
  static Future<TrufiLocation?> onLocationSelected(BuildContext context) async {
    return await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const FullScreenSearchModal(),
      ),
    );
  }

  const FullScreenSearchModal({super.key});

  @override
  State<FullScreenSearchModal> createState() => _FullScreenSearchModalState();
}

class _FullScreenSearchModalState extends State<FullScreenSearchModal> {
  String query = '';
  final locationRepository = LocationRepository();

  @override
  void initState() {
    super.initState();
    locationRepository.searchResult.addListener(_update);
    locationRepository.myDefaultPlaces.addListener(_update);
    locationRepository.myPlaces.addListener(_update);
    locationRepository.historyPlaces.addListener(_update);
    locationRepository.favoritePlaces.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await locationRepository.initLoad();
    });
  }

  @override
  void dispose() {
    locationRepository.searchResult.removeListener(_update);
    locationRepository.myDefaultPlaces.removeListener(_update);
    locationRepository.myPlaces.removeListener(_update);
    locationRepository.historyPlaces.removeListener(_update);
    locationRepository.favoritePlaces.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  Future<void> _setLocation({required TrufiLocation location}) async {
    await locationRepository.insertHistoryPlace(location);
    if (mounted) Navigator.of(context).pop(location);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = Divider(
      height: 8,
      thickness: 8,
      color: theme.colorScheme.surfaceVariant,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'search-bar',
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => Navigator.of(context).pop(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: theme.colorScheme.onSurface,
                            size: 20,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          autofocus: true,
                          cursorColor: theme.colorScheme.primary,
                          decoration: InputDecoration(
                            hintText: 'Search here',
                            hintStyle: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            border: InputBorder.none,
                          ),
                          textInputAction: TextInputAction.search,
                          onChanged: (text) {
                            final t = text.trim();
                            setState(() => query = t);
                            // IMPORTANTE: ya tienes debounce en el repo
                            locationRepository.fetchLocations(t.toLowerCase());
                          },
                          onSubmitted: (text) {
                            final t = text.trim();
                            setState(() => query = t);
                            locationRepository.fetchLocations(t.toLowerCase());
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.mic),
                        color: theme.colorScheme.onSurface,
                        tooltip: 'Voice search',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Progress controlado por isLoading del repositorio
            ValueListenableBuilder<bool>(
              valueListenable: locationRepository.isLoading,
              builder: (context, loading, _) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: loading
                      ? const LinearProgressIndicator(
                          key: ValueKey('progress'),
                          minHeight: 4,
                        )
                      : const SizedBox(key: ValueKey('noprog'), height: 4),
                );
              },
            ),

            Expanded(
              child: CustomScrollView(
                slivers: [
                  if (query.isEmpty)
                    SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 56,
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              scrollDirection: Axis.horizontal,
                              children: [
                                ...locationRepository.myDefaultPlaces.value.map(
                                  (e) => _QuickActionPill(
                                    icon: typeToIconData(
                                      e.type,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    title: e.description,
                                    subtitle: e.address ?? '',
                                    onTap: () async {
                                      if (e.isLatLngDefined) {
                                        _setLocation(location: e);
                                      } else {
                                        final locationSelected =
                                            await ChooseLocationPage.selectLocation(
                                              context,
                                            );
                                        if (locationSelected != null) {
                                          await locationRepository
                                              .updateMyDefaultPlace(
                                                e,
                                                locationSelected,
                                              );
                                        }
                                      }
                                    },
                                  ),
                                ),
                                ...locationRepository.myPlaces.value.map(
                                  (e) => _QuickActionPill(
                                    icon: typeToIconData(
                                      e.type,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    title: e.description,
                                    subtitle: e.address ?? '',
                                    onTap: () => _setLocation(location: e),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          divider,
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Recent',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  SliverList.list(
                    children: [
                      if (query.isEmpty)
                        ...locationRepository.historyPlaces.value.reversed.map(
                          (location) => PlaceTile2(
                            location: location,
                            onTap: () => _setLocation(location: location),
                          ),
                        ),
                      if (query.isEmpty)
                        ...locationRepository.favoritePlaces.value.reversed.map(
                          (location) => PlaceTile2(
                            location: location,
                            onTap: () => _setLocation(location: location),
                          ),
                        ),
                      if (query.isNotEmpty)
                        ...locationRepository.searchResult.value.map(
                          (location) => PlaceTile2(
                            location: location,
                            onTap: () => _setLocation(location: location),
                          ),
                        ),
                      const _MoreFromHistory(),
                    ],
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

class _QuickActionPill extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconBackgorundColor;

  const _QuickActionPill({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconBackgorundColor = const Color(0xFFD9E5EB),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 160,
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: iconBackgorundColor,
              child: SizedBox(
                width: 18,
                height: 18,
                child: FittedBox(child: icon),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceTile2 extends StatelessWidget {
  final TrufiLocation location;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final Color? leadingColor;

  const PlaceTile2({
    super.key,
    required this.location,
    required this.onTap,
    this.leadingIcon,
    this.leadingColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String title = location.description;
    final String? subtitle = location.address;
    final String? metaPrimary = null;
    final Color? metaPrimaryColor = null;
    final String? metaSecondary = null;

    return Column(
      children: [
        ListTile(
          visualDensity: VisualDensity.compact,
          horizontalTitleGap: 12,
          onTap: onTap,
          minVerticalPadding: (subtitle != null && subtitle.isNotEmpty)
              ? 12
              : 20,
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.surfaceVariant,
            radius: 18,
            child: leadingIcon != null
                ? Icon(
                    leadingIcon,
                    color: leadingColor ?? theme.colorScheme.onSurface,
                    size: 20,
                  )
                : typeToIconData(
                    location.type,
                    color: theme.iconTheme.color ?? theme.colorScheme.onSurface,
                  ),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),
          subtitle: (subtitle != null && subtitle.isNotEmpty)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (metaPrimary != null)
                          Text(
                            metaPrimary,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  metaPrimaryColor ??
                                  theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                          ),
                        if (metaPrimary != null && metaSecondary != null)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('·'),
                          ),
                        if (metaSecondary != null)
                          Text(
                            metaSecondary,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1,
                            ),
                          ),
                      ],
                    ),
                  ],
                )
              : null,
        ),
        Divider(
          height: 0.5,
          thickness: 0.5,
          indent: 60,
          color: theme.dividerColor,
        ),
      ],
    );
  }
}

class _MoreFromHistory extends StatelessWidget {
  const _MoreFromHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'More from recent history',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF008080),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: () {},
    );
  }
}
