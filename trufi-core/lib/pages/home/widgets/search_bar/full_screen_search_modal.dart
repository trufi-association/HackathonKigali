import 'package:flutter/material.dart';
import 'package:trufi_core/repositories/location/location_repository.dart';
import 'package:trufi_core/screens/route_navigation/maps/trufi_map_controller.dart';
import 'package:trufi_core/utils/icon_utils/icons.dart';

class FullScreenSearchModal extends StatefulWidget {
  const FullScreenSearchModal({super.key});

  @override
  State<FullScreenSearchModal> createState() => _FullScreenSearchModalState();
}

class _FullScreenSearchModalState extends State<FullScreenSearchModal> {
  String query = '';
  final locationRepository = LocationRepository();

  @override
  void initState() {
    locationRepository.searchResult.addListener(update);
    locationRepository.myDefaultPlaces.addListener(update);
    WidgetsBinding.instance.addPostFrameCallback((duration) async {
      await locationRepository.initLoad();
    });
    super.initState();
  }

  @override
  void dispose() {
    locationRepository.searchResult.removeListener(update);
    locationRepository.myDefaultPlaces.removeListener(update);
    super.dispose();
  }

  void update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final divider = Divider(height: 8, thickness: 8, color: Colors.grey[200]);
    return Scaffold(
      backgroundColor: Colors.white,
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
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(32),
                  ),
                  height: 48,
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search here',
                            border: InputBorder.none,
                          ),
                          textInputAction: TextInputAction.search,
                          onChanged: (text) {
                            locationRepository.fetchLocations(
                              text.trim().toLowerCase(),
                            );
                            setState(() {
                              query = text;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.mic, color: Colors.black87),
                        tooltip: 'Voice search',
                      ),
                    ],
                  ),
                ),
              ),
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
                                  (e) {
                                    return _QuickActionPill(
                                      icon: typeToIconData(e.type),
                                      title: e.description,
                                      subtitle: e.address ?? '',
                                    );
                                  },
                                ),
                                ...locationRepository.myPlaces.value.map((e) {
                                  return _QuickActionPill(
                                    icon: typeToIconData(e.type),
                                    title: e.description,
                                    subtitle: e.address ?? '',
                                  );
                                }),
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
                                  style: Theme.of(context).textTheme.titleSmall!
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                                Icon(Icons.info_outline, size: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  SliverList.list(
                    children: [
                      if (query.isEmpty)
                        ...locationRepository.historyPlaces.value.reversed.map((
                          location,
                        ) {
                          return PlaceTile2(location: location);
                        }),
                      if (query.isEmpty)
                        ...locationRepository.favoritePlaces.value.reversed.map(
                          (location) {
                            return PlaceTile2(location: location);
                          },
                        ),

                      if (query.isNotEmpty)
                        ...locationRepository.searchResult.value.map((
                          location,
                        ) {
                          return PlaceTile2(location: location);
                        }),
                      _MoreFromHistory(),
                      divider,
                      _ContactsCard(),
                      SizedBox(height: 24),
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

/// ---------- UI pieces ----------

class _QuickActionPill extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBackgorundColor;

  const _QuickActionPill({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor = Colors.black,
    this.iconBackgorundColor = const Color(0xFFD9E5EB),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: SizedBox(
        width: 140,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
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
  final IconData? leadingIcon;
  final Color? leadingColor;

  const PlaceTile2({
    super.key,
    required this.location,
    this.leadingIcon,
    this.leadingColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = location.description;
    final subtitle = location.address;
    final metaPrimary = null;
    final metaPrimaryColor = null;
    final metaSecondary = null;
    return Column(
      children: [
        ListTile(
          dense: false,
          visualDensity: VisualDensity.compact,
          horizontalTitleGap: 12,
          minVerticalPadding: (subtitle != null && subtitle.isNotEmpty)
              ? 12
              : (subtitle != null && subtitle.isNotEmpty)
              ? 8
              : 20,
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: (subtitle != null && subtitle.isNotEmpty) ? 0 : 6,
              ),
              CircleAvatar(
                backgroundColor: Colors.grey[200],
                radius: 18,
                child: leadingIcon != null
                    ? Icon(leadingIcon, color: leadingColor, size: 20)
                    : typeToIconData(
                        location.type,
                        color: theme.iconTheme.color,
                      ),
              ),
            ],
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),
          subtitle: subtitle != null && subtitle.isNotEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: Colors.black54,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (metaPrimary != null)
                          Text(
                            metaPrimary!,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: metaPrimaryColor ?? Colors.black87,
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                          ),
                        if (metaPrimary != null && metaSecondary != null)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '·',
                              style: TextStyle(
                                color: Colors.black45,
                                height: 1,
                              ),
                            ),
                          ),
                        if (metaSecondary != null)
                          Text(
                            metaSecondary!,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: Colors.black54,
                              height: 1,
                            ),
                          ),
                      ],
                    ),
                  ],
                )
              : null,
          onTap: () {},
        ),
        Divider(height: 0.5, thickness: 0.5, indent: 60),
      ],
    );
  }
}

class _MoreFromHistory extends StatelessWidget {
  const _MoreFromHistory();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      title: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'More from recent history',
          style: textTheme.bodyMedium?.copyWith(
            color: Color(0xFF008080),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: () {},
    );
  }
}

class _ContactsCard extends StatelessWidget {
  const _ContactsCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      // margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 40,
            child: Icon(
              Icons.contacts_outlined,
              size: 28,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Searching for a friend?',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add your phone contacts so you can search for their addresses on Maps.',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add contacts',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Color(0xFF008080),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
