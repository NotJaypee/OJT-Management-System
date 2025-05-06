import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ojt_management_system/database/db_helper.dart';
import 'package:ojt_management_system/pages/certificate_page.dart';
import 'package:ojt_management_system/pages/generate_qr_page.dart';
import 'package:ojt_management_system/pages/home_page.dart';
import 'package:ojt_management_system/pages/input_page.dart';
import 'package:ojt_management_system/utils/export_database.dart';
import 'package:ojt_management_system/utils/import_database.dart';
import 'package:ojt_management_system/utils/student_model.dart'; // Ensure this import is correct
import 'package:ojt_management_system/utils/edit_student_page.dart';
import 'package:ojt_management_system/utils/generate_report_dialog.dart';
import 'package:intl/intl.dart';
import 'package:ojt_management_system/utils/update_database.dart';

class TablePage extends StatefulWidget {
  @override
  _TablePageState createState() => _TablePageState();
}

class _TablePageState extends State<TablePage> {
  // A list to hold student data fetched from the database
  Timer? _debounce;
  List<Student> students = [];
  List<Student> allStudents = []; // Full list
  List<Student> filteredStudents = []; // The list shown in the table
  // The current search query
  String selectedPage = 'table';
  String? selectedYear = 'All';
  List<String> availableYears = [];
  String searchQuery = '';
  String? selectedProgram = 'All';
  String? selectedSchool = 'All';
  String? selectedOffice = 'All';

  final dbHelper = DBHelper(); // create instance

  @override
  void initState() {
    super.initState();
    loadStudents(); // assuming this fetches students and setsState
    _fetchAndExtractYears();
    _debounce?.cancel();
  }

  // Update the selected page
  void _onPageSelected(String page) {
    setState(() {
      selectedPage = page;
    });
  }

  // Fetch distinct years from the DB
  void _fetchAndExtractYears() async {
    List<String> years =
        await DBHelper.getDistinctYears(); // Use instance method
    setState(() {
      availableYears = years; // Set available years
    });
  }

  // This function loads students from the database
  Future<void> loadStudents() async {
    final result = await DBHelper.getAllStudents(); // Fetching from DB

    // Debug statement to print the result
    print("Loaded students: ${result.toString()}");

    // Ensure the widget is still mounted before calling setState
    if (!mounted) return;

    setState(() {
      students = result;
      allStudents = List.from(
        result,
      ); // Initialize allStudents with the full list
      filteredStudents = List.from(
        result,
      ); // Initialize filteredStudents with the full list
    });

    // Apply the current filter after loading the students
    _applyFilter(); // Custom method to apply the current filter (if any)
  }

  void _applyFilter() {
    setState(() {
      filteredStudents =
          allStudents.where((student) {
            // 1. Name filter
            final matchesName =
                searchQuery.isEmpty ||
                student.firstName.toLowerCase().contains(searchQuery) ||
                student.lastName.toLowerCase().contains(searchQuery);

            // 2. Program filter
            final matchesProgram =
                selectedProgram == null ||
                selectedProgram == 'All' ||
                student.program == selectedProgram;

            // 3. School filter
            final matchesSchool =
                selectedSchool == null ||
                selectedSchool == 'All' ||
                student.school == selectedSchool;

            // 4. Office filter
            final matchesOffice =
                selectedOffice == null ||
                selectedOffice == 'All' ||
                student.office == selectedOffice;

            // 5. Year filter (based on parsed end date)
            bool matchesYear = true;
            if (selectedYear != null && selectedYear != 'All') {
              try {
                final parsedDate = DateFormat(
                  "MMMM d, yyyy",
                ).parse(student.endDate);
                matchesYear = parsedDate.year.toString() == selectedYear;
              } catch (e) {
                matchesYear = false; // Skip if no valid date
              }
            }

            // Return only students who match all filters
            return matchesName &&
                matchesProgram &&
                matchesSchool &&
                matchesOffice &&
                matchesYear;
          }).toList();
    });
  }

