import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/theme.dart'; // Assuming theme.dart contains appGradient
import 'competency.dart';
import 'dashboard.dart';
import 'request_type.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

class AppointmentPage extends StatefulWidget {
  final String requestType;
  final String industryType;

  const AppointmentPage({
    Key? key,
    required this.requestType,
    required this.industryType,
  }) : super(key: key);

  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage>
    with TickerProviderStateMixin {
  String? errorMessage;
  String? jobDescription;
  final TextEditingController _controllerJobDate = TextEditingController();
  final TextEditingController _controllerJobTime = TextEditingController();
  final TextEditingController _controllerSiteLocation = TextEditingController();
  final TextEditingController _controllerJobDescription =
      TextEditingController();
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkLocationPermissions();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _controllerJobDate.dispose();
    _controllerJobTime.dispose();
    _controllerSiteLocation.dispose();
    _controllerJobDescription.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermissions() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDeniedDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDeniedDialog(permanentlyDenied: true);
        return;
      }

      bool isLocationServiceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        _showEnableLocationDialog();
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error checking location permissions: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking location permissions: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPermissionDeniedDialog({bool permanentlyDenied = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_off,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Location Permission Required',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  permanentlyDenied
                      ? 'Location permissions are permanently denied. Please enable them from settings.'
                      : 'Location permission is needed to proceed. Please allow location access.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.2),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!permanentlyDenied)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            _checkLocationPermissions();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.white, Color(0xFFF0F0F0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Request Again',
                              style: TextStyle(
                                color: Color(0xFF1E3A8A),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEnableLocationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_off,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Enable Location Services',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Location services are disabled. Please enable them in your device settings.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.2),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Geolocator.openLocationSettings();
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.white, Color(0xFFF0F0F0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Settings',
                            style: TextStyle(
                              color: Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _storeAppointmentData() async {
    if (_controllerJobDate.text.isEmpty ||
        _controllerJobTime.text.isEmpty ||
        _controllerSiteLocation.text.isEmpty ||
        _controllerJobDescription.text.isEmpty) {
      setState(() {
        errorMessage = 'Please fill in all required fields';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String userId = _auth.currentUser?.uid ?? '';
      String userEmail = _auth.currentUser?.email ?? '';
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('yyyy-MM-dd').format(now);

      if (userId.isEmpty) {
        throw Exception('No user is currently signed in');
      }

      Map<String, dynamic> appointmentData = {
        'jobDate': _controllerJobDate.text,
        'jobTime': _controllerJobTime.text,
        'siteLocation': _controllerSiteLocation.text,
        'jobDescription': _controllerJobDescription.text,
        'appointmentDate': formattedDate,
        'timestamp': now,
        'status': 'Active',
        'clientId': userId,
        'requestType': widget.requestType,
        'industryType': widget.industryType,
      };

      await _firestore
          .collection('selection')
          .doc(userId)
          .collection('appointments')
          .add(appointmentData);

      if (userEmail.isNotEmpty) {
        await _firestore.collection('integrated').doc(userEmail).set({
          'appointments': FieldValue.arrayUnion([appointmentData]),
        }, SetOptions(merge: true));
      }

      await _firestore.collection('notifications').add({
        ...appointmentData,
        'acceptedConsultantId': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CompetencyPage(
            requestType: widget.requestType,
            industryType: widget.industryType,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Error saving appointment: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving appointment: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A8A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E3A8A),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    setState(() {
      _controllerJobDate.text = DateFormat('yyyy-MM-dd').format(pickedDate!);
    });
    }

  Future<void> _selectTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A8A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E3A8A),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final now = DateTime.now();
      final dt = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      final format = DateFormat.Hm();
      setState(() {
        _controllerJobTime.text = format.format(dt);
      });
    }
  }

  Widget _buildModernCard({
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: const Color(0xFF1E3A8A), size: 24),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isDate = false,
    bool isTime = false,
    int maxLines = 1,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        readOnly: isDate || isTime,
        maxLines: maxLines,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          suffixIcon: suffixIcon,
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: appGradient),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Image.network(
                                  'https://firebasestorage.googleapis.com/v0/b/dots-b3559.appspot.com/o/Dots%20logo.png?alt=media&token=2c2333ea-658a-4a70-9378-39c6c248f5ca',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.error_outline,
                                        color: Color(0xFF1E3A8A),
                                        size: 30,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Appointment Details',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Error Message
                      if (errorMessage != null)
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Form Card
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildModernCard(
                            title: 'Enter Appointment Details',
                            icon: Icons.event,
                            child: Column(
                              children: [
                                Text(
                                  'Please fill in the required details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  label: 'Job Date',
                                  controller: _controllerJobDate,
                                  isDate: true,
                                  onTap: _selectDate,
                                  suffixIcon: const Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                                _buildInputField(
                                  label: 'Job Time',
                                  controller: _controllerJobTime,
                                  isTime: true,
                                  onTap: _selectTime,
                                  suffixIcon: const Icon(
                                    Icons.access_time,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                                LocationAutocomplete(
                                  controller: _controllerSiteLocation,
                                  onLocationSelected: (place) {
                                    setState(() {
                                      _controllerSiteLocation.text =
                                          place.formatted;
                                    });
                                  },
                                  mapPickerCallback: _showLocationPicker,
                                ),
                                _buildInputField(
                                  label: 'Job Description',
                                  controller: _controllerJobDescription,
                                  maxLines: 4,
                                ),
                                const SizedBox(height: 24),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _storeAppointmentData,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Colors.white,
                                            Color(0xFFF0F0F0),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'Next',
                                        style: TextStyle(
                                          color: Color(0xFF1E3A8A),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RequestTypePage(),
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        'Back',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _showLocationPicker() async {
    setState(() => _isLoading = true);
    try {
      LatLng? selectedLocation = await showDialog<LatLng>(
        context: context,
        builder: (BuildContext context) {
          return MapPickerDialog();
        },
      );

      if (selectedLocation != null) {
        try {
          final place = await GeoapifyLocationSuggestions.reverseGeocode(
            selectedLocation.latitude,
            selectedLocation.longitude,
          );

          if (place != null) {
            setState(() {
              _controllerSiteLocation.text = place.formatted;
            });
          } else {
            throw Exception('Failed to get address for selected location');
          }
        } catch (e) {
          setState(() {
            errorMessage = 'Error getting address: $e';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Failed to get address for selected location',
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error selecting location: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error selecting location'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class MapPickerDialog extends StatefulWidget {
  const MapPickerDialog({Key? key}) : super(key: key);

  @override
  _MapPickerDialogState createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<MapPickerDialog> {
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(0, 0);
  bool _isLoading = true;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _selectedLocation = _currentLocation;
          _isLoading = false;
        });
        _mapController.move(_currentLocation, 15.0);
      }
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Select Location',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color.fromARGB(225, 0, 74, 173),
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 400,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 15.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedLocation = point;
                  });
                },
              ),
              children: [
                // Use the working TileLayer from original implementation
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.yourapp.name',
                  tileProvider: NetworkTileProvider(),
                  maxZoom: 19,
                  keepBuffer: 5,
                  // Additional configurations for dark theme compatibility
                  tileBuilder: (context, child, tile) {
                    return child;
                  },
                ),
                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        width: 80,
                        height: 80,
                        child: Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (_isLoading)
              Center(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color.fromARGB(225, 0, 74, 173),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text('Loading location...'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(225, 0, 74, 173),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Select',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          onPressed: _selectedLocation == null
              ? null
              : () => Navigator.of(context).pop(_selectedLocation),
        ),
      ],
    );
  }
}

class LocationAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final Function(GeoapifyPlace)? onLocationSelected;
  final VoidCallback? mapPickerCallback;

  const LocationAutocomplete({
    Key? key,
    required this.controller,
    this.onLocationSelected,
    this.mapPickerCallback,
  }) : super(key: key);

  @override
  _LocationAutocompleteState createState() => _LocationAutocompleteState();
}

class _LocationAutocompleteState extends State<LocationAutocomplete> {
  List<GeoapifyPlace> _suggestions = [];
  bool _isLoading = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), _hideOverlay);
      }
    });
  }

  @override
  void dispose() {
    _hideOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay(BuildContext context) {
    _hideOverlay();

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height,
        width: size.width,
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    _suggestions[index].formatted,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    widget.controller.text = _suggestions[index].formatted;
                    widget.onLocationSelected?.call(_suggestions[index]);
                    _hideOverlay();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _getSuggestions(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
      });
      _hideOverlay();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final suggestions =
          await GeoapifyLocationSuggestions.fetchLocationSuggestions(query);
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });

      if (_suggestions.isNotEmpty && _focusNode.hasFocus) {
        _showOverlay(context);
      } else {
        _hideOverlay();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location suggestions: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: _buildInputField(
        label: 'Site Location',
        controller: widget.controller,
        isLocation: true,
        focusNode: _focusNode,
        onChanged: _getSuggestions,
        suffixIcon: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF1E3A8A),
                    ),
                  ),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.map, color: Color(0xFF1E3A8A)),
                onPressed: widget.mapPickerCallback,
              ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isLocation = false,
    FocusNode? focusNode,
    Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        suffixIcon: suffixIcon,
      ),
      style: const TextStyle(color: Colors.white),
    );
  }
}

