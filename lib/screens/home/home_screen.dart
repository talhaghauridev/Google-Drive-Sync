import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:file_upload_app/widgets/drive_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final storage = FlutterSecureStorage();
  final GoogleSignIn googleSignIn = GoogleSignIn(scopes: [
    "https://www.googleapis.com/auth/drive",
    "https://www.googleapis.com/auth/drive.file",
    "https://www.googleapis.com/auth/drive.appdata"
  ]);
  GoogleSignInAccount? googleSignInAccount;
  ga.FileList? list;
  bool _isLoading = false;
  bool signedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    signedIn = await storage.read(key: "signedIn") == "true";
    if (signedIn) {
      _silentSignIn();
    }
  }

  Future<void> _silentSignIn() async {
    setState(() => _isLoading = true);
    try {
      googleSignInAccount = await googleSignIn.signInSilently();
      if (googleSignInAccount != null) {
        setState(() => signedIn = true);
        await _listGoogleDriveFiles();
      }
    } catch (e) {
      print('Silent sign-in error: $e');
      await storage.write(key: "signedIn", value: "false");
      setState(() => signedIn = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      googleSignInAccount = await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final auth = await googleSignInAccount!.authentication;
        String? accessToken = auth.accessToken;
        print('Access token: $accessToken');
        await storage.write(key: "signedIn", value: "true");
        setState(() => signedIn = true);
        await _listGoogleDriveFiles();
      }
    } catch (error) {
      print('Sign in error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    try {
      await googleSignIn.signOut();
      await storage.write(key: "signedIn", value: "false");
      setState(() {
        signedIn = false;
        list = null;
        googleSignInAccount = null;
      });
    } catch (error) {
      print('Sign out error: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadFileToGoogleDrive() async {
    if (googleSignInAccount == null) {
      print('Error: No signed in account');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null) {
        print('File selected: ${result.files.single.name}');
        final file = File(result.files.single.path!);
        var client = GoogleAuthClient(await googleSignInAccount!.authHeaders);
        var drive = ga.DriveApi(client);

        var driveFile = ga.File()
          ..name = path.basename(file.path)
          ..modifiedTime = DateTime.now().toUtc();

        print('Starting upload: ${driveFile.name}');
        var response = await drive.files.create(
          driveFile,
          uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
        );

        print('Upload successful. File ID: ${response.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File uploaded successfully')),
        );

        await _listGoogleDriveFiles();
      }
    } catch (e, stackTrace) {
      print('Upload error: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _listGoogleDriveFiles() async {
    if (googleSignInAccount == null) {
      print('Error: No signed in account');
      return;
    }

    setState(() => _isLoading = true);
    try {
      var client = GoogleAuthClient(await googleSignInAccount!.authHeaders);
      print('Auth Headers: ${await googleSignInAccount!.authHeaders}');

      var drive = ga.DriveApi(client);
      var response = await drive.files.list(
        spaces: 'drive',
        $fields: 'files(id, name, mimeType, size, modifiedTime)',
        orderBy: 'modifiedTime desc',
        pageSize: 20,
      );

      print('Files found: ${response.files?.length ?? 0}');
      setState(() => list = response);
    } catch (e, stackTrace) {
      print('List files error: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to list files: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadGoogleDriveFile(String fileName, String fileId) async {
    if (googleSignInAccount == null) return;

    setState(() => _isLoading = true);
    try {
      var client = GoogleAuthClient(await googleSignInAccount!.authHeaders);
      var drive = ga.DriveApi(client);

      ga.Media file = await drive.files.get(fileId,
          downloadOptions: ga.DownloadOptions.fullMedia) as ga.Media;

      final directory = await getApplicationDocumentsDirectory();
      final saveFile = File(
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName');

      List<int> dataStore = [];
      await for (final data in file.stream) {
        dataStore.addAll(data);
      }

      await saveFile.writeAsBytes(dataStore);
      print('File saved at ${saveFile.path}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File downloaded successfully')),
      );
    } catch (e, stackTrace) {
      print('Download error: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download file')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Color(0xFF0F140E),
        leadingWidth: 72,
        title: Padding(
          padding: EdgeInsets.only(left: 8),
          child: Text('Drive Files', style: TextStyle(fontSize: 25)),
        ),
        centerTitle: true,
        actions: [
          if (signedIn)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: IconButton(
                icon: Icon(Icons.logout, color: Color(0xFFa2d39b)),
                onPressed: _handleSignOut,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF90EE90)))
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Expanded(
                      child: !signedIn
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Connect to Google Drive',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 40),
                                ElevatedButton(
                                  onPressed: _handleSignIn,
                                  child: Text('Connect to Google Drive'),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (list != null && list!.files != null) ...[
                                  Padding(
                                    padding:
                                        EdgeInsets.only(top: 16, bottom: 16),
                                    child: Text(
                                      'Your Drive Files',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                  ),
                                  Expanded(
                                    child: list!.files!.isEmpty
                                        ? Center(
                                            child: Text(
                                              'No files found',
                                              style:
                                                  TextStyle(color: Colors.grey),
                                            ),
                                          )
                                        : ListView.builder(
                                            itemCount: list!.files!.length,
                                            itemBuilder: (context, index) {
                                              final file = list!.files![index];
                                              return DriveFileCard(
                                                fileName:
                                                    file.name ?? 'Unnamed file',
                                                modifiedDate:
                                                    'Modified: ${file.modifiedTime?.toLocal() ?? 'Unknown'}',
                                                onDownload: () =>
                                                    _downloadGoogleDriveFile(
                                                  file.name ?? 'unknown',
                                                  file.id ?? '',
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: signedIn
          ? FloatingActionButton(
              backgroundColor: Color(0xFFa2d39b),
              child: Icon(Icons.upload_file, color: Colors.black),
              onPressed: _uploadFileToGoogleDrive,
            )
          : null,
    );
  }
}
