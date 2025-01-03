// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Drive App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((account) {
      print('User signed in: $account');
      setState(() {
        _currentUser = account;
      });
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _initializeDriveApi() async {
    final headers = await _currentUser!.authHeaders;
    final client = GoogleAuthClient(headers);
    _driveApi = drive.DriveApi(client);
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signOut();
      dynamic user = await _googleSignIn.signIn();
      print('User: $user');
    } catch (error) {
      print('Sign in error: $error');
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.signOut();
    setState(() {
      _currentUser = null;
      _driveApi = null;
    });
  }

  Future<void> _uploadFile() async {
    if (_driveApi == null) return;

    try {
      // Create a test file
      final directory = await getApplicationDocumentsDirectory();
      final testFile = File('${directory.path}/test.txt');
      await testFile.writeAsString('Test content');

      // Upload file metadata
      var driveFile = drive.File();
      driveFile.name = 'test.txt';

      // Upload the file
      final response = await _driveApi!.files.create(
        driveFile,
        uploadMedia: drive.Media(testFile.openRead(), testFile.lengthSync()),
      );

      print('File uploaded! ID: ${response.id}');
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Drive App'),
        actions: [
          if (_currentUser != null)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _handleSignOut,
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_currentUser == null)
              ElevatedButton(
                onPressed: _handleSignIn,
                child: Text('Sign in with Google'),
              )
            else
              Column(
                children: [
                  Text('Welcome ${_currentUser!.email}'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _uploadFile,
                    child: Text('Upload Test File'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

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
