import 'package:flutter/material.dart';
import 'package:ojt_management_system/database/db_helper.dart';
import 'package:ojt_management_system/pages/certificate_page.dart';
import 'package:ojt_management_system/pages/generate_qr_page.dart';
import 'package:ojt_management_system/pages/home_page.dart';
import 'package:ojt_management_system/pages/table_page.dart';

class StudentInputPage extends StatefulWidget {
  const StudentInputPage({super.key});

  @override
  State<StudentInputPage> createState() => _StudentInputPageState();
}

class _StudentInputPageState extends State<StudentInputPage> {
  String selectedPage = 'input'; // Default page is 'home'
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _programController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _ojtHoursController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _officeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final DBHelper dbHelper = DBHelper();

  List<String> programSuggestions = [];
  List<String> schoolSuggestions = [];
  List<String> ojtHourSuggestions = [];
  List<String> startDateSuggestions = [];
  List<String> endDateSuggestions = [];
  List<String> officeSuggestions = [];
  List<String> addressSuggestions = [];

  @override
  void initState() {
    super.initState();
    loadSuggestions(); // load your suggestions when the page opens
  }

  // Update the selected page
  void _onPageSelected(String page) {
    setState(() {
      selectedPage = page;
    });
  }

  Future<void> loadSuggestions() async {
    // Fetch data from DB using dbHelper instance
    programSuggestions =
        await DBHelper.getDistinctPrograms(); // Fetch distinct programs
    schoolSuggestions =
        await DBHelper.getDistinctSchools(); // Fetch distinct schools
    ojtHourSuggestions =
        await dbHelper.getDistinctOJTHours(); // Fetch distinct OJT hours
    startDateSuggestions =
        await dbHelper.getDistinctStartDates(); // Fetch distinct start dates
    endDateSuggestions =
        await dbHelper.getDistinctEndDates(); // Fetch distinct end dates
    officeSuggestions =
        await DBHelper.getDistinctOffices(); // Fetch distinct offices
    addressSuggestions =
        await DBHelper.getDistinctAddresses(); // Fetch distinct addresses
    setState(() {}); // Rebuild the UI with loaded suggestions
  }

