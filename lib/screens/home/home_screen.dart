import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:file_upload_app/blocs/drive/drive_bloc.dart';
import 'package:file_upload_app/blocs/drive/drive_event.dart';
import 'package:file_upload_app/blocs/drive/drive_state.dart';
import 'package:file_upload_app/widgets/drive_files_list.dart';
import 'package:file_upload_app/widgets/image_crop_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriveBloc, DriveState>(
      listener: (context, state) {
        if (state is DriveError) {
          print(state.message);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        if (state is DriveSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            scrolledUnderElevation: 0,
            backgroundColor: Color(0xFF0F140E),
            leadingWidth: 72,
            title: Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text('Drive Files', style: TextStyle(fontSize: 25)),
            ),
            actions: [
              if (state is DriveSignedIn)
                Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: IconButton(
                    icon: Icon(Icons.logout, color: Color(0xFFa2d39b)),
                    onPressed: () {
                      context.read<DriveBloc>().add(SignOutRequested());
                    },
                  ),
                ),
            ],
          ),
          body: state is DriveLoading
              ? Center(
                  child: CircularProgressIndicator(color: Color(0xFF90EE90)))
              : SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        Expanded(
                          child: state is! DriveSignedIn
                              ? _buildSignInView(context)
                              : DriveFilesList(
                                  state: state,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
          floatingActionButton: state is DriveSignedIn
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      heroTag: 'createFolder',
                      backgroundColor: Color(0xFFa2d39b),
                      child: Icon(Icons.create_new_folder, color: Colors.black),
                      onPressed: () => _showCreateFolderDialog(context),
                    ),
                    SizedBox(height: 16),
                    FloatingActionButton(
                      heroTag: 'uploadFile',
                      backgroundColor: Color(0xFFa2d39b),
                      child: Icon(Icons.upload_file, color: Colors.black),
                      onPressed: () => _handleUploadFile(context),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _buildSignInView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Connect to Google Drive',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 40),
        ElevatedButton(
          onPressed: () {
            context.read<DriveBloc>().add(SignInRequested());
          },
          child: Text('Connect to Google Drive'),
        ),
      ],
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E1E),
        title: Text('Create Folder', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Folder name',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFa2d39b)),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Create', style: TextStyle(color: Color(0xFFa2d39b))),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<DriveBloc>().add(
                      CreateFolderRequested(controller.text),
                    );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleUploadFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: false);

    if (result != null) {
      final file = File(result.files.single.path!);
      final imageData = await file.readAsBytes();
      await _showImageCropDialog(context, imageData);
    }
    // if (result != null && context.mounted) {
    //   final file = File(result.files.single.path!);
    //   context.read<DriveBloc>().add(UploadFileRequested(file));
    // }
  }
}

Future<void> _showImageCropDialog(BuildContext context, Uint8List imageData) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return ImageCropScreen(
        imageData: imageData,
        onUpload: (croppedFile) {
          // Close dialog first
          Navigator.of(dialogContext).pop();
          // Then trigger the upload
          context.read<DriveBloc>().add(UploadFileRequested(croppedFile));
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      );
    },
  );
}
