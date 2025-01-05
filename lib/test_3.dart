import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_upload_app/googledrive-functions/googledrivehandler.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const GoogleDriveHandlerExampleApp(),
  );
}

class GoogleDriveHandlerExampleApp extends StatelessWidget {
  const GoogleDriveHandlerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});
  final String myApiKey = "YOUR_API_KEY";

  @override
  Widget build(BuildContext context) {
    GoogleDriveHandler().setAPIKey(
      apiKey: myApiKey,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "GoogleDriveHandlerExampleApp",
        ),
        centerTitle: true,
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                File? myFile = await GoogleDriveHandler()
                    .getFileFromGoogleDrive(context: context);
                if (myFile != null) {
                  /// Do something with the file
                  /// for instance open the file
                  print(myFile.path);
                } else {
                  /// Discard...
                }
              },
              child: const Text(
                "Get file from google drive",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
