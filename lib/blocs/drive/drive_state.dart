import 'package:equatable/equatable.dart';
import 'package:file_upload_app/models/drive_model.dart';

abstract class DriveState extends Equatable {
  final List<DriveFileModel> files;
  final bool isInFolder;
  final String? currentFolderId;

  const DriveState({
    this.files = const [],
    this.isInFolder = false,
    this.currentFolderId,
  });

  @override
  List<Object?> get props => [files, isInFolder, currentFolderId];
}

class DriveInitial extends DriveState {}

class DriveLoading extends DriveState {}

class DriveSuccess extends DriveState {
  final String message;

  const DriveSuccess(
    this.message, {
    super.files,
    super.isInFolder,
    super.currentFolderId,
  });

  @override
  List<Object?> get props => [...super.props, message];
}

class DriveSignOut extends DriveState {}

class DriveSignedIn extends DriveState {
  const DriveSignedIn({
    required super.files,
    super.isInFolder,
    super.currentFolderId,
  });
}

class DriveFileDownloading extends DriveState {}

class DriveError extends DriveState {
  final String message;

  const DriveError(
    this.message, {
    super.files,
    super.isInFolder,
    super.currentFolderId,
  });

  @override
  List<Object?> get props => [...super.props, message];
}