  void _saveStudent() async {
    if (_formKey.currentState!.validate()) {
      // Remove any periods (.) from the middle initial
      final middleInitial =
          _middleNameController.text.trim().replaceAll('.', '').toUpperCase();

      final student = {
        'first_name': _firstNameController.text.trim(),
        'middle_initial': middleInitial, // Save without periods
        'last_name': _lastNameController.text.trim(),
        'program': _programController.text.trim(),
        'school': _schoolController.text.trim(),
        'ojt_hours': _ojtHoursController.text.trim(),
        'start_date': _startDateController.text.trim(),
        'end_date': _endDateController.text.trim(),
        'office': _officeController.text.trim(),
        'address': _addressController.text.trim(),
      };

      await DBHelper.insertStudent(student);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student saved successfully')),
      );

      _formKey.currentState!.reset();

      _firstNameController.clear();
      _middleNameController.clear();
      _lastNameController.clear();
      _programController.clear();
      _schoolController.clear();
      _ojtHoursController.clear();
      _startDateController.clear();
      _endDateController.clear();
      _officeController.clear();
      _addressController.clear();

      await loadSuggestions();
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator:
            (value) =>
                value == null || value.trim().isEmpty
                    ? 'This field is required'
                    : null,
      ),
    );
  }

  Widget buildAutoCompleteField({
    required String hint,
    required TextEditingController controller,
    required List<String> suggestions,
  }) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: FocusNode(),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return suggestions; // Show all if nothing is typed
        }
        return suggestions.where((String option) {
          return option.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          );
        });
      },

      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        );
      },

      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: Container(
              width: 570, // Set your desired width here
              constraints: BoxConstraints(
                maxHeight: 200, // Set max height to make it scrollable
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar (Drawer)
          Container(
            width: 135,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 241, 246, 248),
              border: Border(right: BorderSide(color: Colors.white, width: 1)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Image.asset(
                  'assets/images/pgp_logo.png', // Update this to your actual image path
                  height: 85, // adjust size as needed
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 30),

                // Home
                GestureDetector(
                  onTap: () {
                    _onPageSelected('home');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              selectedPage == 'home'
                                  ? const Color.fromARGB(255, 193, 211, 228)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 17,
                        ),
                        child: Icon(
                          Icons.home,
                          color:
                              selectedPage == 'home'
                                  ? Colors.black
                                  : Colors.black54,
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Home',
                        style: TextStyle(
                          fontWeight:
                              selectedPage == 'home'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              selectedPage == 'home'
                                  ? Colors.black
                                  : Colors.black54,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Add Student
                GestureDetector(
                  onTap: () {
                    _onPageSelected('input');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentInputPage(),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              selectedPage == 'input'
                                  ? const Color.fromARGB(255, 193, 211, 228)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 17,
                        ),
                        child: Icon(
                          Icons.person_add,
                          color:
                              selectedPage == 'input'
                                  ? Colors.black
                                  : Colors.black54,
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Add Student',
                        style: TextStyle(
                          fontWeight:
                              selectedPage == 'input'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              selectedPage == 'input'
                                  ? Colors.black
                                  : Colors.black54,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // View Students
                GestureDetector(
                  onTap: () {
                    _onPageSelected('table');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TablePage()),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              selectedPage == 'table'
                                  ? const Color.fromARGB(255, 193, 211, 228)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 17,
                        ),
                        child: Icon(
                          Icons.table_chart,
                          color:
                              selectedPage == 'table'
                                  ? Colors.black
                                  : Colors.black54,
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'View Students',
                        style: TextStyle(
                          fontWeight:
                              selectedPage == 'table'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              selectedPage == 'table'
                                  ? Colors.black
                                  : Colors.black54,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Generate QR Code
                GestureDetector(
                  onTap: () {
                    _onPageSelected('qr');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GenerateQrPage()),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              selectedPage == 'qr'
                                  ? const Color.fromARGB(255, 193, 211, 228)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 17,
                        ),
                        child: Icon(
                          Icons.qr_code,
                          color:
                              selectedPage == 'qr'
                                  ? Colors.black
                                  : Colors.black54,
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Generate QR Code',
                        style: TextStyle(
                          fontWeight:
                              selectedPage == 'qr'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              selectedPage == 'qr'
                                  ? Colors.black
                                  : Colors.black54,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Generate Certificate
                GestureDetector(
                  onTap: () {
                    _onPageSelected('certificate');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CertificatePage()),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              selectedPage == 'certificate'
                                  ? const Color.fromARGB(255, 193, 211, 228)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 17,
                        ),
                        child: Icon(
                          Icons.picture_as_pdf,
                          color:
                              selectedPage == 'certificate'
                                  ? Colors.black
                                  : Colors.black54,
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Create Certificate',
                        style: TextStyle(
                          fontWeight:
                              selectedPage == 'certificate'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              selectedPage == 'certificate'
                                  ? Colors.black
                                  : Colors.black54,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '👤 Add Student',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 16),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'First Name',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      _buildTextField(
                                        label: 'First Name',
                                        controller: _firstNameController,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Middle Name',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      _buildTextField(
                                        label: 'Middle Name',
                                        controller: _middleNameController,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Last Name',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      _buildTextField(
                                        label: 'Last Name',
                                        controller: _lastNameController,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Program/Course',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      buildAutoCompleteField(
                                        hint: 'Program/Course',
                                        controller: _programController,
                                        suggestions: programSuggestions,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'School',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      buildAutoCompleteField(
                                        hint: 'School',
                                        controller: _schoolController,
                                        suggestions: schoolSuggestions,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // OJT Hours, Start Date, End Date on the same row
                            Center(
                              child: const Text(
                                'On-the-Job Training Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'OJT Hours',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      buildAutoCompleteField(
                                        hint: 'OJT Hours',
                                        controller: _ojtHoursController,
                                        suggestions: ojtHourSuggestions,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Start Date',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      buildAutoCompleteField(
                                        hint: 'Start Date',
                                        controller: _startDateController,
                                        suggestions: startDateSuggestions,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'End Date',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      buildAutoCompleteField(
                                        hint: 'End Date',
                                        controller: _endDateController,
                                        suggestions: endDateSuggestions,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Office',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      buildAutoCompleteField(
                                        hint: 'Office',
                                        controller: _officeController,
                                        suggestions: officeSuggestions,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Address',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      buildAutoCompleteField(
                                        hint: 'Address',
                                        controller: _addressController,
                                        suggestions: addressSuggestions,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Save Button
                            Center(
                              child: SizedBox(
                                width:
                                    120, // You can adjust the width as needed
                                child: ElevatedButton.icon(
                                  onPressed: _saveStudent,
                                  icon: const Icon(Icons.save, size: 24),
                                  label: const Text(
                                    'Save',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      2,
                                      57,
                                      112,
                                    ), // Modern blue
                                    foregroundColor:
                                        Colors.white, // Text and icon color
                                    elevation: 6,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
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
        ],
      ),
    );
  }
}
