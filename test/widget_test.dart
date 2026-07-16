import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misalud_vortexit/app/app.dart';
import 'package:misalud_vortexit/core/storage/app_storage.dart';
import 'package:misalud_vortexit/features/family/services/family_storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppStorage.initialize();
    await FamilyStorageService.initialize();
  });

  testWidgets('La aplicación muestra la selección de integrante', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MiSaludApp());
    await tester.pumpAndSettle();

    expect(find.text('Seleccionar integrante'), findsOneWidget);

    expect(find.text('Mi perfil'), findsOneWidget);
  });
}
