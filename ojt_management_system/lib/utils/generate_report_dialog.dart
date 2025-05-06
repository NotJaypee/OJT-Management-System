import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ojt_management_system/utils/student_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ojt_management_system/database/db_helper.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

class GenerateReportDialog extends StatefulWidget {
  final List<String> programOptions;
  final List<String> schoolOptions;
  final List<String> yearOptions;
  final void Function({
    required String program,
    required String school,
    required String year,
  })?
  onGenerate; // Optional callback to handle generation externally

  const GenerateReportDialog({
    super.key,
    required this.programOptions,
    required this.schoolOptions,
    required this.yearOptions,
    this.onGenerate,
  });

  @override
  State<GenerateReportDialog> createState() => _GenerateReportDialogState();
}

class _GenerateReportDialogState extends State<GenerateReportDialog> {
  final TextEditingController _programController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  bool _isGenerating = false; // Add loading state

  @override
  void dispose() {
    _programController.dispose();
    _schoolController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('📤 Generate Report'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSearchFieldWithDropdown(
              label: 'Program',
              controller: _programController,
              options: widget.programOptions,
              width: 50,
            ),
            const SizedBox(height: 12),
            _buildSearchFieldWithDropdown(
              label: 'School',
              controller: _schoolController,
              options: widget.schoolOptions,
              width: 50,
            ),
            const SizedBox(height: 12),
            _buildSearchFieldWithDropdown(
              label: 'Year',
              controller: _yearController,
              options: widget.yearOptions,
              width: 250,
            ),
            if (_isGenerating) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isGenerating ? null : _handleGenerate,
          icon: const Icon(Icons.file_download),
          label: const Text('Generate Report'),
        ),
      ],
    );
  }

  Future<void> _handleGenerate() async {
    final selectedProgram = _programController.text.trim();
    final selectedSchool = _schoolController.text.trim();
    final selectedYear = _yearController.text.trim();

    setState(() {
      _isGenerating = true;
    });

    try {
      final allStudents = await DBHelper.getAllStudents();

      // Filter by school and year first
      List<Student> filtered =
          allStudents.where((student) {
            final matchesSchool =
                selectedSchool == 'All' ||
                student.school.trim() == selectedSchool.trim();

            String? studentYear;

            // Check if endDate is empty before attempting to parse
            if (student.endDate.isNotEmpty) {
              try {
                final parsedDate = DateFormat(
                  'MMMM d, yyyy',
                ).parse(student.endDate);
                studentYear = parsedDate.year.toString();
              } catch (e) {
                print('Failed to parse endDate: ${student.endDate}');
                studentYear = ''; // Set blank if parsing fails
              }
            } else {
              studentYear = ''; // Leave blank if endDate is empty
            }

            // Compare with the selected year
            final matchesYear =
                selectedYear == 'All' || studentYear == selectedYear;
            return matchesSchool && matchesYear;
          }).toList();

      final workbook = xlsio.Workbook();

      if (selectedProgram == 'All') {
        // Group students by program for separate sheets
        final Map<String, List<Student>> groupedByProgram = {};
        for (var student in filtered) {
          groupedByProgram.putIfAbsent(student.program, () => []).add(student);
        }

        bool createdSheets = false;
        int sheetIndex = 0;
        for (var entry in groupedByProgram.entries) {
          final programName = entry.key;
          final students = entry.value;
          final safeSheetName =
              (programName.length > 31
                  ? programName.substring(0, 31)
                  : programName);

          final sheet =
              sheetIndex == 0
                  ? workbook.worksheets[0] // reuse the default first sheet
                  : workbook.worksheets.addWithName(safeSheetName);

          if (sheetIndex == 0) {
            sheet.name = safeSheetName; // rename default sheet
          }

          createdSheets = true;
          sheetIndex++;

          // Title
          final titleRange = sheet.getRangeByName('A1:H1');
          titleRange.merge();
          titleRange.cellStyle.bold = true;
          titleRange.cellStyle.fontSize = 16;
          titleRange.cellStyle.hAlign = xlsio.HAlignType.center;
          titleRange.setText('$programName - $selectedYear');

          // Headers
          final headers = {
            'A2': 'No',
            'B2': 'Full Name',
            'C2': 'Program',
            'D2': 'School',
            'E2': 'OJT Hours',
            'F2': 'Start Date',
            'G2': 'End Date',
            'H2': 'Office',
          };

          headers.forEach((cell, text) {
            final range = sheet.getRangeByName(cell);
            range.setText(text);
            range.cellStyle.bold = true; // Make it bold
          });

          // Data
          int row = 3;
          int no = 1;
          for (var student in students) {
            sheet.getRangeByName('A$row').setNumber(no.toDouble());
            no++;

            sheet
                .getRangeByName('B$row')
                .setText(
                  '${student.firstName} ${student.middleInitial}. ${student.lastName}',
                );
            sheet.getRangeByName('C$row').setText(student.program);
            sheet.getRangeByName('D$row').setText(student.school);
            sheet
                .getRangeByName('E$row')
                .setNumber(double.tryParse(student.ojtHours.toString()) ?? 0);
            sheet.getRangeByName('F$row').setText(student.startDate);
            sheet.getRangeByName('G$row').setText(student.endDate);
            sheet.getRangeByName('H$row').setText(student.office);
            row++;
          }
          final Map<String, int> columnMaxLengths = {
            'A': 'No'.length,
            'B': 'Full Name'.length,
            'C': 'Program'.length,
            'D': 'School'.length,
            'E': 'OJT Hours'.length,
            'F': 'Start Date'.length,
            'G': 'End Date'.length,
            'H': 'Office'.length,
          };

          // Go through students to find longest text in each column
          for (var student in students) {
            final fullName =
                '${student.firstName} ${student.middleInitial}. ${student.lastName}';
            columnMaxLengths['B'] =
                fullName.length > columnMaxLengths['B']!
                    ? fullName.length
                    : columnMaxLengths['B']!;
            columnMaxLengths['C'] =
                student.program.length > columnMaxLengths['C']!
                    ? student.program.length
                    : columnMaxLengths['C']!;
            columnMaxLengths['D'] =
                student.school.length > columnMaxLengths['D']!
                    ? student.school.length
                    : columnMaxLengths['D']!;
            columnMaxLengths['F'] =
                student.startDate.length > columnMaxLengths['F']!
                    ? student.startDate.length
                    : columnMaxLengths['F']!;
            columnMaxLengths['G'] =
                student.endDate.length > columnMaxLengths['G']!
                    ? student.endDate.length
                    : columnMaxLengths['G']!;
            columnMaxLengths['H'] =
                student.office.length > columnMaxLengths['H']!
                    ? student.office.length
                    : columnMaxLengths['H']!;
          }

          // Apply column widths (with buffer)
          columnMaxLengths.forEach((col, length) {
            final colRange = sheet.getRangeByName('${col}1');
            colRange.columnWidth = length + 1;
          });
        }

        // If we created new sheets, just clear and rename the default sheet
        if (createdSheets && workbook.worksheets.count > 1) {
          // Already handled above
        }
      } else {
        // Normal case - single sheet for selected program
        filtered =
            filtered.where((student) {
              return selectedProgram == 'All' ||
                  student.program.trim() == selectedProgram.trim();
            }).toList();

        final sheet = workbook.worksheets[0];
        sheet.name = '$selectedProgram $selectedYear';

        // Title
        final titleRange = sheet.getRangeByName('A1:H1');
        titleRange.merge();
        titleRange.cellStyle.bold = true;
        titleRange.cellStyle.fontSize = 16;
        titleRange.cellStyle.hAlign = xlsio.HAlignType.center;
        titleRange.setText('$selectedProgram - $selectedYear');

        // Headers
        final headers = {
          'A2': 'No',
          'B2': 'Full Name',
          'C2': 'Program',
          'D2': 'School',
          'E2': 'OJT Hours',
          'F2': 'Start Date',
          'G2': 'End Date',
          'H2': 'Office',
        };

        headers.forEach((cell, text) {
          final range = sheet.getRangeByName(cell);
          range.setText(text);
          range.cellStyle.bold = true; // Make it bold
        });

        // Data
        int row = 3;
        int no = 1;
        for (var student in filtered) {
          sheet.getRangeByName('A$row').setNumber(no.toDouble());
          no++;

          sheet
              .getRangeByName('B$row')
              .setText(
                '${student.firstName} ${student.middleInitial}. ${student.lastName}',
              );
          sheet.getRangeByName('C$row').setText(student.program);
          sheet.getRangeByName('D$row').setText(student.school);
          sheet
              .getRangeByName('E$row')
              .setNumber(double.tryParse(student.ojtHours.toString()) ?? 0);
          sheet.getRangeByName('F$row').setText(student.startDate);
          sheet.getRangeByName('G$row').setText(student.endDate);
          sheet.getRangeByName('H$row').setText(student.office);
          row++;
        }
        final Map<String, int> columnMaxLengths = {
          'A': 'No'.length,
          'B': 'Full Name'.length,
          'C': 'Program'.length,
          'D': 'School'.length,
          'E': 'OJT Hours'.length,
          'F': 'Start Date'.length,
          'G': 'End Date'.length,
          'H': 'Office'.length,
        };

        // Go through students to find longest text in each column
        for (var student in filtered) {
          final fullName =
              '${student.firstName} ${student.middleInitial}. ${student.lastName}';
          columnMaxLengths['B'] =
              fullName.length > columnMaxLengths['B']!
                  ? fullName.length
                  : columnMaxLengths['B']!;
          columnMaxLengths['C'] =
              student.program.length > columnMaxLengths['C']!
                  ? student.program.length
                  : columnMaxLengths['C']!;
          columnMaxLengths['D'] =
              student.school.length > columnMaxLengths['D']!
                  ? student.school.length
                  : columnMaxLengths['D']!;
          columnMaxLengths['F'] =
              student.startDate.length > columnMaxLengths['F']!
                  ? student.startDate.length
                  : columnMaxLengths['F']!;
          columnMaxLengths['G'] =
              student.endDate.length > columnMaxLengths['G']!
                  ? student.endDate.length
                  : columnMaxLengths['G']!;
          columnMaxLengths['H'] =
              student.office.length > columnMaxLengths['H']!
                  ? student.office.length
                  : columnMaxLengths['H']!;
        }

        // Apply column widths (with buffer)
        columnMaxLengths.forEach((col, length) {
          final colRange = sheet.getRangeByName('${col}1');
          colRange.columnWidth = length + 1;
        });
      }

      // Set the file name based on selectedProgram and selectedYear
      String baseFileName = '';

      if (selectedProgram == 'All' &&
          selectedSchool == 'All' &&
          selectedYear != 'All') {
        baseFileName = '${selectedYear}_Interns';
      } else if (selectedProgram == 'All' &&
          selectedSchool != 'All' &&
          selectedYear == 'All') {
        baseFileName = '${selectedSchool.replaceAll(" ", "_")}_Interns';
      } else if (selectedProgram == 'All' &&
          selectedSchool != 'All' &&
          selectedYear != 'All') {
        baseFileName =
            '${selectedSchool.replaceAll(" ", "_")}_Interns_$selectedYear';
      } else if (selectedProgram == 'All') {
        baseFileName =
            'OJT_Report_${selectedSchool.replaceAll(" ", "_")}_$selectedYear';
      } else {
        baseFileName =
            '${selectedProgram.replaceAll(" ", "_")}_Interns_$selectedYear';
      }

      String fileName = '$baseFileName.xlsx';

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final directory = await getDownloadsDirectory();
      String filePath = '${directory!.path}/$fileName';

      int counter = 1;
      while (await File(filePath).exists()) {
        filePath =
            '${directory.path}/$baseFileName'
            '_$counter.xlsx';
        counter++;
      }

      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      if (await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Excel report saved to Downloads as ${file.path.split('/').last}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error saving report.')));
      }
    } catch (e) {
      print('Error generating report: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error generating report.')));
    }

    setState(() {
      _isGenerating = false;
    });

    Navigator.pop(context);
  }

  Widget _buildSearchFieldWithDropdown({
    required String label,
    required TextEditingController controller,
    required List<String> options,
    required double width,
  }) {
    final allOptions = ['All', ...options];

    return Row(
      children: [
        Expanded(
          child: Container(
            width: width,
            child: Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                return allOptions.where(
                  (option) => option.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
                );
              },
              fieldViewBuilder: (
                context,
                textFieldController,
                focusNode,
                onFieldSubmitted,
              ) {
                textFieldController.text = controller.text;
                return TextFormField(
                  controller: textFieldController,
                  focusNode: focusNode,
                  decoration: InputDecoration(labelText: label),
                  onChanged: (value) => controller.text = value,
                );
              },
              onSelected: (String selection) {
                controller.text = selection;
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: Container(
                      width: 360, // Custom dropdown width
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
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_drop_down),
          onPressed: () async {
            String? selectedOption = await showDialog<String>(
              context: context,
              builder: (context) {
                return SimpleDialog(
                  title: Text('Select $label'),
                  children:
                      allOptions.map((option) {
                        return SimpleDialogOption(
                          onPressed: () {
                            Navigator.pop(context, option);
                          },
                          child: Text(option),
                        );
                      }).toList(),
                );
              },
            );

            if (selectedOption != null) {
              setState(() {
                controller.text = selectedOption;
              });
            }
          },
        ),
      ],
    );
  }
}
