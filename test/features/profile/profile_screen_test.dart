import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misalud_vortexit/app/app.dart';
import 'package:misalud_vortexit/core/storage/app_storage.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppStorage.initialize();
  });

  testWidgets('El dashboard abre la pantalla de Perfil médico', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MiSaludApp());

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
