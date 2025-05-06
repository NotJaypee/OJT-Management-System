import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ojt_management_system/database/db_helper.dart';

class SaveQRCodePage {
  static Future<void> saveQRCodeForFile({
    required String program,
    required String school,
    required String year,
    required String fileUrl,
  }) async {
    try {
      // Validate QR data
      final qrValidationResult = QrValidator.validate(
        data: fileUrl,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      );

      if (qrValidationResult.status != QrValidationStatus.valid) {
        throw Exception("Invalid QR code data.");
      }

      final qrCode = qrValidationResult.qrCode!;
      final qrPainter = QrPainter.withQr(
        qr: qrCode,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: true,
      );

      // Render QR code to image
      final qrImage = await qrPainter.toImage(300);
      final qrByteData = await qrImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final qrBytes = qrByteData!.buffer.asUint8List();

      // Load logo from assets
      final ByteData logoData = await rootBundle.load(
        'assets/images/pgp_logo.png',
      );
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final ui.Codec logoCodec = await ui.instantiateImageCodec(
        logoBytes,
        targetWidth: 60,
        targetHeight: 60,
      );
      final ui.FrameInfo logoFrame = await logoCodec.getNextFrame();
      final ui.Image logoImage = logoFrame.image;

      // Combine QR and logo onto new canvas
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final double size = 300;
      final paint = Paint();
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, size, size), bgPaint);

      // Draw QR code
      final ui.Codec qrCodec = await ui.instantiateImageCodec(qrBytes);
      final ui.FrameInfo qrFrame = await qrCodec.getNextFrame();
      canvas.drawImage(qrFrame.image, Offset.zero, paint);

      // Draw logo at center
      final double logoSize = 60;
      final Offset logoOffset = Offset(
        (size - logoSize) / 2,
        (size - logoSize) / 2,
      );
      final ui.Rect ovalRect = Rect.fromLTWH(
        logoOffset.dx,
        logoOffset.dy,
        logoSize,
        logoSize,
      );
      final Path clipPath = Path()..addOval(ovalRect);
      canvas.clipPath(clipPath);
      canvas.drawImage(logoImage, logoOffset, paint);

      // Finalize image
      final picture = recorder.endRecording();
      final ui.Image finalImage = await picture.toImage(300, 300);
      final ByteData? finalData = await finalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List finalBytes = finalData!.buffer.asUint8List();

      // Save to file
      final downloadsDir = await getDownloadsDirectory();
      final fileName = '${program}_${year}_qr.png'.replaceAll(' ', '_');
      final filePath = '${downloadsDir!.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(finalBytes);

      print("✅ QR Code with logo saved to: $filePath");

      // Save to DB
      await DBHelper.insertQRCode({
        'program': program,
        'school': school,
        'year': year,
        'file_url': fileUrl,
        'qr_image_path': filePath,
      });

      print("✅ QR code record saved in database.");
    } catch (e) {
      print("❌ Error saving QR with logo: $e");
    }
  }

  static Future<Directory?> getDownloadsDirectory() async {
    if (Platform.isWindows) {
      return Directory(
        'C:/Users/${Platform.environment['USERNAME']}/Downloads',
      );
    }
    return null;
  }
}
