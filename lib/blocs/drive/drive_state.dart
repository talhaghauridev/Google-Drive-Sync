import 'package:equatable/equatable.dart';
import 'package:file_upload_app/models/drive_model.dart';

abstract class DriveState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DriveInitial extends DriveState {}

class DriveLoading extends DriveState {}

class DriveSuccess extends DriveState {
  final String message;
  DriveSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class DriveSignOut extends DriveState {}

class DriveSignedIn extends DriveState {
  final List<DriveFileModel> files;

  DriveSignedIn(this.files);

  @override
  List<Object?> get props => [files];
}

class DriveFileDownloading extends DriveState {}

class DriveError extends DriveState {
  final String message;
  DriveError(this.message);

  @override
  List<Object?> get props => [message];
}
