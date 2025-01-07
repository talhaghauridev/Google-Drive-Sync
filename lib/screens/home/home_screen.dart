import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:file_upload_app/blocs/drive/drive_bloc.dart';
import 'package:file_upload_app/blocs/drive/drive_event.dart';
import 'package:file_upload_app/blocs/drive/drive_state.dart';
import 'package:file_upload_app/widgets/drive_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriveBloc, DriveState>(
      listener: (context, state) {
        if (state is DriveError) {
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
                              : _buildFilesView(context, state),
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

  Widget _buildFilesView(BuildContext context, DriveSignedIn state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 16, bottom: 16),
          child: Text(
            'Your Drive Files',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: state.files.isEmpty
              ? Center(
                  child: Text(
                    'No files found',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: state.files.length,
                  itemBuilder: (context, index) {
                    final file = state.files[index];
                    return DriveFileCard(
                      fileName: file.name,
                      modifiedDate:
                          'Modified: ${file.modifiedTime?.toLocal() ?? 'Unknown'}',
                      onDownload: () {
                        context.read<DriveBloc>().add(
                              DowloadFileRequested(file.id, file.name),
                            );
                      },
                      mimeType: file.mimeType,
                      thumbnailLink: file.thumbnailLink,
                    );
                  },
                ),
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
    final result = await FilePicker.platform.pickFiles();
    if (result != null && context.mounted) {
      // Add context.mounted check
      final file = File(result.files.single.path!);
      context.read<DriveBloc>().add(UploadFileRequested(file));
    }
  }
}
