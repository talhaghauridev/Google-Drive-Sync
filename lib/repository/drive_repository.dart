// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'package:file_upload_app/models/drive_model.dart';
import 'package:file_upload_app/services/storage_service.dart';
import 'package:file_upload_app/utils/google_auth_client.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

final List<String> scopes = [
  "https://www.googleapis.com/auth/drive.file",
  "https://www.googleapis.com/auth/drive.appdata"
];

class DriveRepository {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: scopes);
  final _storage = StorageService();
  GoogleSignInAccount? _currentUser;
  ga.DriveApi? _driveApi;

  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        // ignore: unused_local_variable
        final auth = await _currentUser!.authentication;
        final client = GoogleAuthClient(await _currentUser!.authHeaders);
        _driveApi = ga.DriveApi(client);
        await _saveUserData(_currentUser!);
        return true;
      }
      return false;
    } catch (e) {
      print('Sign in error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _googleSignIn.signOut(),
      _storage.clearStorage(),
    ]);
    _currentUser = null;
    _driveApi = null;
  }

  Future<bool> checkSignInStatus() async {
    final isSignedIn = await _storage.getSignInStatus();
    if (isSignedIn) {
      return silentSignIn();
    }
    return false;
  }

  Future<bool> silentSignIn() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        // ignore: unused_local_variable
        final auth = await _currentUser!.authentication;
        final client = GoogleAuthClient(await _currentUser!.authHeaders);
        _driveApi = ga.DriveApi(client);

        // Save user data
        await _saveUserData(_currentUser!);
        return true;
      }
      return false;
    } catch (e) {
      print('Silent sign-in error: $e');
      return false;
    }
  }

  Future<void> _saveUserData(GoogleSignInAccount user) async {
    final userData = {
      'email': user.email,
      'displayName': user.displayName ?? '',
      'id': user.id,
      'photoUrl': user.photoUrl ?? '',
    };
    await _storage.saveUserData(userData);
  }

  Future<List<DriveFileModel>> listFiles() async {
    if (_driveApi == null) throw Exception('Not signed in');

    final response = await _driveApi!.files.list(
      spaces: 'drive',
      $fields: 'files(id, name, mimeType, modifiedTime, thumbnailLink)',
      orderBy: 'modifiedTime desc',
    );

    return response.files
            ?.map((file) => DriveFileModel.fromGoogleFile(file))
            .toList() ??
        [];
  }

  Future<void> uploadFile(File file) async {
    if (_driveApi == null) throw Exception('Not signed in');

    var driveFile = ga.File()
      ..name = path.basename(file.path)
      ..modifiedTime = DateTime.now().toUtc();

    await _driveApi!.files.create(
      driveFile,
      uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
    );
  }

  Future<void> createFolder(String name) async {
    if (_driveApi == null) throw Exception('Not signed in');

    var folder = ga.File()
      ..name = name
      ..mimeType = 'application/vnd.google-apps.folder';

    await _driveApi!.files.create(folder);
  }

  Future<void> downloadFile(String fileId, String fileName) async {
    if (_driveApi == null) throw Exception('Not signed in');

    ga.Media file = await _driveApi!.files
        .get(fileId, downloadOptions: ga.DownloadOptions.fullMedia) as ga.Media;

    final directory = await getApplicationDocumentsDirectory();
    final saveFile = File(
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName');

    List<int> dataStore = [];
    await for (final data in file.stream) {
      dataStore.addAll(data);
    }

    await saveFile.writeAsBytes(dataStore);
  }
}