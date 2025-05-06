import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/widgets.dart';
import 'package:ojt_management_system/utils/google_drive_uploader.dart';
import 'package:ojt_management_system/utils/save_qr_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ojt_management_system/database/db_helper.dart';
import 'package:ojt_management_system/utils/student_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:xml/xml.dart';
import 'dart:core';

class WordExportService {
  static Future<void> generateAndUploadGroupedWordFiles(
    BuildContext context,
    String driveFolderLink, {
    String? programFilter,
    String? yearFilter,
    String? schoolFilter,
  }) async {
    final db = await DBHelper.database;

    // Extract folder ID from Google Drive link
    String extractFolderId(String url) {
      final regex = RegExp(r'drive\/folders\/([a-zA-Z0-9_-]+)');
      final match = regex.firstMatch(url);
      return match != null ? match.group(1)! : url; // fallback to raw input
    }

    final folderId = extractFolderId(driveFolderLink);
    print("📂 Using Google Drive folder ID: $folderId");

    // Fetch all students from DB
    final List<Map<String, dynamic>> studentMaps = await db.query('students');
    final List<Student> allStudents =
        studentMaps.map((map) => Student.fromMap(map)).toList();

    print("📋 Total students in DB: ${allStudents.length}");
    for (var student in allStudents) {
      print(
        "↪️ ${student.firstName} ${student.lastName} | Program: ${student.program} | School: ${student.school} | EndDate: ${student.endDate}",
      );
    }

    // Apply filters
    final filteredStudents =
        allStudents.where((student) {
          final matchesProgram =
              programFilter == null ||
              programFilter == 'All' ||
              student.program == programFilter;

          final studentYear =
              student.endDate.contains(',')
                  ? student.endDate.split(',').last.trim()
                  : 'Unknown';
          final matchesYear =
              yearFilter == null ||
              yearFilter == 'All' ||
              studentYear == yearFilter;

          final matchesSchool =
              schoolFilter == null ||
              schoolFilter == 'All' ||
              student.school == schoolFilter;

          return matchesProgram && matchesYear && matchesSchool;
        }).toList();

    print("🎯 Filtered students: ${filteredStudents.length}");
    if (filteredStudents.isEmpty) {
      print("❌ No students match the selected filters.");
      return;
    }

    for (var s in filteredStudents) {
      print(
        "✅ ${s.firstName} ${s.lastName} | ${s.program}, ${s.school}, ${s.endDate}",
      );
    }

    // Group students by Program and Year
    final Map<String, List<Student>> grouped = {};
    for (var student in filteredStudents) {
      final year =
          student.endDate.contains(',')
              ? student.endDate.split(',').last.trim()
              : 'Unknown';
      final key = '${student.program}_$year';
      grouped.putIfAbsent(key, () => []).add(student);
    }

    // Generate, Upload, and Save QR Code for each group
    for (var entry in grouped.entries) {
      final groupKey = entry.key;
      final groupStudents = entry.value;

      try {
        print("📝 Generating Word file for: $groupKey...");
        final docx = await _generateWordFile(groupKey, groupStudents);
        print("✅ Word file created: ${docx.path}");

        // Upload to Google Drive
        final uploadedLink = await GoogleDriveUploader.uploadFileToDrive(
          context,
          folderId,
          docx,
        );

        if (uploadedLink != null) {
          print("✅ File uploaded to Google Drive for group: $groupKey");

          // Extract program and year from key
          final parts = groupKey.split('_');
          final program = parts.first;
          final year = parts.length > 1 ? parts.last : 'Unknown';

          // Validate QR Code URL
          print("🔍 Validating QR code for URL: $uploadedLink");

          final qrValidationResult = QrValidator.validate(
            data: uploadedLink,
            version: QrVersions.auto,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
          );

          if (qrValidationResult.isValid) {
            print("✅ QR code is valid for URL: $uploadedLink");
          } else {
            print("❌ QR code is invalid for URL: $uploadedLink");
          }

          // Save QR code to Downloads and Database
          await SaveQRCodePage.saveQRCodeForFile(
            program: program,
            year: year,
            fileUrl: uploadedLink,
            school: schoolFilter ?? 'Unknown', // ✅
          );

          print("🎉 QR Code saved for $program $year (Downloads & Database)");
        } else {
          print("❌ Failed to get uploaded link for group: $groupKey");
        }
      } catch (e) {
        print("❌ Error processing group $groupKey: $e");
      }
    }
  }

