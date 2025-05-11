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
  double? latitude; // New field for map location
  double? longitude; // New field for map location

  UserModel({
    this.id,
    required this.email,
    this.name,
    this.phoneNumber,
    this.photoUrl,
    this.currency = 'MYR (RM)', // Default from ProfileManagementScreen
    this.createdAt,
    this.latitude, // Initialize new field
    this.longitude, // Initialize new field
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
      'latitude': latitude, // Add to Firestore map
      'longitude': longitude, // Add to Firestore map
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
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      latitude: data['latitude']?.toDouble(), // Read from Firestore
      longitude: data['longitude']?.toDouble(), // Read from Firestore
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
      latitude: null, // Default to null for new users
      longitude: null, // Default to null for new users
    );
  }
}