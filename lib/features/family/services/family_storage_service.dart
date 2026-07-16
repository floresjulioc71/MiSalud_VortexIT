import '../../../core/storage/app_storage.dart';
import '../models/family_member.dart';

class FamilyStorageService {
  FamilyStorageService._();

  static const int maximumMembers = 4;

  static const String _membersKey = 'family_members';
  static const String _activeMemberIdKey = 'active_family_member_id';

  static const String _legacyProfileKey = 'medical_profile';
  static const String _profileRepairMarkerKey =
      'family_profile_scope_repair_v1';

  static Future<void> initialize() async {
    List<FamilyMember> members = loadMembers();

    if (members.isEmpty) {
      final DateTime now = DateTime.now();
      final FamilyMember defaultMember = FamilyMember(
        id: now.microsecondsSinceEpoch.toString(),
        name: 'Mi perfil',
        relationship: 'Titular',
        createdAt: now,
        updatedAt: now,
      );

      await saveMembers(<FamilyMember>[defaultMember]);
      await setActiveMember(defaultMember.id);
      members = <FamilyMember>[defaultMember];
    }

    final String? activeId = AppStorage.readString(_activeMemberIdKey);
    final bool activeExists = members.any(
      (FamilyMember member) => member.id == activeId,
    );

    if (!activeExists) {
      await setActiveMember(members.first.id);
    }

    await _repairProfileScoping(members);
  }

  static List<FamilyMember> loadMembers() {
    final List<String>? storedMembers = AppStorage.readStringList(_membersKey);

    if (storedMembers == null || storedMembers.isEmpty) {
      return <FamilyMember>[];
    }

    final List<FamilyMember> members = <FamilyMember>[];

    for (final String source in storedMembers) {
      try {
        members.add(FamilyMember.fromJson(source));
      } on FormatException {
        continue;
      }
    }

    members.sort(
      (FamilyMember a, FamilyMember b) => a.createdAt.compareTo(b.createdAt),
    );

    return members;
  }

  static Future<void> saveMembers(List<FamilyMember> members) async {
    if (members.length > maximumMembers) {
      throw StateError(
        'Solo se pueden registrar hasta $maximumMembers integrantes.',
      );
    }

    final bool saved = await AppStorage.saveStringList(
      _membersKey,
      members.map((FamilyMember member) => member.toJson()).toList(),
    );

    if (!saved) {
      throw StateError('No fue posible guardar el grupo familiar.');
    }
  }

  static Future<void> saveMember(FamilyMember member) async {
    final List<FamilyMember> members = loadMembers();
    final int index = members.indexWhere(
      (FamilyMember current) => current.id == member.id,
    );

    if (index == -1) {
      if (members.length >= maximumMembers) {
        throw StateError(
          'Solo se pueden registrar hasta $maximumMembers integrantes.',
        );
      }

      members.add(member);
    } else {
      members[index] = member;
    }

    await saveMembers(members);
  }

  static Future<void> deleteMember(String id) async {
    final List<FamilyMember> members = loadMembers();

    if (members.length <= 1) {
      throw StateError(
        'Debe existir al menos una persona en el grupo familiar.',
      );
    }

    members.removeWhere((FamilyMember member) => member.id == id);
    await saveMembers(members);

    if (activeMemberId == id) {
      await setActiveMember(members.first.id);
    }
  }

  static String get activeMemberId {
    final String? id = AppStorage.readString(_activeMemberIdKey);

    if (id == null || id.isEmpty) {
      throw StateError('No hay una persona activa seleccionada.');
    }

    return id;
  }

  static FamilyMember get activeMember {
    final List<FamilyMember> members = loadMembers();

    return members.firstWhere(
      (FamilyMember member) => member.id == activeMemberId,
      orElse: () => members.first,
    );
  }

  static Future<void> setActiveMember(String id) async {
    final bool exists = loadMembers().any(
      (FamilyMember member) => member.id == id,
    );

    if (!exists) {
      throw StateError('El integrante seleccionado no existe.');
    }

    final bool saved = await AppStorage.saveString(_activeMemberIdKey, id);

    if (!saved) {
      throw StateError('No fue posible seleccionar el integrante activo.');
    }
  }

  static String scopedKey(String baseKey) {
    return '${baseKey}_$activeMemberId';
  }

  static Future<void> _repairProfileScoping(List<FamilyMember> members) async {
    if (members.isEmpty || AppStorage.containsKey(_profileRepairMarkerKey)) {
      return;
    }

    final FamilyMember titular = members.first;
    final String titularProfileKey = '${_legacyProfileKey}_${titular.id}';

    final String? legacyProfile = AppStorage.readString(_legacyProfileKey);

    if (!AppStorage.containsKey(titularProfileKey) &&
        legacyProfile != null &&
        legacyProfile.trim().isNotEmpty) {
      await AppStorage.saveString(titularProfileKey, legacyProfile);
    }

    final String? titularProfile = AppStorage.readString(titularProfileKey);

    if (titularProfile != null && titularProfile.isNotEmpty) {
      for (final FamilyMember member in members.skip(1)) {
        final String memberProfileKey = '${_legacyProfileKey}_${member.id}';
        final String? memberProfile = AppStorage.readString(memberProfileKey);

        if (memberProfile == titularProfile) {
          await AppStorage.remove(memberProfileKey);
        }
      }
    }

    if (AppStorage.containsKey(_legacyProfileKey)) {
      await AppStorage.remove(_legacyProfileKey);
    }

    await AppStorage.saveBool(_profileRepairMarkerKey, true);
  }
}
