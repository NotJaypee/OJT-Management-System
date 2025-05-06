import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ojt_management_system/pages/home_page.dart';
import 'package:ojt_management_system/pages/input_page.dart';
import 'package:ojt_management_system/utils/word_export.dart';
import 'package:ojt_management_system/pages/table_page.dart';
import 'package:ojt_management_system/pages/certificate_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ojt_management_system/database/db_helper.dart';
import 'package:ojt_management_system/utils/student_model.dart';

class GenerateQrPage extends StatefulWidget {
  const GenerateQrPage({super.key});

  @override
  State<GenerateQrPage> createState() => _GenerateQrPageState();
}

class _GenerateQrPageState extends State<GenerateQrPage> {
  String selectedPage = 'qr'; // Default page is 'home'
  final TextEditingController _driveLinkController = TextEditingController();
  final TextEditingController _programController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();

  final DBHelper dbHelper = DBHelper();

  bool _isDropdownActive = false;

  bool _isGenerating = false;
  String? _statusMessage;
  List<File> _qrFiles = [];

  List<String> _programs = [];
  List<String> _years = [];
  List<String> _schools = [];
  List<Student> students = [];

  String _selectedProgram = 'All';
  String _selectedYear = 'All';
  String _selectedSchool = 'All';

  @override
  void initState() {
    super.initState();
    _loadProgramsYearsSchools();
  }

  void _onPageSelected(String page) {
    setState(() {
      selectedPage = page;
    });
  }

  Future<void> _loadProgramsYearsSchools() async {
    final dbHelper = DBHelper();
    try {
      final programs = await dbHelper.getPrograms();
      final years = await dbHelper.getEndDates(); // List<int>
      final schools = await dbHelper.getSchools();

      final uniqueYears = years.toSet().toList();
      final stringYears = uniqueYears.map((year) => year.toString()).toList();

      final uniqueSchools =
          schools.where((s) => s.trim().isNotEmpty).toSet().toList();

      setState(() {
        _programs = ['All', ...programs];
        _years = ['All', ...stringYears];
        _schools = ['All', ...uniqueSchools];
      });
    } catch (e) {
      setState(() {
        _statusMessage =
            'Error loading programs, years, or schools: ${e.toString()}';
      });
    }
  }

  Future<void> updateStudentQrCode(Student student, String qrLink) async {
    try {
      final db = await DBHelper.database;
      await db.update(
        'students',
        {'qr_link': qrLink},
        where: 'id = ?',
        whereArgs: [student.id],
      );
    } catch (e) {
      print("Error updating QR code for student ${student.id}: $e");
    }
  }

  Future<void> refreshStudentData() async {
    final db = await DBHelper.database;
    final result = await db.query('students');
    setState(() {
      students = result.map((e) => Student.fromMap(e)).toList();
    });
  }

