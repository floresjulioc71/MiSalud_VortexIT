import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/storage/app_storage.dart';
import 'features/family/services/family_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppStorage.initialize();
  await FamilyStorageService.initialize();

  runApp(const MiSaludApp());
}
