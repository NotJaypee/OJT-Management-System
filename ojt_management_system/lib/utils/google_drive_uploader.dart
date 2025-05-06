import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

class GoogleDriveUploader {
  // Fetch clientId and clientSecret from environment variables
  static final _clientId = dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  static final _clientSecret = dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '';
  static const List<String> _scopes = [drive.DriveApi.driveFileScope];

  /// Authenticates the user and returns an authorized Drive API instance
  static Future<drive.DriveApi> _authenticate(BuildContext context) async {
    // Check if the clientId or clientSecret is empty and throw an error if they are
    if (_clientId.isEmpty || _clientSecret.isEmpty) {
      throw Exception('Client ID or Client Secret is missing.');
    }

    final clientId = auth.ClientId(_clientId, _clientSecret);

    // Show "Authenticating..." dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Authentication Required"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  "Please authenticate your Google Account in the browser...",
                ),
              ],
            ),
          ),
    );

    try {
      // Launch authentication in external browser
      final client = await auth.clientViaUserConsent(clientId, _scopes, (
        url,
      ) async {
        // Launch the URL in an external browser
        if (await canLaunch(url)) {
          await launch(url, forceSafariVC: false, forceWebView: false);
        } else {
          throw 'Could not open the URL $url';
        }
      });

      // Return authenticated Google Drive API client
      return drive.DriveApi(client);
    } catch (e) {
      print("❌ Authentication error: $e");
      rethrow;
    } finally {
      // Close the dialog after authentication process
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  /// Uploads a file to the specified Google Drive folder
  static Future<String?> uploadFileToDrive(
    BuildContext context,
    String folderId,
    File fileToUpload,
  ) async {
    try {
      // Check if the folder ID looks valid
      if (!RegExp(r'^[\w-]{10,}$').hasMatch(folderId)) {
        print('❌ Invalid Google Drive folder ID: $folderId');
        throw Exception("Invalid Google Drive folder ID.");
      }

      // Authenticate user
      final driveApi = await _authenticate(context);

      // Prepare metadata for the file
      final driveFile =
          drive.File()
            ..name = path.basename(fileToUpload.path)
            ..parents = [folderId];

      final media = drive.Media(
        fileToUpload.openRead(),
        await fileToUpload.length(),
      );

      // Upload the file to Google Drive
      final uploadedFile = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      if (uploadedFile.id != null) {
        final fileUrl =
            'https://drive.google.com/file/d/${uploadedFile.id}/view?usp=drivesdk';
        print('✅ File uploaded to Google Drive: $fileUrl');
        return fileUrl;
      } else {
        print('⚠️ Upload attempted but no file ID was returned.');
        return null;
      }
    } catch (e) {
      print('❌ Failed to upload file: $e');
      return null;
    }
  }
}
