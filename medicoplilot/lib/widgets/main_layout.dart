import 'package:flutter/material.dart';
import 'sidebar.dart';
import '../pages/new_encounter_page.dart';
import '../pages/all_encounters_page.dart';
import '../pages/patient_education_page.dart';
import '../services/encounter_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  String? _selectedPatient;
  String? _selectedPatientId;
  final TextEditingController _searchController = TextEditingController();
  List<PatientSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingResults = false;
  final EncounterService _encounterService = EncounterService();

  // List of pages corresponding to sidebar items
  final List<Widget> _pages = [
    const NewEncounterPage(),
    const AllEncountersPage(),
    const PatientEducationPage(),
    // Add more pages here as you create them
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoadingResults = true;
    });

    try {
      final results = await _encounterService.searchPatients(
        query: query,
        limit: 8,
      );

      setState(() {
        _searchResults = results;
        _isLoadingResults = false;
      });
    } catch (e) {
      print('Error searching patients: $e');
      setState(() {
        _searchResults = [];
        _isLoadingResults = false;
      });
    }
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _selectPatient(PatientSearchResult patient) {
    setState(() {
      _selectedPatient = patient.name;
      _selectedPatientId = patient.id;
      _isSearching = false;
      _searchController.clear();
      _searchResults = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected patient: ${patient.name}'),
        backgroundColor: const Color(0xFF059669),
        duration: const Duration(seconds: 2),
      ),
    );
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
                        Expanded(
                          child: _isSearching
                              ? _buildSearchBar()
                              : _buildPatientSelector(),
                        ),
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
    return GestureDetector(
      onTap: () {
        setState(() {
          _isSearching = true;
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
                _selectedPatient ?? 'Select a patient...',
                style: TextStyle(
                  fontSize: 14,
                  color: _selectedPatient != null
                      ? Colors.black87
                      : Colors.grey.shade600,
                ),
              ),
            ),
            Icon(Icons.search, size: 20, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF2563EB), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 20, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search patient by name or MRN...',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        if (_searchController.text.isNotEmpty)
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
            child: _isLoadingResults
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
                : _searchResults.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No patients found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final patient = _searchResults[index];
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
                                  : patient.gender ?? 'No details',
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
