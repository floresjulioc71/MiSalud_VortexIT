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

  testWidgets('El selector abre el dashboard y luego el Perfil médico', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MiSaludApp());
    await tester.pumpAndSettle();

    expect(find.text('Seleccionar integrante'), findsOneWidget);

    await tester.tap(find.text('Mi perfil'));

    await tester.pumpAndSettle();

    expect(find.text('Perfil médico'), findsOneWidget);

    await tester.tap(find.text('Perfil médico'));

    await tester.pumpAndSettle();

    expect(find.text('Datos personales'), findsOneWidget);

    expect(find.text('Nombre y apellido'), findsOneWidget);

    expect(find.text('DNI'), findsOneWidget);

    expect(find.text('Fecha de nacimiento'), findsOneWidget);

    expect(find.text('Grupo sanguíneo'), findsOneWidget);
  });
}
