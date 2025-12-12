import 'package:go_router/go_router.dart';
import 'package:triggeo/features/map/map_screen.dart';
import 'package:triggeo/features/reminders/reminder_detail_screen.dart';
import 'package:triggeo/features/reminders/reminder_list_screen.dart';
import 'package:triggeo/features/settings/settings_screen.dart';
import 'package:latlong2/latlong.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: '/list',
      builder: (context, state) => const ReminderListScreen(),
    ),
    GoRoute(
      path: '/add',
      builder: (context, state) {
        final latlng = state.extra as LatLng;
        return ReminderDetailScreen(target: latlng);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