  static Future<File> _generateWordFile(
    String groupKey,
    List<Student> students,
  ) async {
    try {
      // Create a blank docx using archive and XML
      final builder = XmlBuilder();
      builder.processing('xml', 'version="1.0" encoding="UTF-8"');
      builder.element(
        'w:document',
        nest: () {
          builder.attribute(
            'xmlns:w',
            'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
          );
          builder.element(
            'w:body',
            nest: () {
              // Title (bold)
              builder.element(
                'w:p',
                nest: () {
                  builder.element(
                    'w:r',
                    nest: () {
                      builder.element(
                        'w:rPr',
                        nest: () {
                          builder.element('w:b');
                        },
                      );
                      builder.element(
                        'w:t',
                        nest: () {
                          final program = students.first.program;
                          final startDate = students.first.startDate;
                          final endDate = students.first.endDate;
                          final titleText = '$program $startDate - $endDate';
                          builder.text(titleText);
                        },
                      );
                    },
                  );
                },
              );

              // Table
              builder.element(
                'w:tbl',
                nest: () {
                  // Table borders
                  builder.element(
                    'w:tblPr',
                    nest: () {
                      builder.element(
                        'w:tblBorders',
                        nest: () {
                          [
                            'top',
                            'left',
                            'bottom',
                            'right',
                            'insideH',
                            'insideV',
                          ].forEach((side) {
                            builder.element(
                              'w:$side',
                              nest: () {
                                builder.attribute('w:val', 'single');
                                builder.attribute('w:size', '4');
                              },
                            );
                          });
                        },
                      );
                    },
                  );

                  // Table header row
                  List<String> headers = ['No. ', 'Name', 'Program', 'School'];
                  builder.element(
                    'w:tr',
                    nest: () {
                      for (var header in headers) {
                        builder.element(
                          'w:tc',
                          nest: () {
                            builder.element(
                              'w:p',
                              nest: () {
                                builder.element(
                                  'w:pPr',
                                  nest: () {
                                    builder.element(
                                      'w:jc',
                                      nest: () {
                                        builder.attribute('w:val', 'center');
                                      },
                                    );
                                  },
                                );
                                builder.element(
                                  'w:r',
                                  nest: () {
                                    builder.element(
                                      'w:rPr',
                                      nest: () {
                                        builder.element('w:b'); // Bold
                                      },
                                    );
                                    builder.element(
                                      'w:t',
                                      nest: () {
                                        builder.text(header);
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      }
                    },
                  );

                  // Table data rows
                  int index = 1;
                  for (var student in students) {
                    builder.element(
                      'w:tr',
                      nest: () {
                        // No.
                        builder.element(
                          'w:tc',
                          nest: () {
                            builder.element(
                              'w:p',
                              nest: () {
                                builder.element(
                                  'w:r',
                                  nest: () {
                                    builder.element(
                                      'w:rPr',
                                      nest: () {
                                        builder.element(
                                          'w:sz',
                                          nest: () {
                                            builder.attribute('w:val', '24');
                                          },
                                        );
                                      },
                                    );
                                    builder.element(
                                      'w:t',
                                      nest: () {
                                        builder.text(
                                          '${index.toString()}.',
                                        ); // Added period here
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );

                        // Name
                        builder.element(
                          'w:tc',
                          nest: () {
                            builder.element(
                              'w:p',
                              nest: () {
                                builder.element(
                                  'w:r',
                                  nest: () {
                                    builder.element(
                                      'w:t',
                                      nest: () {
                                        final middleInitial =
                                            student.middleInitial.isNotEmpty
                                                ? '${student.middleInitial[0]}.'
                                                : '';
                                        builder.text(
                                          '${student.firstName} $middleInitial ${student.lastName}',
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );

                        // Program
                        builder.element(
                          'w:tc',
                          nest: () {
                            builder.element(
                              'w:p',
                              nest: () {
                                builder.element(
                                  'w:r',
                                  nest: () {
                                    builder.element(
                                      'w:t',
                                      nest: () {
                                        builder.text(student.program);
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );

                        // School
                        builder.element(
                          'w:tc',
                          nest: () {
                            builder.element(
                              'w:p',
                              nest: () {
                                builder.element(
                                  'w:r',
                                  nest: () {
                                    builder.element(
                                      'w:t',
                                      nest: () {
                                        builder.text(student.school);
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                    index++;
                  }
                },
              );
            },
          );
        },
      );

      final documentXml = builder.buildDocument().toXmlString(pretty: true);

      // Create archive for .docx
      final archive = Archive();

      archive.addFile(
        ArchiveFile(
          '[Content_Types].xml',
          0,
          utf8.encode('''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>'''),
        ),
      );

      archive.addFile(
        ArchiveFile(
          '_rels/.rels',
          0,
          utf8.encode('''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>'''),
        ),
      );

      archive.addFile(
        ArchiveFile('word/document.xml', 0, utf8.encode(documentXml)),
      );

      archive.addFile(
        ArchiveFile(
          'word/_rels/document.xml.rels',
          0,
          utf8.encode('''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
</Relationships>'''),
        ),
      );

      // Save .docx with unique filename if exists
      final encodedBytes = ZipEncoder().encode(archive)!;
      final dir = await _getDirectoryForSaving();
      String basePath = "${dir.path}\\$groupKey";
      String filePath = "$basePath.docx";
      int count = 1;
      while (await File(filePath).exists()) {
        filePath = "${basePath}_$count.docx";
        count++;
      }

      final file = File(filePath);
      print("💾 Saving file to: $filePath");
      await file.writeAsBytes(encodedBytes);

      if (await file.exists()) {
        print("✅ File successfully saved at $filePath");
        return file;
      } else {
        throw Exception("File could not be saved.");
      }
    } catch (e) {
      print("❌ Error during Word file generation: $e");
      rethrow;
    }
  }

  static Future<Directory> _getDirectoryForSaving() async {
    if (Platform.isWindows) {
      final path =
          '${Platform.environment['USERPROFILE']}\\Documents\\OJT_GeneratedDocs';
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  static Future<String> getFixedFilePath(
    String baseName,
    String extension,
  ) async {
    final dir = await _getDirectoryForSaving();
    String filePath = "${dir.path}\\$baseName$extension";
    return filePath; // No counter or uniqueness check
  }
}