class GeoapifyLocationSuggestions {
  static const String apiKey = 'b980b19871164cc8b2651ee6e57d29e7';

  static Future<List<GeoapifyPlace>> fetchLocationSuggestions(
    String query,
  ) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final String url =
          'https://api.geoapify.com/v1/geocode/autocomplete?' +
          'text=${Uri.encodeComponent(query)}' +
          '&format=json' +
          '&apiKey=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];

        return results
            .map(
              (result) => GeoapifyPlace(
                formatted: result['formatted'] as String,
                lat: (result['lat'] is int)
                    ? (result['lat'] as int).toDouble()
                    : result['lat'] as double,
                lon: (result['lon'] is int)
                    ? (result['lon'] as int).toDouble()
                    : result['lon'] as double,
              ),
            )
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception(
          'Invalid or expired API key. Please check your Geoapify API key.',
        );
      } else {
        throw Exception('Failed to fetch suggestions: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<GeoapifyPlace?> reverseGeocode(double lat, double lon) async {
    try {
      final String url =
          'https://api.geoapify.com/v1/geocode/reverse?' +
          'lat=$lat&lon=$lon' +
          '&format=json' +
          '&apiKey=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];

        if (results.isNotEmpty) {
          final result = results[0];
          return GeoapifyPlace(
            formatted: result['formatted'] as String,
            lat: (result['lat'] is int)
                ? (result['lat'] as int).toDouble()
                : result['lat'] as double,
            lon: (result['lon'] is int)
                ? (result['lon'] as int).toDouble()
                : result['lon'] as double,
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception(
          'Invalid or expired API key. Please check your Geoapify API key.',
        );
      } else {
        throw Exception('Failed to reverse geocode: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }
}

class GeoapifyPlace {
  final String formatted;
  final double lat;
  final double lon;

  GeoapifyPlace({
    required this.formatted,
    required this.lat,
    required this.lon,
  });
}
