import 'package:file_upload_app/blocs/drive/drive_bloc.dart';
import 'package:file_upload_app/blocs/drive/drive_event.dart';
import 'package:file_upload_app/blocs/drive/drive_state.dart';
import 'package:file_upload_app/models/drive_model.dart';
import 'package:file_upload_app/widgets/drive_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DriveFilesList extends StatelessWidget {
  final DriveState state;
  final BuildContext context;

  const DriveFilesList({super.key, required this.state, required this.context});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 16),
          child: Text(
            'Your Drive Files',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: state.files.isEmpty
              ? const Center(
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
                      onDelete: () => _deleteFileDialog(context, file),
                      mimeType: file.mimeType,
                      thumbnailLink: file.thumbnailLink,
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _deleteFileDialog(BuildContext context, DriveFileModel file) {
    print('File: ${file.mimeType} hello');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E1E),
        title: Text(
          'Are you absolutely sure?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Delete this ${file.mimeType == "application/vnd.google-apps.folder" ? "folder" : "file"} permanently',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<DriveBloc>().add(
                    DeleteItemRequested(file.id, file),
                  );
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
