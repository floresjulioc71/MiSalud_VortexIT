import 'package:flutter_test/flutter_test.dart';
import 'package:misalud_vortexit/features/medical_studies/models/medical_study.dart';

void main() {
  test('MedicalStudy conserva datos al serializar y restaurar', () {
    final MedicalStudy source = MedicalStudy(
      id: 'study-1',
      studyDate: DateTime(2026, 7, 17),
      type: 'Radiografía',
      name: 'Radiografía de tórax',
      medicalCenter: 'Centro Médico',
      professional: 'Dra. Ejemplo',
      status: MedicalStudyStatus.reported,
      result: 'Sin hallazgos relevantes',
      notes: 'Control anual',
      nextCheckDate: DateTime(2027, 7, 17),
      attachments: const <MedicalStudyAttachment>[
        MedicalStudyAttachment(
          id: 'file-1',
          name: 'informe.pdf',
          path: '/tmp/informe.pdf',
          mimeType: 'application/pdf',
          sizeBytes: 1234,
        ),
      ],
    );

    final MedicalStudy restored = MedicalStudy.fromJson(source.toJson());

    expect(restored.id, source.id);
    expect(restored.studyDate, source.studyDate);
    expect(restored.type, source.type);
    expect(restored.status, MedicalStudyStatus.reported);
    expect(restored.attachments.single.name, 'informe.pdf');
    expect(restored.nextCheckDate, source.nextCheckDate);
  });

  test('MedicalStudyAttachment detecta imagen y PDF', () {
    const MedicalStudyAttachment image = MedicalStudyAttachment(
      id: '1',
      name: 'resultado.PNG',
      path: '/tmp/resultado.png',
      mimeType: 'image/png',
      sizeBytes: 10,
    );
    const MedicalStudyAttachment pdf = MedicalStudyAttachment(
      id: '2',
      name: 'resultado.pdf',
      path: '/tmp/resultado.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 10,
    );

    expect(image.isImage, isTrue);
    expect(image.isPdf, isFalse);
    expect(pdf.isPdf, isTrue);
  });
}
