import 'package:flutter/material.dart';

class DriveFileCard extends StatelessWidget {
  final String fileName;
  final String modifiedDate;
  final VoidCallback onDownload;

  const DriveFileCard({
    Key? key,
    required this.fileName,
    required this.modifiedDate,
    required this.onDownload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onDownload,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
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
