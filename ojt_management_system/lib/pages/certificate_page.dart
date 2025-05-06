import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:ojt_management_system/database/db_helper.dart'; // Import your DBHelper
import 'package:ojt_management_system/pages/generate_qr_page.dart';
import 'package:ojt_management_system/pages/home_page.dart';
import 'package:ojt_management_system/pages/input_page.dart';
import 'package:ojt_management_system/pages/pdf_viewer_page.dart';
import 'package:ojt_management_system/pages/table_page.dart';
import 'package:ojt_management_system/utils/student_model.dart'; // Import your Student model
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class CertificatePage extends StatefulWidget {
  const CertificatePage({super.key});

  @override
  _CertificatePageState createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  String selectedPage = 'certificate';
  String? pdfPath;
  bool selectAll = false;
  List<Student> students = [];
  List<Student> filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();

  List<String> programList = ['All'];
  List<String> filteredPrograms = ['All'];
  List<String> programs = [];
  List<String> allPrograms = [];
  List<String> allSchools = ['All'];
  String selectedProgram = 'All';
  String? selectedYear = 'All';
  late List<String> availableYears;
  String selectedSchool = 'All';

  bool isLoadingPrograms = true;

  late pw.Font regularFont;
  late pw.Font boldFont;
  late pw.Font italicFont;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _onSearchChanged();
    _loadStudentData(); // Load student data
    _loadPrograms(); // Load program data from the database// Attach listener for search input
    _loadFonts(); // Load fonts for PDF generation
    availableYears = getAvailableYears(students);
  }

  void _onPageSelected(String page) {
    setState(() {
      selectedPage = page;
    });
  }

  String convertHoursToWords(int hours) {
    final wordsMap = {
      0: 'ZERO',
      1: 'ONE',
      2: 'TWO',
      3: 'THREE',
      4: 'FOUR',
      5: 'FIVE',
      6: 'SIX',
      7: 'SEVEN',
      8: 'EIGHT',
      9: 'NINE',
      10: 'TEN',
      11: 'ELEVEN',
      12: 'TWELVE',
      13: 'THIRTEEN',
      14: 'FOURTEEN',
      15: 'FIFTEEN',
      16: 'SIXTEEN',
      17: 'SEVENTEEN',
      18: 'EIGHTEEN',
      19: 'NINETEEN',
      20: 'TWENTY',
      30: 'THIRTY',
      40: 'FORTY',
      50: 'FIFTY',
      60: 'SIXTY',
      70: 'SEVENTY',
      80: 'EIGHTY',
      90: 'NINETY',
    };

    if (hours < 0 || hours >= 1000) {
      return '$hours HOURS'; // Fallback for out-of-range
    }

    if (hours == 0) {
      return '${wordsMap[0]} (0)';
    }

    String words = '';

    int hundreds = hours ~/ 100;
    int remainder = hours % 100;

    if (hundreds > 0) {
      words += '${wordsMap[hundreds]} HUNDRED';
      if (remainder > 0) {
        words += ' ';
      }
    }

    if (remainder > 0) {
      if (remainder <= 20 || wordsMap.containsKey(remainder)) {
        words += '${wordsMap[remainder]}';
      } else {
        int tens = (remainder ~/ 10) * 10;
        int ones = remainder % 10;
        words += wordsMap[tens]!;
        if (ones > 0) {
          words += '-${wordsMap[ones]}';
        }
      }
    }

    return '$words ($hours)';
  }

  String getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  // Function to format the date with suffix
  String formatDateWithSuffix(DateTime date) {
    String suffix;
    int day = date.day;

    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
          break;
      }
    }

    // Output: "24th day of February 2025"
    return '$day$suffix day of ${getMonthName(date.month)} ${date.year}';
  }

  DateTime parseDate(String dateStr) {
    try {
      // Use DateFormat to parse dates in the format like "May 20, 2025"
      return DateFormat(
        'MMMM dd, yyyy',
      ).parse(dateStr); // Month day, year (e.g., May 20, 2025)
    } catch (e) {
      // If parsing fails, return a default value (optional)
      print('Error parsing date: $e');
      return DateTime.now(); // Default to current date if parsing fails
    }
  }

  // Load student data from the database
  _loadStudentData() async {
    // Fetch students from the database
    List<Student> studentData = await DBHelper.getAllStudents();
    print("✅ Loaded students: $studentData");

    // Populate the list of schools after loading the students
    _loadSchools(studentData);

    setState(() {
      students = studentData;
      filteredStudents = studentData; // Show all students initially
      availableYears = getAvailableYears(
        studentData,
      ); // Extract available years
    });
  }

  void _loadSchools(List<Student> studentData) {
    // Collect all unique school names from students
    final schools = studentData.map((student) => student.school).toSet();

    // Debugging: Check the schools extracted from students
    print("✅ Extracted schools: $schools");

    // If schools are found, add them to the list; otherwise, use 'All'
    allSchools = ['All', ...schools.toList()];

    // Debugging: Print the final allSchools list
    print("✅ allSchools updated: $allSchools");

    // Update the UI
    setState(() {});
  }

  Future<void> _loadPrograms() async {
    final fetched = await DBHelper.getAllPrograms();
    setState(() {
      allPrograms = fetched.toSet().toList();
      allPrograms.remove('All');
      allPrograms.insert(0, 'All');
    });
  }

  // Load fonts
  Future<void> _loadFonts() async {
    try {
      regularFont = pw.Font.ttf(
        await rootBundle.load('assets/fonts/times_new_roman.ttf'),
      );
      boldFont = pw.Font.ttf(
        await rootBundle.load('assets/fonts/times_new_roman_bold.ttf'),
      );
      italicFont = pw.Font.ttf(
        await rootBundle.load('assets/fonts/times_new_roman_italic.ttf'),
      );
      print("Fonts loaded successfully.");
    } catch (e) {
      print("Error loading fonts: $e");
    }
  }

  // Function to pick PDF template
  Future<bool> pickTemplate() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        pdfPath = result.files.single.path;
      });
      return true;
    }

    return false;
  }

  Future<pw.Widget> loadQrImage(String qrImagePath) async {
    final qrImageBytes = await File(qrImagePath).readAsBytes();
    return pw.Image(pw.MemoryImage(qrImageBytes));
  }

  // In your generateCertificateWithTemplate method

  Future<void> generateCertificateWithTemplate(
    List<Student> selectedStudents,
  ) async {
    final pdf = pw.Document();

    if (pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Template not uploaded! Please upload a template.'),
        ),
      );
      return;
    }

    final templateBytes = File(pdfPath!).readAsBytesSync();
    final outputFile = File('OJT Certificates.pdf');
    final pdfPageFormat = pw.PdfPageFormat(612, 792); // Page size

    try {
      final Set<String> missingQRCodes = {};

      for (var student in selectedStudents) {
        final year = int.tryParse(
          student.endDate.substring(student.endDate.length - 4),
        );

        final allQRCodes = await DBHelper.getAllQRCodes();
        print('📦 All QR Codes in database:');
        for (var qr in allQRCodes) {
          print(
            '→ Program: ${qr['program']}, School: ${qr['school']}, Year: ${qr['year']}, file_url: ${qr['file_url']}',
          );
        }

        if (year != null) {
          final qrData = await DBHelper.getQRCodeForStudent(
            program: student.program,
            school: student.school,
            year: year,
          );

          if (qrData != null && qrData['file_url'] != null) {
            student.qrLink = qrData['file_url'];
            print(
              '✅ QR Code found for ${student.program} - ${student.school} ($year): ${qrData['file_url']}',
            );
          } else {
            final key = '${student.program} | ${student.school} | $year';
            missingQRCodes.add(key);
            print('❌ No QR Code for $key');
          }
        } else {
          print(
            '⚠️ Invalid end year for ${student.firstName} ${student.lastName}',
          );
        }
      }

      // 🔔 Show friendly warning, but continue
      if (missingQRCodes.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Missing QR Codes'),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Some students are missing QR codes. Their certificates will still be generated, but without QR links\nMake sure to generate QR codes first to have QR codes for the following students:\n',
                      ),
                      ...missingQRCodes.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.block,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                              SizedBox(width: 6),
                              Expanded(child: Text(entry)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    child: Text('Got it'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          );
        });
      }

      for (int i = 0; i < selectedStudents.length; i += 2) {
        final student1 = selectedStudents[i];
        final formattedDate1 = formatDateWithSuffix(
          parseDate(student1.endDate),
        );

        final student2 =
            (i + 1 < selectedStudents.length) ? selectedStudents[i + 1] : null;
        final formattedDate2 =
            (student2 != null)
                ? formatDateWithSuffix(parseDate(student2.endDate))
                : null;

        // 👇 Prepare QR widgets (await these)
        final qrWidget1 =
            (student1.qrLink != null && student1.qrLink!.isNotEmpty)
                ? await buildQrCodeWithLogo(student1.qrLink!)
                : null;

        final qrWidget2 =
            (student2 != null &&
                    student2.qrLink != null &&
                    student2.qrLink!.isNotEmpty)
                ? await buildQrCodeWithLogo(student2.qrLink!)
                : null;

        // 👇 Prepare student content widgets (await these too)
        final studentContent1 = await buildStudentContent(
          student1,
          formattedDate1,
        );

        final studentContent2 =
            (student2 != null && formattedDate2 != null)
                ? await buildStudentContentBottom(student2, formattedDate2)
                : null;

        // 👇 Now add page with plain widgets
        pdf.addPage(
          pw.Page(
            pageFormat: pdfPageFormat,
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  pw.Positioned.fill(
                    child: pw.Image(pw.MemoryImage(templateBytes)),
                  ),
                  studentContent1,
                  if (studentContent2 != null) studentContent2,
                  if (qrWidget1 != null)
                    pw.Positioned(top: 310, right: 50, child: qrWidget1),
                  if (qrWidget2 != null)
                    pw.Positioned(bottom: 35, right: 50, child: qrWidget2),
                ],
              );
            },
          ),
        );
      }

      await outputFile.writeAsBytes(await pdf.save());
      await Future.delayed(Duration(milliseconds: 300));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PDFViewerPage(
                pdfPath: outputFile.path,
                program: selectedProgram,
                year: selectedYear!,
              ),
        ),
      );
    } catch (e) {
      print("Error generating certificate: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Something went wrong while creating the certificates. Please try again.',
          ),
        ),
      );
    }
  }

  // Helper: Generate QR code inside PDF
  Future<pw.Widget> buildQrCodeWithLogo(String data, {double size = 50}) async {
    final logoBytes = await rootBundle.load('assets/images/pgp_logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final double logoSize = size * 0.25;

    return pw.Stack(
      alignment: pw.Alignment.center,
      children: [
        pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: data,
          width: size,
          height: size,
          drawText: false,
        ),
        pw.Container(
          width: logoSize,
          height: logoSize,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            image: pw.DecorationImage(image: logoImage, fit: pw.BoxFit.cover),
          ),
        ),
      ],
    );
  }

  // Top student layout with QR
  // Top student layout with QR code
  Future<pw.Widget> buildStudentContent(
    Student student,
    String formattedEndDate,
  ) async {
    final qrWidget =
        (student.qrLink != null && student.qrLink!.isNotEmpty)
            ? await buildQrCodeWithLogo(student.qrLink!)
            : null;

    return pw.Stack(
      children: [
        pw.Positioned(
          top: 144,
          left: 0,
          right: 0,
          child: pw.Align(
            alignment: pw.Alignment.topCenter,
            child: pw.Text(
              '${student.firstName} ${student.middleInitial}. ${student.lastName}'
                  .toUpperCase(),
              style: pw.TextStyle(font: boldFont, fontSize: 32),
            ),
          ),
        ),
        pw.Positioned(
          top: 191,
          left: 0,
          right: 0,
          child: pw.Align(
            alignment: pw.Alignment.topCenter,
            child: pw.Text(
              '(${student.program}, ${student.school})',
              style: pw.TextStyle(font: italicFont, fontSize: 11),
              maxLines: 2,
              overflow: pw.TextOverflow.clip,
            ),
          ),
        ),
        pw.Positioned(
          top: 231,
          left: 0,
          right: 0,
          child: pw.Align(
            alignment: pw.Alignment.topCenter,
            child: pw.Text(
              '${convertHoursToWords(int.parse(student.ojtHours))} HOURS ON THE JOB AND WORK IMMERSION TRAINING',
              style: pw.TextStyle(font: boldFont, fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
        pw.Positioned(
          top: 245,
          left: 0,
          right: 0,
          child: pw.Align(
            alignment: pw.Alignment.topCenter,
            child: pw.Text(
              'from ${student.startDate} to ${student.endDate} at the ${student.office},\n${student.address}',
              style: pw.TextStyle(font: regularFont, fontSize: 12),
              maxLines: 3,
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
        pw.Positioned(
          top: 293,
          left: 0,
          right: 0,
          child: pw.Align(
            alignment: pw.Alignment.topCenter,
            child: pw.Text(
              'Given this $formattedEndDate.',
              style: pw.TextStyle(font: regularFont, fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
        if (qrWidget != null)
          pw.Positioned(top: 310, right: 50, child: qrWidget),
      ],
    );
  }

  // Bottom student layout with QR code
  Future<pw.Widget> buildStudentContentBottom(
    Student student,
    String formattedEndDate,
  ) async {
    final qrWidget =
        (student.qrLink != null && student.qrLink!.isNotEmpty)
            ? await buildQrCodeWithLogo(student.qrLink!)
            : null;

    return pw.Stack(
      children: [
        pw.Positioned(
          top: 535,
          left: 0,
          right: 0,
          child: pw.Align(
            alignment: pw.Alignment.topCenter,
            child: pw.Text(
              '${student.firstName} ${student.middleInitial}. ${student.lastName}'
                  .toUpperCase(),
              style: pw.TextStyle(font: boldFont, fontSize: 32),
            ),
          ),
        ),
        pw.Positioned(
          top: 583,
          left: 0,
          right: 0,
          child: pw.Align(
            alignment: pw.Alignment.topCenter,
            child: pw.Text(
              '(${student.program}, ${student.school})',
              style: pw.TextStyle(font: italicFont, fontSize: 11),
              maxLines: 2,
              overflow: pw.TextOverflow.clip,
            ),
          ),
        ),
        pw.Positioned(
          top: 620,
          left: 0,
          right: 0,
          child: pw.Align(
            alignment: pw.Alignment.topCenter,
            child: pw.Text(
              '${convertHoursToWords(int.parse(student.ojtHours))} HOURS ON THE JOB AND WORK IMMERSION TRAINING',
              style: pw.TextStyle(font: boldFont, fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
        pw.Positioned(
          top: 637,
          left: 0,
          right: 0,
          child: pw.Align(
            alignment: pw.Alignment.topCenter,
            child: pw.Text(
              'from ${student.startDate} to ${student.endDate} at the ${student.office},\n${student.address}',
              style: pw.TextStyle(font: regularFont, fontSize: 12),
              maxLines: 3,
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
        pw.Positioned(
          top: 683,
          left: 0,
          right: 0,
          child: pw.Align(
            alignment: pw.Alignment.topCenter,
            child: pw.Text(
              'Given this $formattedEndDate.',
              style: pw.TextStyle(font: regularFont, fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
        if (qrWidget != null)
          pw.Positioned(bottom: 35, right: 50, child: qrWidget),
      ],
    );
  }

  void _onSearchChanged() {
    setState(() {
      final query = _searchController.text.toLowerCase();

      // Filter students by name and selected program
      filteredStudents =
          students.where((student) {
            final fullName =
                '${student.firstName} ${student.middleInitial} ${student.lastName}'
                    .toLowerCase();
            final matchesSearch =
                fullName.contains(query) ||
                student.program.toLowerCase().contains(query);

            // Check if student matches the selected program or if 'All' is selected
            final matchesProgram =
                selectedProgram == 'All' ||
                student.program.toLowerCase() == selectedProgram.toLowerCase();

            // ✅ Check if student matches the selected year filter (parsed from endDate)
            final matchesYear =
                selectedYear == 'All' ||
                (() {
                  try {
                    final parsedDate = DateFormat(
                      'MMMM d, yyyy',
                    ).parse(student.endDate);
                    return parsedDate.year.toString() == selectedYear;
                  } catch (e) {
                    return false;
                  }
                })();

            // ✅ Check if student matches the selected school
            final matchesSchool =
                selectedSchool == 'All' ||
                student.school.toLowerCase() == selectedSchool.toLowerCase();

            return matchesSearch &&
                matchesProgram &&
                matchesYear &&
                matchesSchool;
          }).toList();

      // Sort students by endDate in descending order (latest at the top)
      filteredStudents.sort((a, b) {
        return (b.id ?? 0).compareTo(a.id ?? 0); // Sort by ID, latest first
      });

      // Optional: filter program dropdown options based on search
      filteredPrograms =
          allPrograms.where((program) {
            return program.toLowerCase().contains(query);
          }).toList();
    });
  }

  List<String> getAvailableYears(List<Student> students) {
    final dateFormat = DateFormat('MMMM d, yyyy', 'en_US');

    print(
      '🧪 Total students received in getAvailableYears: ${students.length}',
    );
    for (var student in students) {
      print('👀 Student endDate: "${student.endDate}"');
    }

    final years =
        students
            .map((student) {
              print('📅 Raw endDate: "${student.endDate}"');
              try {
                final date = dateFormat.parse(student.endDate);
                final year = date.year.toString();
                print('✅ Parsed year: $year');
                return year;
              } catch (e) {
                print('❌ Failed to parse: "${student.endDate}"');
                return null;
              }
            })
            .whereType<String>()
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    print('📋 Final available years: $years');
    return ['All', ...years];
  }

  Widget buildSuperscriptDate(DateTime date) {
    final int day = date.day;
    final String suffix = getSuffix(day);
    final String month = getMonthName(date.month);
    final int year = date.year;

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, color: Colors.black),
        children: [
          TextSpan(text: '$day'),
          TextSpan(
            text: suffix,
            style: const TextStyle(fontFeatures: [FontFeature.superscripts()]),
          ),
          TextSpan(text: ' day of $month $year'),
        ],
      ),
    );
  }

  String getSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Menu
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔍 Search TextField for Students and Programs
                      const Text(
                        '📜 Generate Certificate',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          SizedBox(
                            width: 650, // Set the desired width here
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: 'Search Student or Program',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: Tooltip(
                                  message: 'Select Program',
                                  child: Builder(
                                    builder:
                                        (iconContext) => IconButton(
                                          icon: const Icon(
                                            Icons.arrow_drop_down,
                                          ),
                                          onPressed: () async {
                                            FocusScope.of(context).unfocus();

                                            final RenderBox iconBox =
                                                iconContext.findRenderObject()
                                                    as RenderBox;
                                            final Offset iconPosition = iconBox
                                                .localToGlobal(Offset.zero);
                                            final Size iconSize = iconBox.size;

                                            final List<String> filtered = [
                                              'All',
                                              ...allPrograms
                                                  .where((p) => p != 'All')
                                                  .toSet(),
                                            ];

                                            final String?
                                            selected = await showMenu<String>(
                                              context: context,
                                              position: RelativeRect.fromLTRB(
                                                iconPosition.dx,
                                                iconPosition.dy +
                                                    iconSize.height,
                                                iconPosition.dx +
                                                    iconSize.width,
                                                0,
                                              ),
                                              items:
                                                  filtered.map((
                                                    String program,
                                                  ) {
                                                    return PopupMenuItem<
                                                      String
                                                    >(
                                                      value: program,
                                                      child: SizedBox(
                                                        width:
                                                            300, // Match the width of the TextField here
                                                        child: Text(program),
                                                      ),
                                                    );
                                                  }).toList(),
                                              constraints: BoxConstraints(
                                                maxHeight:
                                                    300, // Max height before scrolling starts
                                              ),
                                            );

                                            if (selected != null) {
                                              setState(() {
                                                selectedProgram = selected;
                                                _searchController.text =
                                                    selected == 'All'
                                                        ? ''
                                                        : selected;
                                                _onSearchChanged();
                                              });
                                            }
                                          },
                                        ),
                                  ),
                                ),
                              ),
                              onChanged: (text) {
                                setState(() {
                                  // If the search bar is empty, reset to show 'All' programs
                                  if (text.isEmpty) {
                                    selectedProgram = 'All';
                                  }
                                  _onSearchChanged();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 20), // spacing after search bar
                          // 🔽 Add School Filter Dropdown here
                          IconButton(
                            icon: const Icon(Icons.filter_alt_outlined),
                            tooltip: 'Add Filter for Students',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: SizedBox(
                                        width: 500,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 20,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // 🔹 Dialog Title
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  const Text(
                                                    '⚙️Filter Options',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.close,
                                                    ),
                                                    onPressed:
                                                        () =>
                                                            Navigator.of(
                                                              context,
                                                            ).pop(),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 20),

                                              // 🔸 School Filter
                                              const Text(
                                                'Select School',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              DropdownButtonFormField<String>(
                                                value: selectedSchool,
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10,
                                                      ),
                                                ),
                                                items:
                                                    (allSchools.isNotEmpty
                                                            ? allSchools
                                                            : ['All'])
                                                        .map(
                                                          (school) =>
                                                              DropdownMenuItem(
                                                                value: school,
                                                                child: Text(
                                                                  school,
                                                                ),
                                                              ),
                                                        )
                                                        .toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    selectedSchool = value!;
                                                  });
                                                },
                                              ),
                                              const SizedBox(height: 16),

                                              // 🔸 Year Filter
                                              const Text(
                                                'Select Year',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              DropdownButtonFormField<String>(
                                                value: selectedYear,
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10,
                                                      ),
                                                ),
                                                items:
                                                    (availableYears.isNotEmpty
                                                            ? availableYears
                                                            : ['All'])
                                                        .map(
                                                          (year) =>
                                                              DropdownMenuItem(
                                                                value: year,
                                                                child: Text(
                                                                  year,
                                                                ),
                                                              ),
                                                        )
                                                        .toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    selectedYear = value!;
                                                  });
                                                },
                                              ),
                                              const SizedBox(height: 24),

                                              // 🔹 Action Buttons
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  // Clear Filters Button with Icon and Padding
                                                  ElevatedButton.icon(
                                                    icon: const Icon(
                                                      Icons.clear_all,
                                                      size: 18,
                                                    ),
                                                    label: const Text(
                                                      'Clear Filters',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors
                                                              .grey[300], // Light background color
                                                      foregroundColor:
                                                          Colors
                                                              .black, // Icon and text color
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 12,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        selectedSchool = 'All';
                                                        selectedYear = 'All';
                                                      });
                                                      _onSearchChanged(); // Optional: refresh list immediately
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Filters Cleared',
                                                          ),
                                                          duration: Duration(
                                                            seconds: 2,
                                                          ), // Duration the snackbar will be shown
                                                        ),
                                                      );
                                                    },
                                                  ),

                                                  const SizedBox(
                                                    width: 12,
                                                  ), // Spacing between buttons
                                                  // Apply Button with Icon
                                                  ElevatedButton.icon(
                                                    icon: const Icon(
                                                      Icons.check,
                                                      size: 18,
                                                    ),
                                                    label: const Text(
                                                      'Apply',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          const Color.fromARGB(
                                                            255,
                                                            9,
                                                            33,
                                                            53,
                                                          ), // Blue background for Apply button
                                                      foregroundColor:
                                                          Colors
                                                              .white, // Icon and text color
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 12,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      _onSearchChanged(); // Apply filters
                                                      Navigator.of(
                                                        context,
                                                      ).pop(); // Close the dialog

                                                      // Show SnackBar indicating the filter is applied
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Filters Applied',
                                                          ),
                                                          duration: Duration(
                                                            seconds: 2,
                                                          ), // Duration the snackbar will be shown
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                              );
                            },
                          ),

                          // ✅ Select All Checkbox aligned to the right
                          Expanded(
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.end, // Align to the right
                              children: [
                                Checkbox(
                                  value:
                                      filteredStudents.isNotEmpty &&
                                      filteredStudents.every(
                                        (s) => s.isSelected,
                                      ),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      for (var student in filteredStudents) {
                                        student.isSelected = value ?? false;
                                      }
                                    });
                                  },
                                ),
                                const Text(
                                  'Select All',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 🧾 Student List
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            // ✅ Sort outside the itemBuilder to avoid re-sorting during rebuild
                            filteredStudents.sort((a, b) {
                              return (b.id ?? 0).compareTo(
                                a.id ?? 0,
                              ); // Sort by ID, latest first
                            });

                            // ✅ Check if no data is available
                            if (filteredStudents.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No data available',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: filteredStudents.length,
                              itemBuilder: (context, index) {
                                final student = filteredStudents[index];

                                // 👇 Extract the year from endDate
                                String endYear = '';
                                try {
                                  endYear =
                                      DateFormat(
                                        'MMMM d, yyyy',
                                      ).parse(student.endDate).year.toString();
                                } catch (e) {
                                  endYear = ''; // Fallback if parsing fails
                                }

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    title: Text(
                                      '${student.firstName} ${student.lastName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('${student.program} - $endYear'),
                                        Text(
                                          student.school,
                                          style: const TextStyle(
                                            color: Color.fromARGB(
                                              255,
                                              53,
                                              53,
                                              53,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Checkbox(
                                      value: student.isSelected,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          student.isSelected = value ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 200,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final uploaded = await pickTemplate();

                                  if (uploaded) {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: const Text(
                                              'Template Uploaded',
                                            ),
                                            content: const Text(
                                              'Your certificate template was uploaded successfully.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          ),
                                    );
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: const Text('Upload Failed'),
                                            content: const Text(
                                              'No template was selected or the upload was canceled.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.upload_file, size: 20),
                                label: const Text(
                                  'Upload Template',
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

                            const SizedBox(width: 16), // space between buttons
                            SizedBox(
                              width: 200,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final selectedStudents =
                                      filteredStudents
                                          .where(
                                            (student) => student.isSelected,
                                          )
                                          .toList();

                                  if (selectedStudents.isEmpty &&
                                      pdfPath == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please select students and upload a template',
                                        ),
                                      ),
                                    );
                                  } else if (selectedStudents.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please select a student or students',
                                        ),
                                      ),
                                    );
                                  } else if (pdfPath == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please upload a template',
                                        ),
                                      ),
                                    );
                                  } else {
                                    generateCertificateWithTemplate(
                                      selectedStudents,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.print, size: 20),
                                label: const Text(
                                  'Generate Certificate',
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
                          ],
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
