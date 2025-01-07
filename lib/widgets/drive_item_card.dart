import 'package:flutter/material.dart';

String truncateWithEllipsis(String str, int maxLength) {
  if (str.length <= maxLength) return str;
  return '${str.substring(0, maxLength)}.';
}

class DriveFileCard extends StatelessWidget {
  final String fileName;
  final String modifiedDate;
  final VoidCallback onDownload;
  final String? mimeType;
  final String? thumbnailLink;

  const DriveFileCard({
    Key? key,
    required this.fileName,
    required this.modifiedDate,
    required this.onDownload,
    this.mimeType,
    this.thumbnailLink,
  }) : super(key: key);

  Widget _getFileIcon() {
    if (thumbnailLink != null && mimeType?.startsWith('image/') == true) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          thumbnailLink!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.insert_drive_file, color: Color(0xFFa2d39b)),
        ),
      );
    }

    IconData iconData = Icons.insert_drive_file;
    if (mimeType?.startsWith('image/') == true) {
      iconData = Icons.image;
    } else if (mimeType?.startsWith('video/') == true) {
      iconData = Icons.video_file;
    } else if (mimeType?.startsWith('audio/') == true) {
      iconData = Icons.audio_file;
    }

    return Icon(iconData, color: Color(0xFFa2d39b), size: 36);
  }

  @override
  Widget build(BuildContext context) {
    final fileNameParts = fileName.split('.');
    final extension = fileNameParts.length > 1 ? fileNameParts.last : '';
    final nameWithoutExt = fileNameParts.length > 1
        ? fileNameParts.sublist(0, fileNameParts.length - 1).join('.')
        : fileName;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              _getFileIcon(),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${truncateWithEllipsis(nameWithoutExt, 18)}$extension",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      modifiedDate,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.download, color: Color(0xFFa2d39b)),
                onPressed: onDownload,
                visualDensity: VisualDensity.compact,
                splashRadius: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
