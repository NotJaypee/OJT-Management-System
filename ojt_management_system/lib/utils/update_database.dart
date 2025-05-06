import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ojt_management_system/database/db_helper.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:ojt_management_system/pages/table_page.dart'; // Update with your actual TablePage

void pickFileAndUpdateDatabase(BuildContext context) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );

  if (result != null && result.files.single.path != null) {
    await updateDatabase(context, result.files.single.path!);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("❌ No CSV file selected."),
        duration: Duration(seconds: 3),
      ),
    );
  }
}

Future<void> updateDatabase(BuildContext context, String csvPath) async {
  try {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    "Importing Data...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    final input = File(csvPath).openRead();
    final fieldsList =
        await input
            .transform(utf8.decoder)
            .transform(const CsvToListConverter(eol: '\n'))
            .toList();

    int addedCount = 0;
    int existingCount = 0;

    // Skip header row
    for (int i = 1; i < fieldsList.length; i++) {
      final fields = fieldsList[i];
      if (fields.length < 10) continue;

      String firstName = fields[0].toString().trim();
      String middleInitial = fields[1].toString().trim();
      String lastName = fields[2].toString().trim();
      String program = fields[3].toString().trim();
      String school = fields[4].toString().trim();
      String ojtHours = fields[5].toString().trim();
      String startDate = _formatDateToLong(fields[6].toString().trim());
      String endDate = _formatDateToLong(fields[7].toString().trim());
      String office = fields[8].toString().trim();

      // Combine all remaining fields into address
      String address = fields.sublist(9).join(', ').trim();

      bool studentExists = await DBHelper.checkIfStudentExists(
        firstName,
        middleInitial,
        lastName,
        school,
      );

      if (!studentExists) {
        await DBHelper.addStudent(
          firstName,
          middleInitial,
          lastName,
          program,
          school,
          ojtHours,
          startDate,
          endDate,
          office,
          address,
        );
        addedCount++;
      } else {
        existingCount++;
      }
    }

    // Dismiss the loading indicator
    Navigator.of(context).pop();

    // Show dialog after data update
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Import Status'),
          content: Text("✅ $addedCount added, $existingCount already existed."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => TablePage()),
                ); // Navigate to TablePage after closing the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    print("✅ $addedCount students added, $existingCount already existed.");
  } catch (e) {
    // Dismiss the loading indicator in case of error
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ Error: $e"),
        duration: const Duration(seconds: 3),
      ),
    );
    print("❌ Error updating database: $e");
  }
}

String _formatDateToLong(String dateStr) {
  try {
    DateTime date;
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
      date = DateFormat('yyyy-MM-dd').parseStrict(dateStr);
    } else {
      date = DateFormat('MMMM d, yyyy').parseStrict(dateStr);
    }
    return DateFormat('MMMM d, yyyy').format(date);
  } catch (_) {
    return dateStr;
  }
}
