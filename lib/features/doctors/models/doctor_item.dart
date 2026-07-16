import 'dart:convert';

class DoctorItem {
  final String id;
  final String firstName;
  final String lastName;
  final String specialty;
  final String licenseNumber;
  final String phone;
  final String mobile;
  final String email;
  final String website;
  final String institution;
  final String office;
  final String address;
  final String notes;
  final bool isPrimaryDoctor;
  final int colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DoctorItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.specialty = '',
    this.licenseNumber = '',
    this.phone = '',
    this.mobile = '',
    this.email = '',
    this.website = '',
    this.institution = '',
    this.office = '',
    this.address = '',
    this.notes = '',
    this.isPrimaryDoctor = false,
    this.colorValue = 0xFF1565C0,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName {
    return '$firstName $lastName'.trim();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'specialty': specialty,
      'licenseNumber': licenseNumber,
      'phone': phone,
      'mobile': mobile,
      'email': email,
      'website': website,
      'institution': institution,
      'office': office,
      'address': address,
      'notes': notes,
      'isPrimaryDoctor': isPrimaryDoctor,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DoctorItem.fromMap(Map<String, dynamic> map) {
    final DateTime now = DateTime.now();

    return DoctorItem(
      id: map['id'] as String? ?? now.microsecondsSinceEpoch.toString(),
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      specialty: map['specialty'] as String? ?? '',
      licenseNumber: map['licenseNumber'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      mobile: map['mobile'] as String? ?? '',
      email: map['email'] as String? ?? '',
      website: map['website'] as String? ?? '',
      institution: map['institution'] as String? ?? '',
      office: map['office'] as String? ?? '',
      address: map['address'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      isPrimaryDoctor: map['isPrimaryDoctor'] as bool? ?? false,
      colorValue: map['colorValue'] as int? ?? 0xFF1565C0,
      createdAt: _parseDate(map['createdAt']) ?? now,
      updatedAt: _parseDate(map['updatedAt']) ?? now,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DoctorItem.fromJson(String source) {
    final dynamic decoded = jsonDecode(source);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Profesional médico inválido.');
    }

    return DoctorItem.fromMap(decoded);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
