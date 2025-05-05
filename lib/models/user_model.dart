import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class UserModel {
  String? id;
  String email;
  String? name;
  String? phoneNumber;
  String? photoUrl;
  String? currency; // For ProfileManagementScreen's _currency
  DateTime? createdAt;

  UserModel({
    this.id,
    required this.email,
    this.name,
    this.phoneNumber,
    this.photoUrl,
    this.currency = 'MYR (RM)', // Default from ProfileManagementScreen
    this.createdAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'currency': currency,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  // Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'],
      phoneNumber: data['phoneNumber'],
      photoUrl: data['photoUrl'],
      currency: data['currency'] ?? 'MYR (RM)',
      createdAt: data['createdAt']?.toDate(),
    );
  }

  // Create from FirebaseAuth.User (after login/signup)
  factory UserModel.fromFirebaseUser(auth.User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName,
      phoneNumber: user.phoneNumber,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime,
    );
  }
}