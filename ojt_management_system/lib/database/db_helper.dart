import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ojt_management_system/utils/student_model.dart';

class DBHelper {
  static Database? _database;

  // Get the database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Initialize the database
  static Future<Database> _initDB() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ojt_management.db');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 5, // Updated version to 5
        onCreate: (db, version) async {
          print('📦 Creating students table...');
          await db.execute(''' 
            CREATE TABLE students (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              first_name TEXT,
              middle_initial TEXT,
              last_name TEXT,
              program TEXT,
              school TEXT,
              ojt_hours TEXT,
              start_date TEXT,
              end_date TEXT,
              office TEXT,
              address TEXT,
              qr_link TEXT,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          print('📦 Creating qr_codes table...');
          await db.execute(''' 
            CREATE TABLE qr_codes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              program TEXT,
              school TEXT,
              year INTEGER,
              file_url TEXT,
              qr_image_path TEXT
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            print('⬆️ Upgrading to version 2: Creating qr_codes table...');
            await db.execute(''' 
              CREATE TABLE qr_codes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                program TEXT,
                year INTEGER,
                file_url TEXT,
                qr_image_path TEXT
              )
            ''');
          }

          if (oldVersion < 3) {
            print(
              '⬆️ Upgrading to version 3: Adding "school" column to qr_codes...',
            );
            try {
              await db.execute('ALTER TABLE qr_codes ADD COLUMN school TEXT');
            } catch (e) {
              print(
                '⚠️ Could not alter qr_codes table (maybe already has school): $e',
              );
            }
          }

          if (oldVersion < 4) {
            print(
              '⬆️ Upgrading to version 4: Adding "qr_link" column to students...',
            );
            try {
              await db.execute('ALTER TABLE students ADD COLUMN qr_link TEXT');
            } catch (e) {
              print(
                '⚠️ Could not alter students table (maybe already has qr_link): $e',
              );
            }
          }

          if (oldVersion < 5) {
            print(
              '⬆️ Upgrading to version 5: Adding "created_at" column to students...',
            );
            try {
              await db.execute(
                'ALTER TABLE students ADD COLUMN created_at TEXT DEFAULT CURRENT_TIMESTAMP',
              );
            } catch (e) {
              print(
                '⚠️ Could not alter students table (maybe already has created_at): $e',
              );
            }
          }
        },
      ),
    );
  }

  // Insert a student
  static Future<int> insertStudent(Map<String, dynamic> student) async {
    final db = await database;
    return await db.insert('students', student);
  }

  // Fetch all students
  static Future<List<Map<String, dynamic>>> getStudents() async {
    final db = await database;
    return await db.query('students');
  }

  // Get all students as model
  static Future<List<Student>> getAllStudents() async {
    final db = await database;
    final List<Map<String, dynamic>> studentMaps = await db.query('students');

    return List.generate(studentMaps.length, (i) {
      return Student.fromMap(studentMaps[i]);
    });
  }

  // Get all unique programs
  static Future<List<String>> getAllPrograms() async {
    final db = await database;
    final List<Map<String, dynamic>> programMaps = await db.rawQuery(
      'SELECT DISTINCT program FROM students',
    );

    return List.generate(programMaps.length, (i) {
      return programMaps[i]['program'] as String;
    });
  }

  // Instance method version of program fetcher
  Future<List<String>> getPrograms() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT DISTINCT program FROM students',
    );
    return results.map((row) => row['program'] as String).toList();
  }

  // Get unique end years
  Future<List<int>> getEndDates() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''SELECT DISTINCT 
        substr(end_date, -4) AS year 
        FROM students 
        WHERE end_date IS NOT NULL AND length(end_date) >= 4
      ''',
    );

    return result
        .map((row) => int.tryParse(row['year']) ?? 0)
        .where((year) => year > 0)
        .toSet()
        .toList();
  }

  // Get all unique schools
  Future<List<String>> getSchools() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT DISTINCT school FROM students',
    );
    return results.map((row) => row['school'] as String).toList();
  }

  // Insert QR code entry
  static Future<void> insertQRCode(Map<String, dynamic> qrData) async {
    final db = await DBHelper.database;
    await db.insert(
      'qr_codes',
      qrData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Fetch QR code entry for a specific student (program, school, and year)
  static Future<Map<String, dynamic>?> getQRCodeForStudent({
    required String program,
    required String school,
    required int year,
  }) async {
    final db = await database;

    final result = await db.query(
      'qr_codes',
      where: 'program = ? AND school = ? AND year = ?',
      whereArgs: [program, school, year],
      orderBy: 'id DESC', // 👈 Make sure 'id' is the auto-increment column
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  static Future<List<Map<String, dynamic>>> getAllQRCodes() async {
    final db = await DBHelper.database;
    return await db.query('qr_codes');
  }

  static Future<void> updateStudent(Student student) async {
    final db = await database; // Assuming you're using a database object
    // Update student without passing created_at field
    await db.update(
      'students',
      student.toMap()..remove(
        'created_at',
      ), // Remove created_at from the Map if it's included
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  // Make this method non-static
  static Future<void> deleteStudent(int studentId) async {
    final db = await database; // Assuming you're using a database object
    await db.delete(
      'students', // The name of your table
      where: 'id = ?',
      whereArgs: [studentId], // Using the student ID to delete the record
    );
  }

  static Future<List<String>> getDistinctPrograms() async {
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT program FROM students');
    return result
        .map((row) => row['program'] as String)
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static Future<List<String>> getDistinctSchools() async {
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT school FROM students');
    return result
        .map((row) => row['school'] as String)
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<List<String>> getDistinctOJTHours() async {
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT ojt_hours FROM students');
    return result.map((e) => e['ojt_hours'].toString()).toList();
  }

  Future<List<String>> getDistinctStartDates() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT start_date FROM students',
    );
    return result.map((e) => e['start_date'].toString()).toList();
  }

  Future<List<String>> getDistinctEndDates() async {
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT end_date FROM students');
    return result.map((e) => e['end_date'].toString()).toList();
  }

  static Future<List<String>> getDistinctOffices() async {
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT office FROM students');
    return result.map((e) => e['office'].toString()).toList();
  }

  static Future<List<String>> getDistinctAddresses() async {
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT address FROM students');
    return result.map((e) => e['address'].toString()).toList();
  }

  static Future<List<String>> getDistinctYears() async {
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT end_date FROM students');

    final years = <String>{}; // Use a set to automatically remove duplicates

    for (var e in result) {
      final endDate = e['end_date'] as String?;
      if (endDate != null && endDate.trim().isNotEmpty) {
        try {
          final year =
              DateFormat('MMMM d, yyyy').parse(endDate).year.toString();
          years.add(year);
        } catch (e) {
          // Skip if endDate is not in the expected format
          continue;
        }
      }
    }

    final sortedYears = years.toList()..sort();
    return sortedYears;
  }

  static Future<List<Map<String, dynamic>>> exportStudents() async {
    final db = await database;
    final result = await db.query(
      'students',
      columns: [
        'id',
        'first_name',
        'middle_initial',
        'last_name',
        'program',
        'school',
        'ojt_hours',
        'start_date',
        'end_date',
        'office',
        'address',
      ],
    );
    return result;
  }

  static Future<void> importStudents(
    List<Map<String, dynamic>> students,
  ) async {
    final db = await database;
    for (var student in students) {
      await db.insert('students', {
        'first_name': student['first_name'],
        'middle_initial': student['middle_initial'],
        'last_name': student['last_name'],
        'program': student['program'],
        'school': student['school'],
        'ojt_hours': student['ojt_hours'],
        'start_date': student['start_date'],
        'end_date': student['end_date'],
        'office': student['office'],
        'address': student['address'],
      });
    }
  }

  static Future<void> clearStudents() async {
    final db = await DBHelper.database;
    await db.delete('students');
  }

  // Add a new student to the database
  static Future<void> addStudent(
    String firstName,
    String middleInitial,
    String lastName,
    String program,
    String school,
    String ojtHours,
    String startDate,
    String endDate,
    String office,
    String address,
  ) async {
    final db =
        await database; // Assuming 'database' is your reference to the SQLite DB instance

    try {
      await db.insert(
        'students', // Table name
        {
          'first_name': firstName,
          'middle_initial': middleInitial,
          'last_name': lastName,
          'program': program,
          'school': school,
          'ojt_hours': ojtHours,
          'start_date': startDate,
          'end_date': endDate,
          'office': office,
          'address': address,
        },
        conflictAlgorithm:
            ConflictAlgorithm.ignore, // This avoids overwriting existing data
      );
    } catch (e) {
      print("Error adding student: $e");
    }
  }

  // Check if a student already exists in the database
  static Future<bool> checkIfStudentExists(
    String firstName,
    String middleInitial,
    String lastName,
    String school,
  ) async {
    final db =
        await database; // Assuming 'database' is your reference to the SQLite DB instance

    try {
      var result = await db.query(
        'students', // Table name
        where:
            'first_name = ? AND middle_initial = ? AND last_name = ? AND school = ?', // SQL condition
        whereArgs: [
          firstName,
          middleInitial,
          lastName,
          school,
        ], // Values for the placeholders
      );

      return result
          .isNotEmpty; // Returns true if any records match, meaning the student exists
    } catch (e) {
      print("Error checking if student exists: $e");
      return false; // Returns false if there’s an error
    }
  }
}
