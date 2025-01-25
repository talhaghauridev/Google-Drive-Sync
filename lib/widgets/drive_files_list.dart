import 'package:file_upload_app/blocs/drive/drive_bloc.dart';
import 'package:file_upload_app/blocs/drive/drive_event.dart';
import 'package:file_upload_app/blocs/drive/drive_state.dart';
import 'package:file_upload_app/constants/constants.dart';
import 'package:file_upload_app/models/drive_model.dart';
import 'package:file_upload_app/widgets/drive_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DriveFilesList extends StatefulWidget {
  final DriveState state;

  const DriveFilesList({super.key, required this.state});

  @override
  State<DriveFilesList> createState() => _DriveFilesListState();
}

class _DriveFilesListState extends State<DriveFilesList> {
  void _openFolder(DriveFileModel file) {
    if (file.mimeType == AppConstants.folderType) {
      print('Attempting to open folder: ${file.name}');
      context.read<DriveBloc>().add(
            LoadFolderFilesRequested(
              file.id,
              isInFolder: true,
            ),
          );
    }
  }

  void _navigateBack() {
    print('Navigating back from folder');
    context.read<DriveBloc>().add(LoadFilesRequested());
  }

  @override
  Widget build(BuildContext context) {
    print('Current folder: ${widget.state.isInFolder}');
    print("Access Token: ${widget.state.accessToken}");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              if (widget.state.isInFolder)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _navigateBack,
                  tooltip: 'Back to previous folder',
                ),
              const SizedBox(width: 2),
              Text(
                'Your Drive Files',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.state.files.isEmpty
              ? const Center(
                  child: Text(
                    'No files found',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: widget.state.files.length,
                  itemBuilder: (context, index) {
                    final file = widget.state.files[index];
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
                      onTap: () => _openFolder(file),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _deleteFileDialog(BuildContext context, DriveFileModel file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Are you absolutely sure?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Delete this ${file.mimeType == AppConstants.folderType ? "folder" : "file"} permanently?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
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
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
