import '../../../core/storage/app_storage.dart';
import '../models/family_member.dart';

class FamilyStorageService {
  FamilyStorageService._();

  static const int maximumMembers = 4;
  static const String _membersKey = 'family_members';
  static const String _activeMemberIdKey = 'active_family_member_id';

  static Future<void> initialize() async {
    final List<FamilyMember> members = loadMembers();

    if (members.isEmpty) {
      final DateTime now = DateTime.now();
      final FamilyMember member = FamilyMember(
        id: now.microsecondsSinceEpoch.toString(),
        name: 'Mi perfil',
        relationship: 'Titular',
        createdAt: now,
        updatedAt: now,
      );
      await saveMembers(<FamilyMember>[member]);
      await setActiveMember(member.id);
      return;
    }

    final String? activeId = AppStorage.readString(_activeMemberIdKey);
    if (!members.any((FamilyMember member) => member.id == activeId)) {
      await setActiveMember(members.first.id);
    }
  }

  static List<FamilyMember> loadMembers() {
    final List<String>? stored = AppStorage.readStringList(_membersKey);
    if (stored == null) {
      return <FamilyMember>[];
    }

    final List<FamilyMember> members = <FamilyMember>[];
    for (final String source in stored) {
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
      throw StateError('Solo se permiten hasta 4 integrantes.');
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
        throw StateError('Solo se permiten hasta 4 integrantes.');
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
      throw StateError('Debe existir al menos un integrante.');
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
      throw StateError('No hay una persona activa.');
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
    if (!loadMembers().any((FamilyMember member) => member.id == id)) {
      throw StateError('El integrante no existe.');
    }

    final bool saved = await AppStorage.saveString(_activeMemberIdKey, id);

    if (!saved) {
      throw StateError('No fue posible seleccionar el integrante.');
    }
  }

  static String scopedKey(String baseKey) => '${baseKey}_$activeMemberId';
}
