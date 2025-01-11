import 'package:file_upload_app/blocs/drive/drive_bloc.dart';
import 'package:file_upload_app/blocs/drive/drive_event.dart';
import 'package:file_upload_app/blocs/drive/drive_state.dart';
import 'package:file_upload_app/models/drive_model.dart';
import 'package:file_upload_app/widgets/drive_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DriveFilesList extends StatefulWidget {
  final DriveState state;

  const DriveFilesList({super.key, required this.state});

  @override
  State<DriveFilesList> createState() => _DriveFilesListState();
}

class _DriveFilesListState extends State<DriveFilesList> {
  void _openFolder(DriveFileModel file) {
    if (file.mimeType == 'application/vnd.google-apps.folder') {
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

  void _copyAccessToken() {
    if (widget.state.accessToken != null) {
      Clipboard.setData(
        ClipboardData(text: widget.state.accessToken!),
      ).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access token copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Current folder: ${widget.state.isInFolder}');
    print("Access Token: ${widget.state.accessToken}");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.state.accessToken != null)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2D2D2D),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Access Token',
                      style: TextStyle(
                        color: Color(0xFFa2d39b),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.copy_rounded,
                        color: Color(0xFFa2d39b),
                        size: 20,
                      ),
                      onPressed: _copyAccessToken,
                      tooltip: 'Copy access token',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.state.accessToken!,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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
          'Delete this ${file.mimeType == "application/vnd.google-apps.folder" ? "folder" : "file"} permanently?',
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
