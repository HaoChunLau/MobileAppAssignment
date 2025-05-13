import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app_assignment/models/user_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  ProfileManagementScreenState createState() => ProfileManagementScreenState();
}

class ProfileManagementScreenState extends State<ProfileManagementScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;
  bool _isEmailPendingVerification = false;
  String _currency = 'MYR (RM)';
  String? _photoUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  GoogleMapController? _mapController;
  double? _latitude = 3.1390; // Default: Kuala Lumpur
  double? _longitude = 101.6869; // Default: Kuala Lumpur
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  // ======================== Load User Data ========================
  Future<void> _loadUserData() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user logged in')),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final UserModel user = UserModel.fromFirestore(userDoc);

      if (user.emailPendingVerification == true &&
          currentUser.email != null &&
          currentUser.email != user.email) {
        // Update Firestore with the new verified email
        await _firestore.collection('users').doc(currentUser.uid).update({
          'email': currentUser.email,
          'emailPendingVerification': false, // Reset the flag
        });
        // Refresh userDoc after update
        final updatedDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();
        setState(() {
          final updatedUser = UserModel.fromFirestore(updatedDoc);
          _nameController.text = updatedUser.name ?? '';
          _emailController.text = currentUser.email ?? updatedUser.email;
          _phoneController.text = updatedUser.phoneNumber ?? '';
          _currency = updatedUser.currency ?? 'MYR (RM)';
          _photoUrl = updatedUser.photoUrl;
          _latitude = updatedUser.latitude ?? 3.1390;
          _longitude = updatedUser.longitude ?? 101.6869;
          _selectedLocation = (_latitude != null && _longitude != null)
              ? LatLng(_latitude!, _longitude!)
              : null;
          _isEmailPendingVerification = false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _nameController.text = user.name ?? '';
          _emailController.text = currentUser.email ?? user.email;
          _phoneController.text = user.phoneNumber ?? '';
          _currency = user.currency ?? 'MYR (RM)';
          _photoUrl = user.photoUrl;
          _latitude = user.latitude ?? 3.1390;
          _longitude = user.longitude ?? 101.6869;
          _selectedLocation = (_latitude != null && _longitude != null)
              ? LatLng(_latitude!, _longitude!)
              : null;
          _isEmailPendingVerification = user.emailPendingVerification ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
    }
  }

  // ======================== Save Changes ========================
  Future<void> _saveChanges() async {
    if (!_isEditing) return;

    setState(() => _isLoading = true);

    try {
      if (!_validateInputs()) {
        setState(() => _isLoading = false);
        return;
      }

      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final UserModel currentData = UserModel.fromFirestore(userDoc);

      final bool hasChanges = _nameController.text != currentData.name ||
          _phoneController.text != currentData.phoneNumber ||
          _currency != currentData.currency ||
          _photoUrl != currentData.photoUrl ||
          _emailController.text != currentData.email ||
          _latitude != currentData.latitude ||
          _longitude != currentData.longitude;

      if (!hasChanges) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No changes to save')),
          );
          setState(() {
            _isLoading = false;
            _isEditing = false;
          });
        }
        return;
      }

      // First check if email has been changed
      if (_emailController.text != currentData.email) {
        // Email has changed - we need to update it in Firebase Auth
        await _updateEmail(_emailController.text);
      }

      await _firestore.collection('users').doc(currentUser.uid).update({
        'name': _nameController.text,
        'phoneNumber': _phoneController.text,
        'currency': _currency,
        'photoUrl': _photoUrl,
        'latitude': _latitude,
        'longitude': _longitude,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateEmail(String newEmail) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Updating email in Firebase Auth requires recent authentication
      // For real production code, you might want to re-authenticate the user first
      // This method is currently not used in _changeEmail, but kept for compatibility
    } catch (e) {
      // Handle specific Firebase Auth errors
      if (e is FirebaseAuthException) {
        if (e.code == 'requires-recent-login') {
          throw Exception('Please log out and log in again before changing your email');
        } else if (e.code == 'email-already-in-use') {
          throw Exception('This email is already used by another account');
        }
      }
      // Rethrow to be caught by the calling method
      rethrow;
    }
  }

  // ======================== Change Email ========================
  Future<void> _changeEmail() async {
    if (_isEmailPendingVerification) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your pending email before changing to a new email.'),
          ),
        );
      }
      return;
    }
    final TextEditingController newEmailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Email'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Please enter your new email address and current password to verify your identity.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newEmailController,
                  decoration: const InputDecoration(
                    labelText: 'New Email Address',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                ),
                const SizedBox(height: 8),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                // Validate inputs
                final newEmail = newEmailController.text.trim();
                final password = passwordController.text;

                if (newEmail.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(newEmail)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid email address')),
                  );
                  return;
                }

                if (password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your password')),
                  );
                  return;
                }

                // Start loading
                setState(() => isLoading = true);

                try {
                  // 1. Re-authenticate user
                  final User? user = _auth.currentUser;
                  if (user == null) throw Exception('User not logged in');

                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: password,
                  );

                  await user.reauthenticateWithCredential(credential);

                  // 2. Confirm logout requirement
                  final bool? confirmLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text(
                        'Changing your email requires you to log out and re-login with the new email after verification. Do you want to proceed?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Proceed'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmLogout != true) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email update canceled. Logout is required to change email.'),
                        ),
                      );
                    }
                    setState(() => isLoading = false);
                    Navigator.pop(context); // Close the email change dialog
                    return;
                  }

                  // 3. Initiate email update
                  await user.verifyBeforeUpdateEmail(newEmail);
                  await user.reload();

                  // 4. Update Firestore
                  await _firestore.collection('users').doc(user.uid).update({
                    'emailPendingVerification': true,
                  });

                  // 5. Update UI
                  setState(() {
                    _emailController.text = newEmail;
                    _isEmailPendingVerification = true;
                  });

                  // 6. Close dialog
                  if (mounted) Navigator.pop(context);

                  // 7. Show verification message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Verification email sent. You will be logged out. Please verify your new email and log in again.',
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 8),
                      ),
                    );
                  }

                  // 8. Log out and navigate to login
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                          (route) => false,
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  // Handle specific Firebase Auth errors
                  String errorMessage;

                  switch (e.code) {
                    case 'wrong-password':
                      errorMessage = 'The password is incorrect.';
                      break;
                    case 'invalid-email':
                      errorMessage = 'The email address is not valid.';
                      break;
                    case 'too-many-requests':
                      errorMessage = 'Too many attempts. Please try again later.';
                      break;
                    case 'operation-not-allowed':
                      errorMessage = 'Email verification is not enabled for this project.';
                      break;
                    default:
                      errorMessage = 'Error: ${e.message}';
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMessage)),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => isLoading = false);
                }
              },
              child: const Text('Update Email'),
            ),
          ],
        ),
      ),
    );
  }

  // ======================== Photo Selection and Upload ========================
  Future<void> _changeProfilePhoto() async {
    try {
      await showModalBottomSheet(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () async {
                Navigator.pop(context);
                await _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _getImage(ImageSource.gallery);
              },
            ),
            if (_photoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove photo',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _removePhoto();
                },
              ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _getImage(ImageSource source) async {
    setState(() => _isLoading = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 200,
        maxHeight: 200,
        imageQuality: 60,
      );

      if (pickedFile == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Convert image to base64
      final File imageFile = File(pickedFile.path);
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // Proceed with saving without size check
      await _saveBase64Image(base64Image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBase64Image(String base64Image) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      setState(() {
        _photoUrl = 'data:image/jpeg;base64,$base64Image';
      });

      // Only update Firestore, not Firebase Auth
      await _firestore.collection('users').doc(currentUser.uid).update({
        'photoUrl': 'data:image/jpeg;base64,$base64Image',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _isLoading = true);

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      setState(() {
        _photoUrl = null;
        _isLoading = false;
      });

      // Only update Firestore, not Firebase Auth
      await _firestore.collection('users').doc(currentUser.uid).update({
        'photoUrl': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo removed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error removing photo: ${e.toString()}'),
        ));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true, // Allow default pop to return to Settings
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile Management'),
          // Remove automaticallyImplyLeading: false to enable default back button
          actions: [
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              onPressed: () {
                if (_isEditing) {
                  _saveChanges();
                } else {
                  setState(() => _isEditing = true);
                }
              },
            )
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 24),
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                    _buildEmailInfoSection(),
                    const SizedBox(height: 24),
                    _buildPreferencesSection(),
                    const SizedBox(height: 24),
                    _buildDataSection(),
                    const SizedBox(height: 24),
                    _buildLogoutButton(),
                  ],
                ),
              ),
        // No bottomNavigationBar
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _isEditing ? () => _changeProfilePhoto() : null,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800] // Darker, contrasting background in dark mode
                      : Theme.of(context).primaryColor.withAlpha((0.1 * 255).round()),
                  backgroundImage:
                  _photoUrl != null && _photoUrl!.startsWith('data:image')
                      ? MemoryImage(base64Decode(_photoUrl!.split(',')[1]))
                      : null,
                  child: _photoUrl == null
                      ? Icon(
                    Icons.person,
                    size: 80,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white // White icon in dark mode
                        : Theme.of(context).primaryColor,
                  )
                      : null,
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Text(
            _nameController.text,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            _emailController.text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: OutlinedButton.icon(
                icon: Icon(Icons.photo_camera),
                label: Text('Change Photo'),
                onPressed: () => _changeProfilePhoto(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Personal Information'),
        SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInfoField(
                  label: 'Name',
                  value: _nameController.text,
                  controller: _nameController,
                  isEditing: _isEditing,
                  icon: Icons.person,
                ),
                Divider(height: 24),
                _buildInfoField(
                  label: 'Phone Number',
                  value: _phoneController.text,
                  controller: _phoneController,
                  isEditing: _isEditing,
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Location'),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation ?? LatLng(3.1390, 101.6869),
                    zoom: 15,
                  ),
                  markers: _selectedLocation != null
                      ? {
                          Marker(
                            markerId: const MarkerId('user_location'),
                            position: _selectedLocation!,
                            infoWindow:
                                const InfoWindow(title: 'Your Location'),
                          ),
                        }
                      : {},
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  onTap: _isEditing
                      ? (LatLng position) {
                          setState(() {
                            _selectedLocation = position;
                            _latitude = position.latitude;
                            _longitude = position.longitude;
                          });
                        }
                      : null,
                  gestureRecognizers: _isEditing
                      ? {
                          Factory<PanGestureRecognizer>(
                              () => PanGestureRecognizer()),
                          Factory<ScaleGestureRecognizer>(
                              () => ScaleGestureRecognizer()),
                          Factory<TapGestureRecognizer>(
                              () => TapGestureRecognizer()),
                        }
                      : {},
                ),
              ),
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use Current Location'),
                    onPressed: _setCurrentLocation,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Email Information'),
        SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.email, color: Colors.grey[600]),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _emailController.text,
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          if (_isEmailPendingVerification) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Pending Verification',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  icon: Icon(_isEditing ? Icons.check : Icons.edit),
                  label: Text(''),
                  onPressed: _isEmailPendingVerification ? null : () => _changeEmail(),
                  style: TextButton.styleFrom(
                    foregroundColor: _isEmailPendingVerification ? Colors.grey : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Preferences'),
        SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.attach_money),
                title: Text('Currency'),
                subtitle: Text(_currency),
                trailing: _isEditing ? Icon(Icons.chevron_right) : null,
                onTap: _isEditing ? () => _showCurrencyPicker() : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Data Management'),
        SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.download),
                title: Text('Export Account Data'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/export');
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.red),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.red),
                onTap: () => _showDeleteAccountDialog(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Log Out'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text('Log Out', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }
        }
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.logout,
            color: Colors.white,
          ),
          SizedBox(width: 8),
          Text(
            'Log Out',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.grey[600]),
        SizedBox(width: 16),
        Expanded(
          child: isEditing
              ? TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: label,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: keyboardType,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  bool _validateInputs() {
    // Email validation
    final emailValid =
        RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text);
    if (!emailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return false;
    }

    // Name validation - make sure it's not empty
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return false;
    }

    // Phone validation - make it required
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return false;
    }

    // Malaysian format: +60 or 0 followed by 8-11 digits
    final phoneValid =
        RegExp(r'^(\+?60|0)[0-9]{8,11}$').hasMatch(_phoneController.text);
    if (!phoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please enter a valid Malaysian phone number (e.g., +60123456789 or 0123456789)')),
      );
      return false;
    }

    return true;
  }

  void _showCurrencyPicker() {
    final currencies = [
      'MYR (RM)',
      'USD (\$)',
      'EUR (€)',
      'GBP (£)',
      'JPY (¥)',
      'SGD (S\$)',
    ];

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Select Currency'),
        children: currencies.map((currency) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() {
                _currency = currency;
              });
              Navigator.pop(context);
            },
            child: Text(currency),
          );
        }).toList(),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all data. This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _deleteAccount(); // Handle deletion
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 1. Delete Firestore data
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // 2. Delete Auth account
      await user.delete();

      // Navigate to login
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _setCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location permissions are permanently denied')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _selectedLocation = LatLng(_latitude!, _longitude!);
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_selectedLocation!),
      );
    });
  }
}