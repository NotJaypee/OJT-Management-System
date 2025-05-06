import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart'; // Required for date formatting
import 'package:flutter/material.dart'; // For SnackBar
import 'package:ojt_management_system/database/db_helper.dart';

Future<void> importFromCSV(BuildContext context) async {
  try {
    print("🔄 Starting import process...");

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Importing..."),
          content: Row(
            children: <Widget>[
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Please wait..."),
            ],
          ),
        );
      },
    );

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.path == null) {
      print("❌ No file selected.");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ No file selected.')));
      Navigator.of(context).pop(); // Dismiss loading dialog
      return;
    }

    final path = result.files.single.path!;
    final file = File(path);

    print("📄 File selected: $path");

    String csv = await file.readAsString();

    List<List<dynamic>> rows = const CsvToListConverter(eol: '\n').convert(csv);

    print("📄 Parsed rows: $rows");

    rows.removeAt(0); // Remove header row

    List<Map<String, dynamic>> students = [];
    int rowIndex = 1;

    for (var row in rows) {
      print("🔍 Row $rowIndex: $row");

      if (row.length >= 10) {
        try {
          students.add({
            'first_name': row[0].toString().trim(),
            'middle_initial': row[1].toString().trim(),
            'last_name': row[2].toString().trim(),
            'program': row[3].toString().trim(),
            'school': row[4].toString().trim(),
            'ojt_hours': row[5],
            'start_date': _formatDate(row[6].toString()),
            'end_date': _formatDate(row[7].toString()),
            'office': row[8].toString().trim(),
            'address': row[9].toString().trim(),
          });
          print("✅ Parsed student from row $rowIndex");
        } catch (e) {
          print("⚠️ Error parsing row $rowIndex: $e");
        }
      } else {
        print("⚠️ Skipping invalid row $rowIndex (too few columns): $row");
      }

      rowIndex++;
    }

    if (students.isEmpty) {
      // If no students were successfully parsed, show a message and exit
      print("⚠️ No valid students to import.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ No valid students to import.')),
      );
      Navigator.of(context).pop(); // Dismiss loading dialog
      return;
    }

    print("Imported students: $students");

    // Ensure students were successfully parsed before clearing and importing
    print("🧹 Clearing existing student records...");
    await DBHelper.clearStudents();

    print("📥 Importing new students...");
    await DBHelper.importStudents(students);

    print("✅ Data imported successfully from $path");

    // Dismiss loading dialog and show success dialog
    Navigator.of(context).pop(); // Dismiss loading dialog

    // Show success dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Import Successful'),
          content: Text('✅ Imported ${students.length} students successfully!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  } catch (e) {
    print("⚠️ Error during import: $e");

    // Dismiss loading dialog
    Navigator.of(context).pop(); // Dismiss loading dialog

    // Show error SnackBar
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('❌ Error importing students: $e')));
  }
}

// Format short date (like 2/18/2025 or 2-18-2025) into full format (February 18, 2025)
String _formatDate(String dateStr) {
  try {
    DateTime date = DateFormat('yyyy-MM-dd').parseStrict(dateStr);
    return DateFormat('MMMM d, yyyy').format(date);
  } catch (_) {
    return dateStr;
  }
}
