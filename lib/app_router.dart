import 'package:go_router/go_router.dart';
import 'package:triggeo/core/services/overlay_service.dart';
import 'package:triggeo/features/map/map_screen.dart';
import 'package:triggeo/features/reminders/models/reminder_detail_screen.dart';
import 'package:triggeo/features/reminders/models/reminder_list_screen.dart';
import 'package:triggeo/features/settings/settings_screen.dart';
import 'package:latlong2/latlong.dart';

final router = GoRouter(
  navigatorKey: OverlayService.navigatorKey,
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
        // 从 MapScreen 传递选中的坐标
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
