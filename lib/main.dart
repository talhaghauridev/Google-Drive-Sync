import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Drive Integration',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'Google Drive Integration'),
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

class MyHomePage extends StatefulWidget {
  MyHomePage({required this.title});
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final storage = FlutterSecureStorage();
  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive',
    ],
  );
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
        title: Text(widget.title),
        actions: [
          if (signedIn)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _handleSignOut,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!signedIn)
                      ElevatedButton.icon(
                        icon: Icon(Icons.login),
                        label: Text('Sign in with Google Drive'),
                        onPressed: _handleSignIn,
                      )
                    else ...[
                      ElevatedButton.icon(
                        icon: Icon(Icons.upload_file),
                        label: Text('Upload File'),
                        onPressed: _uploadFileToGoogleDrive,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: Icon(Icons.refresh),
                        label: Text('Refresh File List'),
                        onPressed: _listGoogleDriveFiles,
                      ),
                      SizedBox(height: 16),
                      if (list != null && list!.files != null) ...[
                        Text(
                          'Files in Drive',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 8),
                        ...list!.files!
                            .map((file) => Card(
                                  margin: EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(file.name ?? 'Unnamed file'),
                                    subtitle: Text(
                                      'Modified: ${file.modifiedTime?.toLocal() ?? 'Unknown'}',
                                    ),
                                    trailing: ElevatedButton.icon(
                                      icon: Icon(Icons.download),
                                      label: Text('Download'),
                                      onPressed: () => _downloadGoogleDriveFile(
                                        file.name ?? 'unknown',
                                        file.id ?? '',
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
