import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'services/api_service.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load date/number symbols for all locales (Arabic + English).
  await initializeDateFormatting();
  // Restore the saved light/dark choice before the first frame.
  await ThemeController.load();
  // Pick up the current backend URL (self-heals when the tunnel rotates).
  await ApiService.resolveBaseUrl();
  runApp(const SalesTrackerApp());
}
