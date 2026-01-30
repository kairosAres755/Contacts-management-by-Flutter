import 'package:cloud_firestore/cloud_firestore.dart';

/// A contact stored in Firestore under the current user.
class Contact {
  const Contact({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    DateTime? createdAt,
  }) : _createdAt = createdAt;

  Contact.fromMap(Map<String, dynamic> map, String id)
      : id = id,
        name = map['name'] as String? ?? '',
        phone = map['phone'] as String? ?? '',
        email = map['email'] as String? ?? '',
        _createdAt = (map['createdAt'] as Timestamp?)?.toDate();

  final String id;
  final String name;
  final String phone;
  final String email;
  final DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  Contact copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    DateTime? createdAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? _createdAt,
    );
  }
}
