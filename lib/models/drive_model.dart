import 'package:googleapis/drive/v3.dart' as ga;

class DriveFileModel {
  final String id;
  final String name;
  final String? mimeType;
  final String? thumbnailLink;
  final DateTime? modifiedTime;

  DriveFileModel({
    required this.id,
    required this.name,
    this.mimeType,
    this.thumbnailLink,
    this.modifiedTime,
  });

  factory DriveFileModel.fromGoogleFile(ga.File file) {
    return DriveFileModel(
      id: file.id ?? '',
      name: file.name ?? 'Unnamed',
      mimeType: file.mimeType,
      thumbnailLink: file.thumbnailLink,
      modifiedTime: file.modifiedTime,
    );
  }
}
