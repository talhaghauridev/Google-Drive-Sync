import 'package:flutter/material.dart';

class DriveFileCard extends StatelessWidget {
  final String fileName;
  final String modifiedDate;
  final VoidCallback onDownload;

  const DriveFileCard({
    super.key,
    required this.fileName,
    required this.modifiedDate,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Color(0xFF1E1E1E),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    fileName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.download,
                    color: Color(0xFFa2d39b),
                  ),
                  onPressed: onDownload,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
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
    );
  }
}
