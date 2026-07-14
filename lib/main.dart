import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/storage/app_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppStorage.initialize();

  runApp(const MiSaludApp());
}
