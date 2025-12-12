import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:triggeo/core/constants/global_config.dart';
import 'package:triggeo/core/services/service_locator.dart';
import 'package:triggeo/data/repositories/settings_repository.dart';
import 'package:triggeo/features/map/widgets/offline_tile_provider.dart';
import 'package:triggeo/features/map/widgets/reminder_edit_dialog.dart';
import 'package:triggeo/l10n/app_localizations.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _hasAutoCentered = false;

  LatLng? _currentLatLng;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocation();
    });
  }

  Future<void> _initLocation() async {
    final locationService = ref.read(locationServiceProvider);

    await locationService.startService();

    final initialPos = await locationService.getCurrentPosition(context);

    if (initialPos != null && mounted) {
      final latLng = LatLng(initialPos['lat'], initialPos['lng']);
      _updateLocation(latLng, isInitial: true);
    }
  }

  void _updateLocation(LatLng latLng, {bool isInitial = false}) {
    setState(() {
      _currentLatLng = latLng;
      if (!_hasAutoCentered) {
        _hasAutoCentered = true;
        _mapController.move(latLng, 15.0);
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&accept-language=zh-CN');
    try {
      final response =
          await http.get(url, headers: {'User-Agent': 'TriggeoApp/1.0'});
      if (response.statusCode == 200) {
        setState(() {
          _searchResults = json.decode(response.body);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                AppLocalizations.of(context)!.mapSearchFailed(e.toString()))));
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _moveToLocation(double lat, double lon) {
    _mapController.move(LatLng(lat, lon), 15.0);
    setState(() {
      _searchResults = [];
      _searchController.clear();
      FocusScope.of(context).unfocus();
    });
  }

  Future<void> _centerToCurrentLocation() async {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.mapLocating)));
    try {
      final locationService = ref.read(locationServiceProvider);
      final pos = await locationService.getCurrentPosition(context);
      if (pos != null && mounted) {
        final latLng = LatLng(pos['lat'], pos['lng']);
        _updateLocation(latLng);
        _mapController.move(latLng, 15.0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!
                .mapLocationFailed(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileUrl = ref.watch(tileUrlProvider);

    ref.listen(currentLocationProvider, (previous, next) {
      if (next.value != null) {
        final newLoc = LatLng(next.value!['lat'], next.value!['lng']);
        if (_currentLatLng == null ||
            newLoc.latitude != _currentLatLng!.latitude ||
            newLoc.longitude != _currentLatLng!.longitude) {
          _updateLocation(newLoc);
        }
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(39.9042, 116.4074),
              initialZoom: 15.0,
              onLongPress: (_, latlng) {
                showDialog(
                  context: context,
                  builder: (context) => ReminderEditDialog(position: latlng),
                );
              },
              onTap: (_, __) {
                if (_searchResults.isNotEmpty) {
                  setState(() => _searchResults = []);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.anchialc.triggeo',
                tileProvider:
                    OfflineTileProvider(offlineMapsDir: globalOfflineMapsDir),
              ),
              MarkerLayer(
                markers: [
                  if (_currentLatLng != null)
                    Marker(
                      point: _currentLatLng!,
                      width: 40,
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                          const Icon(
                            Icons.navigation,
                            color: Colors.blueAccent,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Search Bar Layer
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Theme.of(context).colorScheme.surface,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText:
                                AppLocalizations.of(context)!.mapSearchHint,
                            prefixIcon: Icon(Icons.search,
                                color: Theme.of(context).colorScheme.onSurface),
                            suffixIcon: _isSearching
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: CircularProgressIndicator(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            strokeWidth: 2)))
                                : IconButton(
                                    icon: Icon(Icons.clear,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchResults = []);
                                    },
                                  ),
                            errorText: _searchController.text.isEmpty &&
                                    _searchResults.isNotEmpty &&
                                    !_isSearching
                                ? AppLocalizations.of(context)!
                                    .mapSearchEmptyError
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                          ),
                          onSubmitted: _searchPlaces,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.settings,
                          color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () => context.push('/settings'),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4)
                      ],
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final place = _searchResults[index];
                        if (place.isEmpty) {
                      return Center(
                        child: Text(AppLocalizations.of(context)!.mapNoSearchResults), 
                      );
                    }
                        return ListTile(
                          title: Text(place['display_name'].split(',')[0],
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface)),
                          subtitle: Text(place['display_name'],
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          leading: Icon(Icons.location_city,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurface),
                          onTap: () {
                            final lat = double.parse(place['lat']);
                            final lon = double.parse(place['lon']);
                            _moveToLocation(lat, lon);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // My Location
          FloatingActionButton.small(
            heroTag: 'location_fab',
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            onPressed: _centerToCurrentLocation,
            child: Icon(
              Icons.my_location,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          // Reminder List
          FloatingActionButton.small(
            heroTag: 'list_fab',
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            onPressed: () => context.push('/list'),
            child:
                Icon(Icons.list, color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