  // This method is triggered when the user types in the search bar
  void onSearchQueryChanged(String query) {
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel(); // Cancel the previous debounce
    }
    _debounce = Timer(const Duration(milliseconds: 498), () {
      setState(() {
        searchQuery = query.toLowerCase(); // Update search query after debounce
        _applyFilter(); // Apply the filters
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Container (OJT Menu)
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

          // Right Side - Data Table
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '📊 On-the-Job Training Students Table',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PopupMenuButton<int>(
                            icon: Icon(Icons.apps),
                            onSelected: (value) async {
                              if (value == 1) {
                                // Fetch dynamic options
                                final programOptions =
                                    await DBHelper.getDistinctPrograms();
                                final schoolOptions =
                                    await DBHelper.getDistinctSchools();
                                final yearOptions =
                                    await DBHelper.getDistinctYears();

                                // Show the dialog with the fetched data
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => GenerateReportDialog(
                                        programOptions: programOptions,
                                        schoolOptions: schoolOptions,
                                        yearOptions: yearOptions,
                                      ),
                                );
                              } else if (value == 2) {
                                print("Import Database clicked");

                                // Call the import function
                                await importFromCSV(context);

                                // Reload the students after import if this method exists
                                if (mounted) {
                                  await loadStudents(); // This should be inside a StatefulWidget with loadStudents defined
                                }
                              } else if (value == 3) {
                                // Call the export function to export the database data to CSV
                                exportToCSV(context);
                              } else if (value == 4) {
                                print("Update Database clicked");

                                // Call the update database function
                                pickFileAndUpdateDatabase(context);
                              }
                            },
                            itemBuilder:
                                (BuildContext context) => <PopupMenuEntry<int>>[
                                  PopupMenuItem<int>(
                                    value: 1,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.description,
                                          color: Colors.black54,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Generate Report'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<int>(
                                    value: 2,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.file_upload,
                                          color: Colors.black54,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Import Database'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<int>(
                                    value: 3,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.file_download,
                                          color: Colors.black54,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Export Database'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<int>(
                                    value: 4,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.update,
                                          color: Colors.black54,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Update Database'),
                                      ],
                                    ),
                                  ),
                                ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Search by Name',
                          hintText: 'Enter First or Last Name',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          onSearchQueryChanged(
                            value,
                          ); // use the debounced search method
                        },
                      ),
                      const SizedBox(height: 10),

                      Expanded(
                        // <-- Add Expanded or Flexible above
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Table(
                                border: TableBorder.all(color: Colors.black),
                                children: [
                                  /// 🔠 Header Row
                                  TableRow(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                    children: [
                                      IntrinsicWidth(
                                        child: Container(
                                          width: 100.0,
                                          padding: const EdgeInsets.all(8.0),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Name',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IntrinsicWidth(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            children: [
                                              Text(
                                                'Program',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: FutureBuilder<
                                                  List<String>
                                                >(
                                                  future:
                                                      DBHelper.getDistinctPrograms(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return SizedBox(
                                                        height: 20,
                                                        width: 50,
                                                      );
                                                    } else if (snapshot
                                                        .hasError) {
                                                      return Text('Error');
                                                    } else if (snapshot
                                                            .hasData &&
                                                        snapshot
                                                            .data!
                                                            .isNotEmpty) {
                                                      return DropdownButtonHideUnderline(
                                                        child: DropdownButton<
                                                          String
                                                        >(
                                                          value:
                                                              selectedProgram,
                                                          icon: Icon(
                                                            Icons
                                                                .arrow_drop_down,
                                                          ),
                                                          isDense: true,
                                                          isExpanded: true,
                                                          onChanged: (
                                                            newProgram,
                                                          ) {
                                                            setState(() {
                                                              selectedProgram =
                                                                  newProgram;
                                                            });
                                                            _applyFilter(); // Apply the filter after selection
                                                          },
                                                          selectedItemBuilder: (
                                                            BuildContext
                                                            context,
                                                          ) {
                                                            return <String>[
                                                              'All',
                                                              ...[
                                                                ...snapshot
                                                                      .data!
                                                                  ..sort(),
                                                              ],
                                                            ].map<Widget>((
                                                              String value,
                                                            ) {
                                                              return SizedBox.shrink(); // Hide selected text
                                                            }).toList();
                                                          },
                                                          items:
                                                              <String>[
                                                                'All',
                                                                ...[
                                                                  ...snapshot
                                                                        .data!
                                                                    ..sort(),
                                                                ],
                                                              ].map<
                                                                DropdownMenuItem<
                                                                  String
                                                                >
                                                              >((String value) {
                                                                String
                                                                displayValue =
                                                                    value.length >
                                                                            35
                                                                        ? '${value.substring(0, 35)}...'
                                                                        : value;

                                                                return DropdownMenuItem<
                                                                  String
                                                                >(
                                                                  value: value,
                                                                  child: Text(
                                                                    displayValue,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    maxLines: 2,
                                                                  ),
                                                                );
                                                              }).toList(),

                                                          // Make the dropdown menu scrollable
                                                          menuMaxHeight:
                                                              300, // Set max height for the dropdown menu
                                                        ),
                                                      );
                                                    } else {
                                                      return Text('No data');
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      IntrinsicWidth(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            children: [
                                              Text(
                                                'School',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: FutureBuilder<
                                                  List<String>
                                                >(
                                                  future:
                                                      DBHelper.getDistinctSchools(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return SizedBox(
                                                        height: 20,
                                                        width: 50,
                                                      );
                                                    } else if (snapshot
                                                        .hasError) {
                                                      return Text('Error');
                                                    } else if (snapshot
                                                            .hasData &&
                                                        snapshot
                                                            .data!
                                                            .isNotEmpty) {
                                                      return DropdownButtonHideUnderline(
                                                        child: DropdownButton<
                                                          String
                                                        >(
                                                          value:
                                                              selectedSchool ==
                                                                      'All'
                                                                  ? null
                                                                  : selectedSchool,
                                                          icon: Icon(
                                                            Icons
                                                                .arrow_drop_down,
                                                          ),
                                                          isDense: true,
                                                          isExpanded: true,
                                                          onChanged: (
                                                            newSchool,
                                                          ) {
                                                            setState(() {
                                                              selectedSchool =
                                                                  newSchool;
                                                            });
                                                            _applyFilter(); // Apply the filter after selection
                                                          },
                                                          selectedItemBuilder: (
                                                            BuildContext
                                                            context,
                                                          ) {
                                                            return <String>[
                                                              'All',
                                                              ...[
                                                                ...snapshot
                                                                      .data!
                                                                  ..sort(),
                                                              ],
                                                            ].map<Widget>((
                                                              String value,
                                                            ) {
                                                              return SizedBox.shrink(); // Hide selected text
                                                            }).toList();
                                                          },
                                                          items:
                                                              <String>[
                                                                'All',
                                                                ...[
                                                                  ...snapshot
                                                                        .data!
                                                                    ..sort(),
                                                                ],
                                                              ].map<
                                                                DropdownMenuItem<
                                                                  String
                                                                >
                                                              >((String value) {
                                                                String
                                                                displayValue =
                                                                    value.length >
                                                                            35
                                                                        ? '${value.substring(0, 35)}...'
                                                                        : value;

                                                                return DropdownMenuItem<
                                                                  String
                                                                >(
                                                                  value: value,
                                                                  child: Text(
                                                                    displayValue,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    maxLines: 2,
                                                                  ),
                                                                );
                                                              }).toList(),

                                                          // Make the dropdown menu scrollable
                                                          menuMaxHeight:
                                                              300, // Set max height for the dropdown menu
                                                        ),
                                                      );
                                                    } else {
                                                      return Text('No data');
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      IntrinsicWidth(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            children: [
                                              Text(
                                                'Office',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: FutureBuilder<
                                                  List<String>
                                                >(
                                                  future:
                                                      DBHelper.getDistinctOffices(), // Replace with your method that fetches office names
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return SizedBox(
                                                        height: 20,
                                                        width: 50,
                                                      );
                                                    } else if (snapshot
                                                        .hasError) {
                                                      return Text('Error');
                                                    } else if (snapshot
                                                            .hasData &&
                                                        snapshot
                                                            .data!
                                                            .isNotEmpty) {
                                                      return DropdownButtonHideUnderline(
                                                        child: DropdownButton<
                                                          String
                                                        >(
                                                          value:
                                                              selectedOffice ==
                                                                      'All'
                                                                  ? null
                                                                  : selectedOffice,
                                                          icon: Icon(
                                                            Icons
                                                                .arrow_drop_down,
                                                          ),
                                                          isDense: true,
                                                          isExpanded:
                                                              true, // Ensures full width is used
                                                          onChanged: (
                                                            newOffice,
                                                          ) {
                                                            selectedOffice =
                                                                newOffice;
                                                            _applyFilter(); // Apply filter logic
                                                          },
                                                          selectedItemBuilder: (
                                                            BuildContext
                                                            context,
                                                          ) {
                                                            return <String>[
                                                              'All',
                                                              ...[
                                                                ...snapshot
                                                                      .data!
                                                                  ..sort(),
                                                              ],
                                                            ].map<Widget>((
                                                              String value,
                                                            ) {
                                                              return SizedBox.shrink(); // Hide selected text
                                                            }).toList();
                                                          },
                                                          items:
                                                              <String>[
                                                                'All',
                                                                ...[
                                                                  ...snapshot
                                                                        .data!
                                                                    ..sort(),
                                                                ],
                                                              ].map<
                                                                DropdownMenuItem<
                                                                  String
                                                                >
                                                              >((String value) {
                                                                String
                                                                displayValue =
                                                                    value.length >
                                                                            35
                                                                        ? '${value.substring(0, 35)}...'
                                                                        : value;

                                                                return DropdownMenuItem<
                                                                  String
                                                                >(
                                                                  value: value,
                                                                  child: Text(
                                                                    displayValue,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    maxLines: 2,
                                                                  ),
                                                                );
                                                              }).toList(),

                                                          // Make the dropdown menu scrollable
                                                          menuMaxHeight:
                                                              300, // Set max height for the dropdown menu
                                                        ),
                                                      );
                                                    } else {
                                                      return Text('No data');
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      IntrinsicWidth(
                                        child: Container(
                                          width: 120.0,
                                          padding: const EdgeInsets.all(8.0),
                                          alignment: Alignment.center,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Year',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              FutureBuilder<List<String>>(
                                                future:
                                                    DBHelper.getDistinctYears(),
                                                builder: (context, snapshot) {
                                                  if (snapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return SizedBox();
                                                  } else if (snapshot
                                                      .hasError) {
                                                    return Text(
                                                      'Error: ${snapshot.error}',
                                                    );
                                                  } else if (snapshot.hasData &&
                                                      snapshot
                                                          .data!
                                                          .isNotEmpty) {
                                                    return DropdownButtonHideUnderline(
                                                      child: Container(
                                                        width:
                                                            80, // Make dropdown menu wider
                                                        child: DropdownButton<
                                                          String
                                                        >(
                                                          value: selectedYear,
                                                          icon: Icon(
                                                            Icons
                                                                .arrow_drop_down,
                                                          ),
                                                          isDense: true,
                                                          onChanged: (newYear) {
                                                            selectedYear =
                                                                newYear;
                                                            _applyFilter(); // instead of _applyProgramFilter
                                                          },
                                                          selectedItemBuilder: (
                                                            BuildContext
                                                            context,
                                                          ) {
                                                            return <String>[
                                                              'All',
                                                              ...snapshot.data!,
                                                            ].map<Widget>((
                                                              String value,
                                                            ) {
                                                              return SizedBox.shrink(); // Hides selected text
                                                            }).toList();
                                                          },
                                                          items:
                                                              <String>[
                                                                'All',
                                                                ...snapshot
                                                                    .data!,
                                                              ].map<
                                                                DropdownMenuItem<
                                                                  String
                                                                >
                                                              >((String value) {
                                                                return DropdownMenuItem<
                                                                  String
                                                                >(
                                                                  value: value,
                                                                  child: Container(
                                                                    width:
                                                                        100, // Adjust this width as needed
                                                                    child: Text(
                                                                      value,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                );
                                                              }).toList(),
                                                          menuMaxHeight:
                                                              300, // Set max height for the dropdown menu to make it scrollable
                                                        ),
                                                      ),
                                                    );
                                                  } else {
                                                    return Text(
                                                      'No data available',
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  /// 🧑‍🎓 Student Rows or No Data Message
                                  if (filteredStudents.isEmpty)
                                    TableRow(
                                      children: [
                                        TableCell(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            alignment: Alignment.center,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                            ),
                                            child: Text(
                                              'No data available',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ),
                                        for (int i = 0; i < 4; i++)
                                          const TableCell(
                                            child: SizedBox.shrink(),
                                          ),
                                      ],
                                    ),

                                  ...(filteredStudents.toList()..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0))).map((
                                    student,
                                  ) {
                                    final fullName =
                                        '${student.firstName} '
                                        '${student.middleInitial.isNotEmpty ? '${student.middleInitial}. ' : ''}'
                                        '${student.lastName}';

                                    // Parse and extract year from end_date
                                    String year = '';
                                    try {
                                      final parsedDate = DateFormat(
                                        "MMMM d, yyyy",
                                      ).parse(student.endDate);
                                      year = parsedDate.year.toString();
                                    } catch (e) {
                                      year =
                                          '—'; // Fallback in case of parse error
                                    }

                                    return TableRow(
                                      children: [
                                        IntrinsicWidth(
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Container(
                                              width:
                                                  120.0, // Adjust this value to control the width
                                              child: InkWell(
                                                onTap: () async {
                                                  await showDialog(
                                                    context: context,
                                                    builder: (
                                                      BuildContext context,
                                                    ) {
                                                      return EditStudentDialog(
                                                        student: student,
                                                        onSave: (
                                                          updatedStudent,
                                                        ) async {
                                                          await DBHelper.updateStudent(
                                                            updatedStudent,
                                                          ); // Save to DB
                                                          await loadStudents(); // Reload all students

                                                          // Reapply filter to keep the search results consistent
                                                          _applyFilter(); // Apply the filter after update
                                                        },
                                                        onDelete: () async {
                                                          await DBHelper.deleteStudent(
                                                            student.id!,
                                                          ); // Delete from DB
                                                          await loadStudents(); // Reload all students

                                                          // Reapply filter to keep the search results consistent
                                                          _applyFilter(); // Apply the filter after delete
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                                child: Text(
                                                  fullName,
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        IntrinsicWidth(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Container(
                                              width:
                                                  180.0, // Set width for the program column
                                              child: InkWell(
                                                onTap: () async {
                                                  await showDialog(
                                                    context: context,
                                                    builder: (
                                                      BuildContext context,
                                                    ) {
                                                      return EditStudentDialog(
                                                        student: student,
                                                        onSave: (
                                                          updatedStudent,
                                                        ) async {
                                                          await DBHelper.updateStudent(
                                                            updatedStudent,
                                                          ); // Save to DB
                                                          await loadStudents(); // Reload all students

                                                          // Reapply filter to keep the search results consistent
                                                          _applyFilter(); // Apply the filter after update
                                                        },
                                                        onDelete: () async {
                                                          await DBHelper.deleteStudent(
                                                            student.id!,
                                                          ); // Delete from DB
                                                          await loadStudents(); // Reload all students

                                                          // Reapply filter to keep the search results consistent
                                                          _applyFilter(); // Apply the filter after delete
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                                child: Text(
                                                  student.program,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        IntrinsicWidth(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Container(
                                              width:
                                                  80.0, // Set width for the school column
                                              child: InkWell(
                                                onTap: () async {
                                                  await showDialog(
                                                    context: context,
                                                    builder: (
                                                      BuildContext context,
                                                    ) {
                                                      return EditStudentDialog(
                                                        student: student,
                                                        onSave: (
                                                          updatedStudent,
                                                        ) async {
                                                          await DBHelper.updateStudent(
                                                            updatedStudent,
                                                          ); // Save to DB
                                                          await loadStudents(); // Reload all students

                                                          // Reapply filter to keep the search results consistent
                                                          _applyFilter(); // Apply the filter after update
                                                        },
                                                        onDelete: () async {
                                                          await DBHelper.deleteStudent(
                                                            student.id!,
                                                          ); // Delete from DB
                                                          await loadStudents(); // Reload all students

                                                          // Reapply filter to keep the search results consistent
                                                          _applyFilter(); // Apply the filter after delete
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                                child: Text(
                                                  student.school,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        IntrinsicWidth(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Container(
                                              width:
                                                  80.0, // Set width for the office column
                                              child: InkWell(
                                                onTap: () async {
                                                  await showDialog(
                                                    context: context,
                                                    builder: (
                                                      BuildContext context,
                                                    ) {
                                                      return EditStudentDialog(
                                                        student: student,
                                                        onSave: (
                                                          updatedStudent,
                                                        ) async {
                                                          await DBHelper.updateStudent(
                                                            updatedStudent,
                                                          ); // Save to DB
                                                          await loadStudents(); // Reload all students

                                                          // Reapply filter to keep the search results consistent
                                                          _applyFilter(); // Apply the filter after update
                                                        },
                                                        onDelete: () async {
                                                          await DBHelper.deleteStudent(
                                                            student.id!,
                                                          ); // Delete from DB
                                                          await loadStudents(); // Reload all students

                                                          // Reapply filter to keep the search results consistent
                                                          _applyFilter(); // Apply the filter after delete
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                                child: Text(
                                                  student.office,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        IntrinsicWidth(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 10,
                                              top: 8,
                                            ),
                                            child: Container(
                                              width:
                                                  80.0, // Set width for the year column
                                              child: InkWell(
                                                onTap: () async {
                                                  await showDialog(
                                                    context: context,
                                                    builder: (
                                                      BuildContext context,
                                                    ) {
                                                      return EditStudentDialog(
                                                        student: student,
                                                        onSave: (
                                                          updatedStudent,
                                                        ) async {
                                                          await DBHelper.updateStudent(
                                                            updatedStudent,
                                                          ); // Save to DB
                                                          await loadStudents(); // Reload all students

                                                          // Reapply filter to keep the search results consistent
                                                          _applyFilter(); // Apply the filter after update
                                                        },
                                                        onDelete: () async {
                                                          await DBHelper.deleteStudent(
                                                            student.id!,
                                                          ); // Delete from DB
                                                          await loadStudents(); // Reload all students

                                                          // Reapply filter to keep the search results consistent
                                                          _applyFilter(); // Apply the filter after delete
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                                child: Text(year),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
