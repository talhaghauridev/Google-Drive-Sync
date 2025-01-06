import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
        _listGoogleDriveFiles();
      }
    } catch (e) {
      print('Silent sign-in error: $e');
      await storage.write(key: "signedIn", value: "false");
      setState(() => signedIn = false);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      googleSignInAccount = await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        await storage.write(key: "signedIn", value: "true");
        setState(() => signedIn = true);
        await _listGoogleDriveFiles();
      }
    } catch (error) {
      print('Sign in error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in: $error')),
      );
    }
    setState(() => _isLoading = false);
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
    }
    setState(() => _isLoading = false);
  }

  Future<void> _uploadFileToGoogleDrive() async {
    if (googleSignInAccount == null) return;

    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null) {
        final file = File(result.files.single.path!);
        var client = GoogleAuthClient(await googleSignInAccount!.authHeaders);
        var drive = ga.DriveApi(client);

        var driveFile = ga.File();
        driveFile.name = path.basename(file.path);

        var response = await drive.files.create(
          driveFile,
          uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
        );

        print('File uploaded: ${response.name}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File uploaded successfully')),
        );

        await _listGoogleDriveFiles();
      }
    } catch (e) {
      print('Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload file')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _listGoogleDriveFiles() async {
    if (googleSignInAccount == null) return;

    setState(() => _isLoading = true);
    try {
      var client = GoogleAuthClient(await googleSignInAccount!.authHeaders);
      var drive = ga.DriveApi(client);
      var response = await drive.files.list(
        spaces: 'drive',
        $fields: 'files(id, name, mimeType, size, modifiedTime)',
      );
      setState(() => list = response);
    } catch (e) {
      print('List files error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to list files')),
      );
    }
    setState(() => _isLoading = false);
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
    } catch (e) {
      print('Download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download file')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Drive Files',
          style: TextStyle(color: Color(0xFFa2d39b)),
        ),
        actions: [
          if (signedIn)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _handleSignOut,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF90EE90)))
          : Padding(
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
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
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
                            children: [
                              if (list != null && list!.files != null) ...[
                                Text(
                                  'Your Drive Files',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                SizedBox(height: 16),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: list!.files!.length,
                                    itemBuilder: (context, index) {
                                      final file = list!.files![index];
                                      return Card(
                                        margin: EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          title: Text(
                                            file.name ?? 'Unnamed file',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          subtitle: Text(
                                            'Modified: ${file.modifiedTime?.toLocal() ?? 'Unknown'}',
                                            style:
                                                TextStyle(color: Colors.grey),
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(
                                              Icons.download,
                                              color: Color(0xFF90EE90),
                                            ),
                                            onPressed: () =>
                                                _downloadGoogleDriveFile(
                                              file.name ?? 'unknown',
                                              file.id ?? '',
                                            ),
                                          ),
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
    );
  }
}