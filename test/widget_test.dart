import 'package:flutter_test/flutter_test.dart';
import 'package:misalud_vortexit/app/app.dart';

void main() {
  testWidgets('La pantalla principal muestra los elementos iniciales', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MiSaludApp());

    expect(find.text('MiSalud VortexIT'), findsOneWidget);

    expect(find.text('Mi información médica'), findsOneWidget);

    expect(find.text('Perfil médico'), findsOneWidget);
  });
}
