import '../../../core/storage/app_storage.dart';
import '../../family/services/family_storage_service.dart';
import '../models/doctor_item.dart';

class DoctorStorageService {
  DoctorStorageService._();

  static const String _baseStorageKey = 'doctor_items';

  static String get _storageKey =>
      FamilyStorageService.scopedKey(_baseStorageKey);

  static List<DoctorItem> loadItems() {
    final List<String>? storedItems = AppStorage.readStringList(_storageKey);

    if (storedItems == null || storedItems.isEmpty) {
      return <DoctorItem>[];
    }

    final List<DoctorItem> items = <DoctorItem>[];

    for (final String source in storedItems) {
      try {
        items.add(DoctorItem.fromJson(source));
      } on FormatException {
        continue;
      }
    }

    items.sort((DoctorItem a, DoctorItem b) {
      if (a.isPrimaryDoctor != b.isPrimaryDoctor) {
        return a.isPrimaryDoctor ? -1 : 1;
      }

      return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    });

    return items;
  }

  static Future<void> saveItems(List<DoctorItem> items) async {
    final bool saved = await AppStorage.saveStringList(
      _storageKey,
      items.map((DoctorItem item) => item.toJson()).toList(),
    );

    if (!saved) {
      throw StateError(
        'No fue posible guardar los médicos y centros de salud.',
      );
    }
  }

  static Future<void> saveItem(DoctorItem item) async {
    final List<DoctorItem> items = loadItems();

    if (item.isPrimaryDoctor) {
      for (int index = 0; index < items.length; index++) {
        final DoctorItem current = items[index];

        if (current.id != item.id && current.isPrimaryDoctor) {
          items[index] = DoctorItem(
            id: current.id,
            firstName: current.firstName,
            lastName: current.lastName,
            specialty: current.specialty,
            licenseNumber: current.licenseNumber,
            phone: current.phone,
            mobile: current.mobile,
            email: current.email,
            website: current.website,
            institution: current.institution,
            office: current.office,
            address: current.address,
            notes: current.notes,
            isPrimaryDoctor: false,
            colorValue: current.colorValue,
            createdAt: current.createdAt,
            updatedAt: DateTime.now(),
          );
        }
      }
    }

    final int existingIndex = items.indexWhere(
      (DoctorItem current) => current.id == item.id,
    );

    if (existingIndex == -1) {
      items.add(item);
    } else {
      items[existingIndex] = item;
    }

    await saveItems(items);
  }

  static Future<void> deleteItem(String id) async {
    final List<DoctorItem> items = loadItems()
      ..removeWhere((DoctorItem item) => item.id == id);

    await saveItems(items);
  }
}
