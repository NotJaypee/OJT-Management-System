import 'package:flutter/material.dart';
import 'package:ojt_management_system/pages/table_page.dart';
import 'package:ojt_management_system/utils/student_model.dart';
import 'package:ojt_management_system/database/db_helper.dart';

class EditStudentDialog extends StatefulWidget {
  final Student student;
  final Function(Student) onSave;
  final Function() onDelete;

  const EditStudentDialog({
    super.key,
    required this.student,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<EditStudentDialog> {
  late TextEditingController _firstNameController;
  late TextEditingController _middleInitialController;
  late TextEditingController _lastNameController;
  late TextEditingController _programController;
  late TextEditingController _schoolController;
  late TextEditingController _ojtHoursController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _officeController;
  late TextEditingController _addressController;
  List<String> programList = [];
  List<String> schoolList = [];
  List<String> ojtHoursList = []; // New list for OJT Hours
  List<String> startDateList = [];
  List<String> endDateList = []; // New list for End Dates
  List<String> officeList = []; // New list for Office
  List<String> addressList = []; // New list for Address

  final DBHelper dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    loadAutocompleteData();
    _firstNameController = TextEditingController(
      text: widget.student.firstName,
    );
    _middleInitialController = TextEditingController(
      text: widget.student.middleInitial,
    );
    _lastNameController = TextEditingController(text: widget.student.lastName);
    _programController = TextEditingController(text: widget.student.program);
    _schoolController = TextEditingController(text: widget.student.school);
    _ojtHoursController = TextEditingController(
      text: widget.student.ojtHours.toString(),
    );
    _startDateController = TextEditingController(
      text: widget.student.startDate,
    );
    _endDateController = TextEditingController(text: widget.student.endDate);
    _officeController = TextEditingController(text: widget.student.office);
    _addressController = TextEditingController(text: widget.student.address);
  }

  void loadAutocompleteData() async {
    // Replace this with your actual database fetch logic
    final programsFromDb = await dbHelper.getPrograms(); // returns List<String>
    final schoolsFromDb = await dbHelper.getSchools(); // returns List<String>
    final ojtHoursFromDb =
        await dbHelper
            .getDistinctOJTHours(); // New fetch for OJT Hours (List<String>)
    final startDateFromDb =
        await dbHelper.getDistinctStartDates(); // Fetch distinct start dates
    final endDateFromDb =
        await dbHelper.getDistinctEndDates(); // Fetch distinct end dates
    final officeFromDb =
        await DBHelper.getDistinctOffices(); // Fetch distinct offices
    final addressFromDb =
        await DBHelper.getDistinctAddresses(); // Fetch distinct addresses

    setState(() {
      programList = programsFromDb;
      schoolList = schoolsFromDb;
      ojtHoursList = ojtHoursFromDb; // Assign the OJT Hours list here
      startDateList = startDateFromDb; // Assign the start date list here
      endDateList = endDateFromDb; // Assign the end date list here
      officeList = officeFromDb; // Assign the office list here
      addressList = addressFromDb; // Assign the address list here
    });
  }

  void _saveChanges() async {
    final updatedStudent = widget.student.copyWith(
      firstName: _firstNameController.text,
      middleInitial: _middleInitialController.text,
      lastName: _lastNameController.text,
      program: _programController.text,
      school: _schoolController.text,
      ojtHours: (int.tryParse(_ojtHoursController.text) ?? 0).toString(),
      startDate: _startDateController.text,
      endDate: _endDateController.text,
      office: _officeController.text,
      address: _addressController.text,
    );

    await DBHelper.updateStudent(updatedStudent); // Update the student in DB
    widget.onSave(updatedStudent); // Call the onSave function to refresh UI
    Navigator.pop(context);
  }

  void _deleteStudent() async {
    // Check if the ID is not null
    if (widget.student.id != null) {
      await DBHelper.deleteStudent(widget.student.id!);

      widget.onDelete(); // Optional: for parent widgets to refresh state

      // Navigate to TablePage after deletion and replace current page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TablePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student ID is null, cannot delete')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.all(16),
      contentPadding: EdgeInsets.zero,
      content: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 30,
              left: 13,
              right: 13,
              bottom: 13,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Edit Student',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Row 1: Name
                  Row(
                    children: [
                      Expanded(
                        child: _buildBoxedTextField(
                          _firstNameController,
                          'First Name',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildBoxedTextField(
                          _middleInitialController,
                          'Middle Initial',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildBoxedTextField(
                          _lastNameController,
                          'Last Name',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 2: Program and School
                  Row(
                    children: [
                      Expanded(
                        child: RawAutocomplete<String>(
                          textEditingController: _programController,
                          focusNode: FocusNode(),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return programList; // Return all program options
                            }
                            return programList.where((String option) {
                              return option.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              );
                            });
                          },
                          fieldViewBuilder: (
                            context,
                            controller,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            return _buildBoxedTextField(
                              controller,
                              'Program',
                              focusNode: focusNode,
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            final width = MediaQuery.of(context).size.width;

                            // Calculate dynamic width based on the longest option
                            double dynamicWidth =
                                width /
                                3.5; // Default to a third of the screen width

                            if (options.isNotEmpty) {
                              String longestOption = options.reduce(
                                (a, b) => a.length > b.length ? a : b,
                              );

                              final textPainter = TextPainter(
                                text: TextSpan(
                                  text: longestOption,
                                  style: TextStyle(fontSize: 16),
                                ),
                                textDirection: TextDirection.ltr,
                              )..layout();

                              dynamicWidth =
                                  textPainter.width + 65; // Add padding
                            }

                            dynamicWidth =
                                dynamicWidth < width ? dynamicWidth : width / 2;

                            // Calculate the dynamic height based on the number of options
                            double dynamicHeight =
                                options.length * 60.0; // Height per item

                            // Limit height to 200 pixels (for a reasonable dropdown height)
                            dynamicHeight =
                                dynamicHeight < 200 ? dynamicHeight : 200;

                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                child: Container(
                                  width: dynamicWidth,
                                  height: dynamicHeight,
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(option),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 8),
                      Expanded(
                        child: RawAutocomplete<String>(
                          textEditingController: _schoolController,
                          focusNode: FocusNode(),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            // Show all options if there's no text
                            if (textEditingValue.text.isEmpty) {
                              return schoolList; // Return all school options
                            }
                            // Filter options when text is typed
                            return schoolList.where((String option) {
                              return option.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              );
                            });
                          },
                          fieldViewBuilder: (
                            context,
                            controller,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            return _buildBoxedTextField(
                              controller,
                              'School',
                              focusNode: focusNode,
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            final width = MediaQuery.of(context).size.width;

                            // Calculate dynamic width based on the longest option
                            double dynamicWidth =
                                width /
                                3.5; // Default to a third of the screen width

                            if (options.isNotEmpty) {
                              String longestOption = options.reduce(
                                (a, b) => a.length > b.length ? a : b,
                              );

                              final textPainter = TextPainter(
                                text: TextSpan(
                                  text: longestOption,
                                  style: TextStyle(fontSize: 16),
                                ),
                                textDirection: TextDirection.ltr,
                              )..layout();

                              dynamicWidth =
                                  textPainter.width + 60; // Add padding
                            }

                            dynamicWidth =
                                dynamicWidth < width ? dynamicWidth : width / 2;

                            // Calculate the dynamic height based on the number of options
                            double dynamicHeight =
                                options.length * 60.0; // Height per item

                            // Limit height to 200 pixels (for a reasonable dropdown height)
                            dynamicHeight =
                                dynamicHeight < 200 ? dynamicHeight : 200;

                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                child: Container(
                                  width: dynamicWidth,
                                  height: dynamicHeight,
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(option),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 3: OJT Hours, Start Date, End Date
                  Row(
                    children: [
                      Expanded(
                        child: RawAutocomplete<String>(
                          textEditingController: _ojtHoursController,
                          focusNode: FocusNode(),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return ojtHoursList; // Return all OJT Hours options
                            }
                            return ojtHoursList.where((String option) {
                              return option.contains(
                                textEditingValue.text,
                              ); // Filter by the entered text
                            }).toList();
                          },
                          fieldViewBuilder: (
                            context,
                            controller,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            return _buildBoxedTextField(
                              controller,
                              'OJT Hours',
                              type:
                                  TextInputType
                                      .number, // Ensuring number input for OJT Hours
                              focusNode: focusNode,
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            final width = MediaQuery.of(context).size.width;

                            // Calculate dynamic width based on the longest option
                            double dynamicWidth =
                                width /
                                3.5; // Default to a third of the screen width

                            if (options.isNotEmpty) {
                              String longestOption = options.reduce(
                                (a, b) => a.length > b.length ? a : b,
                              );

                              final textPainter = TextPainter(
                                text: TextSpan(
                                  text: longestOption,
                                  style: TextStyle(fontSize: 16),
                                ),
                                textDirection: TextDirection.ltr,
                              )..layout();

                              // Make sure the dropdown has a minimum width based on the longest option
                              dynamicWidth =
                                  textPainter.width + 32; // Add padding
                            }

                            // Ensure the dropdown width is at least 150px or the width of the screen
                            dynamicWidth =
                                dynamicWidth < 150 ? 150 : dynamicWidth;
                            dynamicWidth =
                                dynamicWidth < width ? dynamicWidth : width / 2;

                            // Calculate the dynamic height based on the number of options
                            double dynamicHeight =
                                options.length * 60.0; // Height per item

                            // Limit height to 200 pixels (for a reasonable dropdown height)
                            dynamicHeight =
                                dynamicHeight < 200 ? dynamicHeight : 200;

                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                child: Container(
                                  width:
                                      dynamicWidth, // Dynamic width for the dropdown
                                  height: dynamicHeight,
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(option),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 8),
                      Expanded(
                        child: RawAutocomplete<String>(
                          textEditingController: _startDateController,
                          focusNode: FocusNode(),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            // Show all options if there's no text
                            if (textEditingValue.text.isEmpty) {
                              return startDateList; // Return all start date options
                            }
                            // Filter options when text is typed
                            return startDateList.where((String option) {
                              return option.contains(
                                textEditingValue.text,
                              ); // Filter by the entered text
                            }).toList();
                          },
                          fieldViewBuilder: (
                            context,
                            controller,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            return _buildBoxedTextField(
                              controller,
                              'Start Date',
                              focusNode: focusNode,
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            final width = MediaQuery.of(context).size.width;

                            // Calculate dynamic width based on the longest option
                            double dynamicWidth =
                                width /
                                3.5; // Default to a third of the screen width

                            if (options.isNotEmpty) {
                              String longestOption = options.reduce(
                                (a, b) => a.length > b.length ? a : b,
                              );

                              final textPainter = TextPainter(
                                text: TextSpan(
                                  text: longestOption,
                                  style: TextStyle(fontSize: 16),
                                ),
                                textDirection: TextDirection.ltr,
                              )..layout();

                              // Make sure the dropdown has a minimum width based on the longest option
                              dynamicWidth =
                                  textPainter.width + 50; // Add padding
                            }

                            // Ensure the dropdown width is at least 150px or the width of the screen
                            dynamicWidth =
                                dynamicWidth < 150 ? 150 : dynamicWidth;
                            dynamicWidth =
                                dynamicWidth < width ? dynamicWidth : width / 2;

                            // Calculate the dynamic height based on the number of options
                            double dynamicHeight =
                                options.length * 60.0; // Height per item

                            // Limit height to 200 pixels (for a reasonable dropdown height)
                            dynamicHeight =
                                dynamicHeight < 200 ? dynamicHeight : 200;

                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                child: Container(
                                  width:
                                      dynamicWidth, // Dynamic width for the dropdown
                                  height: dynamicHeight,
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(option),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 8),
                      Expanded(
                        child: RawAutocomplete<String>(
                          textEditingController: _endDateController,
                          focusNode: FocusNode(),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            // Show all options if there's no text
                            if (textEditingValue.text.isEmpty) {
                              return endDateList; // Return all end date options
                            }
                            // Filter options when text is typed
                            return endDateList.where((String option) {
                              return option.contains(
                                textEditingValue.text,
                              ); // Filter by the entered text
                            }).toList();
                          },
                          fieldViewBuilder: (
                            context,
                            controller,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            return _buildBoxedTextField(
                              controller,
                              'End Date',
                              focusNode: focusNode,
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            final width = MediaQuery.of(context).size.width;

                            // Calculate dynamic width based on the longest option
                            double dynamicWidth = width / 3.5;

                            if (options.isNotEmpty) {
                              String longestOption = options.reduce(
                                (a, b) => a.length > b.length ? a : b,
                              );

                              final textPainter = TextPainter(
                                text: TextSpan(
                                  text: longestOption,
                                  style: TextStyle(fontSize: 16),
                                ),
                                textDirection: TextDirection.ltr,
                              )..layout();

                              dynamicWidth = textPainter.width + 32;
                            }

                            dynamicWidth =
                                dynamicWidth < 150 ? 150 : dynamicWidth;
                            dynamicWidth =
                                dynamicWidth < width ? dynamicWidth : width / 2;

                            // Calculate height
                            double dynamicHeight = options.length * 60.0;
                            dynamicHeight =
                                dynamicHeight < 200 ? dynamicHeight : 200;

                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                child: Container(
                                  width: dynamicWidth,
                                  height: dynamicHeight,
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(option),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 4: Office and Address
                  Row(
                    children: [
                      Expanded(
                        child: RawAutocomplete<String>(
                          textEditingController: _officeController,
                          focusNode: FocusNode(),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return officeList; // All options
                            }
                            return officeList.where((String option) {
                              return option.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              );
                            }).toList();
                          },
                          fieldViewBuilder: (
                            context,
                            controller,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            return _buildBoxedTextField(
                              controller,
                              'Office',
                              focusNode: focusNode,
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            final width = MediaQuery.of(context).size.width;

                            // Estimate dropdown width
                            double dynamicWidth = width / 3.5;

                            if (options.isNotEmpty) {
                              String longestOption = options.reduce(
                                (a, b) => a.length > b.length ? a : b,
                              );

                              final textPainter = TextPainter(
                                text: TextSpan(
                                  text: longestOption,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                textDirection: TextDirection.ltr,
                              )..layout();

                              dynamicWidth = textPainter.width + 60;
                            }

                            dynamicWidth =
                                dynamicWidth < 150 ? 150 : dynamicWidth;
                            dynamicWidth =
                                dynamicWidth < width ? dynamicWidth : width / 2;

                            double dynamicHeight = options.length * 60.0;
                            dynamicHeight =
                                dynamicHeight < 200 ? dynamicHeight : 200;

                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                child: Container(
                                  width: dynamicWidth,
                                  height: dynamicHeight,
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(option),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 8),
                      Expanded(
                        child: RawAutocomplete<String>(
                          textEditingController: _addressController,
                          focusNode: FocusNode(),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return addressList; // Return all address options
                            }
                            return addressList.where((String option) {
                              return option.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              );
                            }).toList();
                          },
                          fieldViewBuilder: (
                            context,
                            controller,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            return _buildBoxedTextField(
                              controller,
                              'Address',
                              focusNode: focusNode,
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            final width = MediaQuery.of(context).size.width;

                            // Estimate dropdown width based on the longest string
                            double dynamicWidth = width / 3.5;

                            if (options.isNotEmpty) {
                              String longestOption = options.reduce(
                                (a, b) => a.length > b.length ? a : b,
                              );

                              final textPainter = TextPainter(
                                text: TextSpan(
                                  text: longestOption,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                textDirection: TextDirection.ltr,
                              )..layout();

                              dynamicWidth = textPainter.width + 60;
                            }

                            dynamicWidth =
                                dynamicWidth < 150 ? 150 : dynamicWidth;
                            dynamicWidth =
                                dynamicWidth < width ? dynamicWidth : width / 2;

                            double dynamicHeight = options.length * 60.0;
                            dynamicHeight =
                                dynamicHeight < 200 ? dynamicHeight : 200;

                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                child: Container(
                                  width: dynamicWidth,
                                  height: dynamicHeight,
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(option),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirm Deletion'),
                                content: const Text(
                                  'Are you sure you want to delete this student? This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(true),
                                    child: const Text(
                                      'Yes, Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirm == true) {
                            _deleteStudent();
                            Navigator.of(context).pop();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TablePage(),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _saveChanges();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Changes saved successfully!'),
                            ),
                          );
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Close icon
          Positioned(
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxedTextField(
    TextEditingController controller,
    String label, {
    TextInputType type = TextInputType.text,
    FocusNode? focusNode, // ✅ added support
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode, // ✅ assign if provided
        keyboardType: type,
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
      ),
    );
  }
}
