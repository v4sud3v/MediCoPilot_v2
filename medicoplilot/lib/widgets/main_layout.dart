import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sidebar.dart';
import '../pages/new_encounter_page.dart';
import '../pages/all_encounters_page.dart';
import '../pages/patient_education_page.dart';
import '../pages/login_page.dart';
import '../services/encounter_service.dart';
import '../services/auth_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  String? _selectedPatient;
  String? _selectedPatientId;
  PatientDetails? _selectedPatientDetails;
  List<PatientSearchResult> _appointmentPatients = [];
  bool _isLoadingAppointments = false;
  bool _showPatientList = false;
  final EncounterService _encounterService = EncounterService();
  String _doctorName = 'Doctor';
  String _doctorEmail = '';

  // List of pages corresponding to sidebar items
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _initializePages();
    _loadAppointmentPatients();
    _loadDoctorInfo();
  }

  Future<void> _loadDoctorInfo() async {
    try {
      final details = await AuthService().getDoctorDetails();
      final user = Supabase.instance.client.auth.currentUser;
      if (mounted && details != null) {
        setState(() {
          _doctorName = details['name'] ?? 'Doctor';
          _doctorEmail = details['email'] ?? user?.email ?? '';
        });
      } else if (mounted && user != null) {
        setState(() {
          _doctorEmail = user.email ?? '';
        });
      }
    } catch (_) {}
  }

  void _initializePages() {
    _pages = [
      NewEncounterPage(
        selectedPatientId: _selectedPatientId,
        selectedPatientName: _selectedPatient,
        selectedPatientDetails: _selectedPatientDetails,
      ),
      const AllEncountersPage(),
      const PatientEducationPage(),
    ];
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadAppointmentPatients() async {
    setState(() {
      _isLoadingAppointments = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      final results = await _encounterService.searchPatients(
        query: '',
        limit: 8,
        doctorId: currentUser?.id,
      );

      setState(() {
        _appointmentPatients = results;
        _isLoadingAppointments = false;
      });
    } catch (e) {
      setState(() {
        _appointmentPatients = [];
        _isLoadingAppointments = false;
      });
    }
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    try {
      await AuthService().signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selectPatient(PatientSearchResult patient) async {
    // Fetch full patient details
    try {
      final patientDetails = await _encounterService.getPatientDetails(
        patient.id,
      );

      setState(() {
        _selectedPatient = patient.name;
        _selectedPatientId = patient.id;
        _selectedPatientDetails = patientDetails;
        _showPatientList = false;
        _initializePages();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected patient: ${patient.name}'),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading patient details: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Sidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemSelected,
            onLogout: _handleLogout,
            doctorName: _doctorName,
            doctorEmail: _doctorEmail,
          ),
          // Main content area
          Expanded(
            child: Column(
              children: [
                // Patient selection bar - only for New Encounter tab
                if (_selectedIndex == 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(25),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: Color(0xFF2563EB),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _buildPatientSelector()),
                      ],
                    ),
                  ),
                // Main page content
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSelector() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () async {
            if (_appointmentPatients.isEmpty && !_isLoadingAppointments) {
              await _loadAppointmentPatients();
            }
            if (!mounted) return;
            setState(() {
              _showPatientList = !_showPatientList;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedPatient ??
                        'Select from today\'s patient list (simulated)...',
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedPatient != null
                          ? Colors.black87
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
                Icon(
                  _showPatientList ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
        if (_showPatientList)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(51),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isLoadingAppointments
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  )
                : _appointmentPatients.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No patients available for today',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _appointmentPatients.length,
                    itemBuilder: (context, index) {
                      final patient = _appointmentPatients[index];
                      return ListTile(
                        dense: true,
                        leading: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFF2563EB),
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          patient.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          patient.age != null
                              ? '${patient.age} years old${patient.gender != null ? ' • ${patient.gender}' : ''}'
                              : patient.gender ?? 'Scheduled patient',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () => _selectPatient(patient),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}
