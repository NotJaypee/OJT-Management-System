import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; // Import for PDF viewer
import 'package:path_provider/path_provider.dart'; // Import for path_provider

class PDFViewerPage extends StatefulWidget {
  final String pdfPath;
  final String program; // Add this line to accept the program name
  final String year; // Add this line to accept the year

  const PDFViewerPage({
    Key? key,
    required this.pdfPath,
    required this.program, // 👈 Add this
    required this.year, // 👈 Add this
  }) : super(key: key);

  @override
  _PDFViewerPageState createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  bool _isHovered = false;

  Future<Directory?> getDownloadDirectory() async {
    if (Platform.isWindows) {
      return Directory('${Platform.environment['USERPROFILE']}\\Downloads');
    } else if (Platform.isMacOS) {
      return await getDownloadsDirectory(); // from path_provider
    } else if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getExternalStorageDirectory();
      if (dir == null) return null;

      final downloads = Directory('${dir.path}/Download');
      if (!(await downloads.exists())) {
        await downloads.create(recursive: true);
      }
      return downloads;
    } else {
      return null;
    }
  }

  Future<void> _downloadCertificate(BuildContext context) async {
    try {
      final File sourceFile = File(widget.pdfPath);
      if (!await sourceFile.exists()) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Source file does not exist.')));
        return;
      }

      final downloadsDir = await getDownloadDirectory();
      if (downloadsDir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot access Downloads folder.')),
        );
        return;
      }

      final String selectedProgram = widget.program;
      final String selectedYear = widget.year;

      String baseName;

      // Check both program and year are provided
      if (selectedProgram == 'All' && selectedYear == 'All') {
        baseName = 'On_the_Job_Training_Certificate';
      } else if (selectedProgram.isNotEmpty && selectedYear.isNotEmpty) {
        baseName =
            '${selectedProgram.replaceAll(" ", "_")}_${selectedYear}_Certificate';
      } else {
        baseName = '${selectedProgram.replaceAll(" ", "_")}_Certificate';
      }

      final String extension = '.pdf';

      String newPath =
          '${downloadsDir.path}${Platform.pathSeparator}$baseName$extension';
      int counter = 1;

      // Check if file exists and generate a unique name
      while (await File(newPath).exists()) {
        newPath =
            '${downloadsDir.path}${Platform.pathSeparator}${baseName}_$counter$extension';
        counter++;
      }

      await sourceFile.copy(newPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Certificate downloaded to: ${newPath.split(Platform.pathSeparator).last}',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading certificate: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!File(widget.pdfPath).existsSync()) {
      return Scaffold(
        appBar: AppBar(title: const Text('View Certificate')),
        body: Center(child: Text('PDF file not found at ${widget.pdfPath}')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('View Certificate')),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SfPdfViewer.file(
                  File(widget.pdfPath),
                  interactionMode: PdfInteractionMode.pan,
                  canShowScrollHead: false,
                  canShowScrollStatus: false,
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => _downloadCertificate(context),
              child: MouseRegion(
                onEnter: (_) {
                  setState(() {
                    _isHovered = true;
                  });
                },
                onExit: (_) {
                  setState(() {
                    _isHovered = false;
                  });
                },
                child: Stack(
                  clipBehavior: Clip.none, // Ensure it doesn't clip the tooltip
                  children: [
                    // Tooltip for hover text
                    if (_isHovered)
                      Positioned(
                        bottom:
                            50, // Adjust this to control the vertical distance of the text
                        right: 0, // Adjust position of the text horizontally
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            color: Colors.black.withOpacity(
                              0.8,
                            ), // Dark background for the tooltip
                            child: Text(
                              'Generate Certificate',
                              style: TextStyle(
                                color: Colors.white, // White text
                                fontWeight: FontWeight.bold,
                                fontSize: 14, // Font size
                              ),
                            ),
                          ),
                        ),
                      ),
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          _isHovered
                              ? Colors.blue
                              : Colors.lightBlue, // Change color on hover
                      child: Icon(
                        Icons.download,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
