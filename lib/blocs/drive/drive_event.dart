import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:file_upload_app/models/drive_model.dart';

abstract class DriveEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SignInRequested extends DriveEvent {}

class SignOutRequested extends DriveEvent {}

class CheckAuthStatusRequested extends DriveEvent {}

class SilentSignInRequested extends DriveEvent {}

class LoadFilesRequested extends DriveEvent {}

class UploadFileRequested extends DriveEvent {
  final File file;
  UploadFileRequested(this.file);

  @override
  List<Object?> get props => [file];
}

class CreateFolderRequested extends DriveEvent {
  final String folderName;
  CreateFolderRequested(this.folderName);

  @override
  List<Object?> get props => [folderName];
}

class DowloadFileRequested extends DriveEvent {
  final String fileId;
  final String fileName;
  DowloadFileRequested(this.fileId, this.fileName);

  @override
  List<Object?> get props => [fileId, fileName];
}

class DeleteItemRequested extends DriveEvent {
  final String fileId;
  final DriveFileModel file;
  DeleteItemRequested(this.fileId, this.file);

  @override
  List<Object?> get props => [fileId];
}
