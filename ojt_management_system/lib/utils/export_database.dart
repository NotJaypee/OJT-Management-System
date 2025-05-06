import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ojt_management_system/database/db_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

void exportToCSV(BuildContext context) async {
  try {
    List<Map<String, dynamic>> students = await DBHelper.exportStudents();

    String csv =
        "first_name,middle_initial,last_name,program,school,ojt_hours,start_date,end_date,office,address\n";

    for (var student in students) {
      String startDate = _formatDate(student['start_date']);
      String endDate = _formatDate(student['end_date']);
      String lastName =
          '"${student['last_name']}"'; // wrap last name with quotes
      String address = '"${student['address']}"'; // already wrapping address
      String school = '"${student['school']}"'; // wrap school with quotes

      csv +=
          "${student['first_name']},${student['middle_initial']},$lastName,"
          "${student['program']},$school,${student['ojt_hours']},"
          "$startDate,$endDate,${student['office']},$address\n";
    }

    final directory = await getApplicationDocumentsDirectory();
    String path = "${directory.path}/students_data.csv";

    int counter = 1;
    while (await File(path).exists()) {
      path = "${directory.path}/students_data_$counter.csv";
      counter++;
    }

    final file = File(path);
    List<int> utf8WithBom = [0xEF, 0xBB, 0xBF] + utf8.encode(csv);
    await file.writeAsBytes(utf8WithBom);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Data exported successfully to $path"),
        duration: Duration(seconds: 3),
      ),
    );
    print("Data exported to $path");
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error exporting data: $e"),
        duration: Duration(seconds: 3),
      ),
    );
    print("Error exporting data: $e");
  }
}

String _formatDate(String original) {
  try {
    DateTime parsed = DateFormat("MMMM d, yyyy").parse(original);
    return DateFormat("yyyy-MM-dd").format(parsed);
  } catch (_) {
    return original; // fallback if it can't parse
  }
}