  Future<bool> _generateWordFilesAndQRs() async {
    final driveLink = _driveLinkController.text.trim();

    if (driveLink.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Input Required'),
            content: const Text('Please enter the Google Drive folder link.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop(); // Close the dialog when 'OK' is pressed
                },
              ),
            ],
          );
        },
      );
      return false;
    }

    setState(() {
      _isGenerating = true;
      _statusMessage = null;
      _qrFiles = []; // Clear safely by assigning a new empty list
    });

    try {
      await WordExportService.generateAndUploadGroupedWordFiles(
        context,
        driveLink,
        programFilter: _selectedProgram == 'All' ? null : _selectedProgram,
        yearFilter: _selectedYear == 'All' ? null : _selectedYear,
        schoolFilter: _selectedSchool == 'All' ? null : _selectedSchool,
      );

      final dir = await getApplicationDocumentsDirectory();
      final qrDir = Directory('${dir.path}/qr_codes');
      if (!await qrDir.exists()) await qrDir.create();

      final qrFiles =
          qrDir
              .listSync()
              .whereType<File>()
              .where((file) => file.path.endsWith('.png'))
              .toList();

      setState(() {
        _qrFiles = qrFiles;
      });

      // ✅ Show a SnackBar message instead of setting _statusMessage
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✅ QR Codes and Word files successfully generated and uploaded!',
          ),
          duration: Duration(seconds: 4),
        ),
      );

      return true;
    } catch (e, stackTrace) {
      print("❌ Generation error: $e");
      print(stackTrace);
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
      return false;
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
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

          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '📱 Generate QR Code',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Program:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Autocomplete<String>(
                                  optionsBuilder: (
                                    TextEditingValue textEditingValue,
                                  ) {
                                    if (_isDropdownActive)
                                      return const Iterable<String>.empty();

                                    final List<String> allOptions = _programs;
                                    if (textEditingValue.text == '') {
                                      return allOptions;
                                    }
                                    return allOptions.where((String option) {
                                      return option.toLowerCase().contains(
                                        textEditingValue.text.toLowerCase(),
                                      );
                                    });
                                  },

                                  // Scrollable dropdown
                                  optionsViewBuilder: (
                                    context,
                                    onSelected,
                                    options,
                                  ) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 4,
                                        child: Container(
                                          width: 572, // Dropdown width
                                          constraints: BoxConstraints(
                                            maxHeight:
                                                200, // Set max height to make it scrollable
                                          ),
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            shrinkWrap: true,
                                            itemCount: options.length,
                                            itemBuilder: (
                                              BuildContext context,
                                              int index,
                                            ) {
                                              final option = options.elementAt(
                                                index,
                                              );
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
                                  onSelected: (String selection) {
                                    setState(() {
                                      _selectedProgram = selection;
                                      _programController.text = selection;
                                      _isDropdownActive = false;
                                    });
                                  },
                                  fieldViewBuilder: (
                                    context,
                                    controller,
                                    focusNode,
                                    onEditingComplete,
                                  ) {
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        hintText: 'Select Program',
                                        border: const OutlineInputBorder(),
                                        suffixIcon: Tooltip(
                                          message: 'Show all Programs',
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.arrow_drop_down,
                                            ),
                                            onPressed: () async {
                                              setState(() {
                                                _isDropdownActive = true;
                                              });

                                              FocusScope.of(context).unfocus();
                                              final RenderBox renderBox =
                                                  context.findRenderObject()
                                                      as RenderBox;
                                              final Offset offset = renderBox
                                                  .localToGlobal(Offset.zero);

                                              final String?
                                              selection = await showMenu<
                                                String
                                              >(
                                                context: context,
                                                position: RelativeRect.fromLTRB(
                                                  offset.dx,
                                                  offset.dy +
                                                      renderBox.size.height,
                                                  offset.dx +
                                                      renderBox.size.width -
                                                      50,
                                                  offset.dy +
                                                      renderBox.size.height,
                                                ),
                                                items:
                                                    _programs.map((
                                                      String option,
                                                    ) {
                                                      return PopupMenuItem<
                                                        String
                                                      >(
                                                        value: option,
                                                        child: SizedBox(
                                                          width:
                                                              renderBox
                                                                  .size
                                                                  .width,
                                                          child: Text(option),
                                                        ),
                                                      );
                                                    }).toList(),
                                              );

                                              if (selection != null) {
                                                setState(() {
                                                  _selectedProgram = selection;
                                                  controller.text = selection;
                                                  _isDropdownActive = false;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      onEditingComplete: onEditingComplete,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Year:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Autocomplete<String>(
                                  optionsBuilder: (
                                    TextEditingValue textEditingValue,
                                  ) {
                                    if (_isDropdownActive)
                                      return const Iterable<String>.empty();

                                    final List<String> allOptions = _years;
                                    if (textEditingValue.text == '') {
                                      return allOptions;
                                    }
                                    return allOptions.where((String option) {
                                      return option.toLowerCase().contains(
                                        textEditingValue.text.toLowerCase(),
                                      );
                                    });
                                  },
                                  optionsViewBuilder: (
                                    context,
                                    onSelected,
                                    options,
                                  ) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 4,
                                        child: Container(
                                          width: 572,
                                          constraints: const BoxConstraints(
                                            maxHeight:
                                                200, // 👈 Added to make Autocomplete scrollable
                                          ),
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            shrinkWrap: true,
                                            itemCount: options.length,
                                            itemBuilder: (
                                              BuildContext context,
                                              int index,
                                            ) {
                                              final option = options.elementAt(
                                                index,
                                              );
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
                                  onSelected: (String selection) {
                                    setState(() {
                                      _selectedYear = selection;
                                      _yearController.text = selection;
                                      _isDropdownActive = false;
                                    });
                                  },
                                  fieldViewBuilder: (
                                    context,
                                    controller,
                                    focusNode,
                                    onEditingComplete,
                                  ) {
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        hintText: 'Select Year',
                                        border: const OutlineInputBorder(),
                                        suffixIcon: Tooltip(
                                          message: 'Show all Years',
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.arrow_drop_down,
                                            ),
                                            onPressed: () async {
                                              setState(() {
                                                _isDropdownActive = true;
                                              });

                                              FocusScope.of(context).unfocus();
                                              final RenderBox renderBox =
                                                  context.findRenderObject()
                                                      as RenderBox;
                                              final Offset offset = renderBox
                                                  .localToGlobal(Offset.zero);

                                              final String?
                                              selection = await showMenu<
                                                String
                                              >(
                                                context: context,
                                                position: RelativeRect.fromLTRB(
                                                  offset.dx,
                                                  offset.dy +
                                                      renderBox.size.height,
                                                  offset.dx +
                                                      renderBox.size.width -
                                                      50,
                                                  offset.dy +
                                                      renderBox.size.height,
                                                ),
                                                items:
                                                    _years.map((String option) {
                                                      return PopupMenuItem<
                                                        String
                                                      >(
                                                        value: option,
                                                        child: SizedBox(
                                                          width:
                                                              renderBox
                                                                  .size
                                                                  .width,
                                                          child: Text(option),
                                                        ),
                                                      );
                                                    }).toList(),
                                              );

                                              if (selection != null) {
                                                setState(() {
                                                  _selectedYear = selection;
                                                  controller.text = selection;
                                                  _isDropdownActive = false;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      onEditingComplete: onEditingComplete,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 1, // Allow School to expand properly
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'School:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 570, // Maximum width
                                    minWidth: 300, // Optional: minimum width
                                  ),
                                  child: Autocomplete<String>(
                                    optionsBuilder: (
                                      TextEditingValue textEditingValue,
                                    ) {
                                      if (_isDropdownActive)
                                        return const Iterable<String>.empty();
                                      final List<String> allOptions = _schools;
                                      if (textEditingValue.text.isEmpty) {
                                        return allOptions;
                                      }
                                      return allOptions.where((String option) {
                                        return option.toLowerCase().contains(
                                          textEditingValue.text.toLowerCase(),
                                        );
                                      });
                                    },
                                    optionsViewBuilder: (
                                      context,
                                      onSelected,
                                      options,
                                    ) {
                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Material(
                                          elevation: 4,
                                          color:
                                              Colors
                                                  .white, // White background for contrast
                                          child: Container(
                                            width:
                                                572, // Width for the dropdown
                                            constraints: const BoxConstraints(
                                              maxHeight:
                                                  200, // Ensure dropdown is scrollable
                                            ),
                                            child: ListView.builder(
                                              padding: EdgeInsets.zero,
                                              shrinkWrap: true,
                                              itemCount: options.length,
                                              itemBuilder: (
                                                BuildContext context,
                                                int index,
                                              ) {
                                                final option = options
                                                    .elementAt(index);
                                                return ListTile(
                                                  title: Text(
                                                    option,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                    ), // Adjust font size for clarity
                                                  ),
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
                                    onSelected: (String selection) {
                                      setState(() {
                                        _selectedSchool = selection;
                                        _schoolController.text = selection;
                                        _isDropdownActive = false;
                                      });
                                    },
                                    fieldViewBuilder: (
                                      context,
                                      controller,
                                      focusNode,
                                      onEditingComplete,
                                    ) {
                                      return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        decoration: InputDecoration(
                                          hintText: 'Select School',
                                          border: const OutlineInputBorder(),
                                          suffixIcon: Tooltip(
                                            message: 'Show all Schools',
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.arrow_drop_down,
                                              ),
                                              onPressed: () async {
                                                setState(() {
                                                  _isDropdownActive = true;
                                                });

                                                FocusScope.of(
                                                  context,
                                                ).unfocus();
                                                final RenderBox renderBox =
                                                    context.findRenderObject()
                                                        as RenderBox;
                                                final Offset offset = renderBox
                                                    .localToGlobal(Offset.zero);

                                                final String?
                                                selection = await showMenu<
                                                  String
                                                >(
                                                  context: context,
                                                  position:
                                                      RelativeRect.fromLTRB(
                                                        offset.dx,
                                                        offset.dy +
                                                            renderBox
                                                                .size
                                                                .height,
                                                        offset.dx +
                                                            renderBox
                                                                .size
                                                                .width -
                                                            50,
                                                        offset.dy +
                                                            renderBox
                                                                .size
                                                                .height,
                                                      ),
                                                  items:
                                                      _schools.map((
                                                        String option,
                                                      ) {
                                                        return PopupMenuItem<
                                                          String
                                                        >(
                                                          value: option,
                                                          child: SizedBox(
                                                            width:
                                                                renderBox
                                                                    .size
                                                                    .width,
                                                            child: Text(option),
                                                          ),
                                                        );
                                                      }).toList(),
                                                );

                                                if (selection != null) {
                                                  setState(() {
                                                    _selectedSchool = selection;
                                                    controller.text = selection;
                                                    _isDropdownActive = false;
                                                  });
                                                } else {
                                                  setState(() {
                                                    _isDropdownActive =
                                                        false; // Reset when closing without selection
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                        onEditingComplete: onEditingComplete,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Invisible Expanded widget
                          Expanded(
                            flex: 1,
                            child:
                                SizedBox(), // Empty widget to balance the Row
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        'Paste the Google Drive Folder Link:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150.0, // Set the desired width here
                        child: TextField(
                          controller: _driveLinkController,
                          decoration: const InputDecoration(
                            hintText: 'https://drive.google.com/folder/...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center, // Center the button
                        children: [
                          SizedBox(
                            width:
                                320, // Adjust the width as per your requirement
                            child: SizedBox(
                              width: 300,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isGenerating
                                        ? null
                                        : () async {
                                          setState(() {
                                            _isGenerating = true;
                                            _statusMessage = null;
                                          });

                                          try {
                                            _qrFiles.clear();

                                            bool generationSuccess =
                                                await _generateWordFilesAndQRs();

                                            if (generationSuccess) {
                                              for (Student student
                                                  in students) {
                                                if (student.qrLink != null &&
                                                    student
                                                        .qrLink!
                                                        .isNotEmpty) {
                                                  await updateStudentQrCode(
                                                    student,
                                                    student.qrLink!,
                                                  );
                                                  print(
                                                    "✅ Updated QR code for student: ${student.firstName} ${student.lastName}",
                                                  );
                                                }
                                              }

                                              await refreshStudentData();
                                              print(
                                                "✅ Student list refreshed successfully.",
                                              );

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "QR Codes and Word files generated and uploaded successfully!",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  backgroundColor: Colors.green,
                                                  duration: Duration(
                                                    seconds: 3,
                                                  ),
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "Failed to generate QR Codes and Word files.",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  backgroundColor: Colors.red,
                                                  duration: Duration(
                                                    seconds: 3,
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e, stack) {
                                            print(
                                              "❌ Error generating files: $e",
                                            );
                                            print(stack);
                                            setState(() {
                                              _statusMessage =
                                                  "Failed to Generate";
                                            });

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "An error occurred while generating files.",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                backgroundColor: Colors.red,
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                          } finally {
                                            setState(() {
                                              _isGenerating = false;
                                            });
                                          }
                                        },
                                icon: const Icon(Icons.qr_code, size: 24),
                                label: const Text(
                                  'Generate QR Codes and Word Files',
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
                                  ),
                                  foregroundColor: Colors.white,
                                  elevation: 6,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          if (_statusMessage != null) ...[
                            const SizedBox(height: 20),
                            Text(
                              _statusMessage!,
                              style: TextStyle(
                                color:
                                    _statusMessage == 'Failed to Generate'
                                        ? Colors.red
                                        : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          if (_qrFiles.isNotEmpty) ...[
                            const Text(
                              'Generated QR Codes:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            for (var qrFile in _qrFiles) ...[
                              Image.file(qrFile),
                              const SizedBox(height: 10),
                            ],
                          ],
                        ],
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
