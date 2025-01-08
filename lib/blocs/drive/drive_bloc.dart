import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:file_upload_app/blocs/drive/drive_event.dart';
import 'package:file_upload_app/blocs/drive/drive_state.dart';
import 'package:file_upload_app/models/drive_model.dart';
import 'package:file_upload_app/repository/drive_repository.dart';
import 'package:file_upload_app/services/storage_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DriveBloc extends Bloc<DriveEvent, DriveState> {
  final DriveRepository _repository;
  final StorageService _storage;

  DriveBloc(this._repository, this._storage) : super(DriveInitial()) {
    on<SignInRequested>(_handleSignIn);
    on<SignOutRequested>(_handleSignOut);
    on<LoadFilesRequested>(_handleLoadFiles);
    on<LoadFolderFilesRequested>(_handleLoadFolderFiles);
    on<UploadFileRequested>(_handleUploadFile);
    on<DowloadFileRequested>(_handleDownloadFile);
    on<CreateFolderRequested>(_handleCreateFolder);
    on<CheckAuthStatusRequested>(_handleCheckAuthStatus);
    on<SilentSignInRequested>(_handleSilentSignIn);
    on<DeleteItemRequested>(_handleDeleteItem);
  }

  Future<void> _handleSignIn(
      SignInRequested event, Emitter<DriveState> emit) async {
    emit(DriveLoading());

    try {
      final success = await _repository.signIn();
      if (success) {
        final files = await _repository.listFiles();
        emit(DriveSuccess("Signed In Successfully"));
        emit(DriveSignedIn(files: files));
      } else {
        emit(DriveSignOut());
      }
    } catch (e) {
      emit(DriveError(e.toString()));
    }
  }

  Future<void> _handleSignOut(
      SignOutRequested event, Emitter<DriveState> emit) async {
    emit(DriveLoading());
    try {
      await _repository.signOut();
      emit(DriveSuccess("Signed Out"));
      emit(DriveSignOut());
    } catch (e) {
      emit(DriveError(e.toString()));
    }
  }

  Future<void> _handleCheckAuthStatus(
    CheckAuthStatusRequested event,
    Emitter<DriveState> emit,
  ) async {
    emit(DriveLoading());
    try {
      final isSignedIn = await _repository.checkSignInStatus();
      print("isSignedIn: $isSignedIn");
      if (isSignedIn) {
        // Run listFiles and getUserData concurrently
        final results = await Future.wait([
          _repository.listFiles(),
          _storage.getUserData(),
        ]);

        final files = results[0] as List<DriveFileModel>;

        emit(DriveSignedIn(files: files));
      } else {
        emit(DriveSignOut());
      }
    } catch (e) {
      emit(DriveError(e.toString()));
    } finally {
      FlutterNativeSplash.remove();
    }
  }

  Future<void> _handleSilentSignIn(
    SilentSignInRequested event,
    Emitter<DriveState> emit,
  ) async {
    emit(DriveLoading());
    try {
      final success = await _repository.silentSignIn();

      if (success) {
        // Run listFiles and getUserData concurrently
        final results = await Future.wait([
          _repository.listFiles(),
          _storage.getUserData(),
        ]);

        final files = results[0] as List<DriveFileModel>;

        emit(DriveSignedIn(files: files));
      } else {
        emit(DriveSignOut());
      }
    } catch (e) {
      emit(DriveError(e.toString()));
    }
  }

  Future<void> _handleLoadFiles(
      LoadFilesRequested event, Emitter<DriveState> emit) async {
    emit(DriveLoading());
    try {
      final files = await _repository.listFiles();
      emit(DriveSignedIn(
        files: files,
        isInFolder: false,
        currentFolderId: null,
      ));
    } catch (e) {
      emit(DriveError(e.toString()));
    }
  }

  Future<void> _handleLoadFolderFiles(
      LoadFolderFilesRequested event, Emitter<DriveState> emit) async {
    emit(DriveLoading());

    try {
      final result = await _repository.listFilesInFolder(
        folderId: event.folderId,
      );
      emit(DriveSignedIn(
        files: result,
        isInFolder: true,
        currentFolderId: event.folderId,
      ));
    } catch (e) {
      emit(DriveError(e.toString()));
    }
  }

  Future<void> _handleUploadFile(
      UploadFileRequested event, Emitter<DriveState> emit) async {
    final currentState = state;
    if (currentState is DriveSignedIn) {
      emit(DriveLoading());
      final bool isFolder =
          currentState.isInFolder && currentState.currentFolderId != null;
      try {
        await _repository.uploadFile(
          event.file,
          parentFolderId: isFolder ? currentState.currentFolderId : null,
        );

        final files = isFolder
            ? await _repository.listFilesInFolder(
                folderId: currentState.currentFolderId!,
              )
            : await _repository.listFiles();

        emit(DriveSuccess("File uploaded successfully"));
        emit(DriveSignedIn(
          files: files,
          isInFolder: currentState.isInFolder,
          currentFolderId: currentState.currentFolderId,
        ));
      } catch (e) {
        emit(DriveError(e.toString()));
        emit(DriveSignedIn(
          files: currentState.files,
          isInFolder: currentState.isInFolder,
          currentFolderId: currentState.currentFolderId,
        ));
      }
    }
  }

  Future<void> _handleDownloadFile(
    DowloadFileRequested event,
    Emitter<DriveState> emit,
  ) async {
    final currentState = state;
    if (currentState is DriveSignedIn) {
      emit(DriveLoading());
      try {
        await _repository.downloadFile(event.fileId, event.fileName);
        emit(DriveSuccess("File downloaded successfully"));
        emit(DriveSignedIn(files: currentState.files));
      } catch (e) {
        emit(DriveError(e.toString()));
      }
    }
  }

  Future<void> _handleCreateFolder(
      CreateFolderRequested event, Emitter<DriveState> emit) async {
    final currentState = state;
    emit(DriveLoading());
    try {
      final bool isFolder =
          currentState.isInFolder && currentState.currentFolderId != null;

      await _repository.createFolder(
        event.folderName,
        parentFolderId: isFolder ? currentState.currentFolderId : null,
      );

      final files = currentState is DriveSignedIn && isFolder
          ? await _repository.listFilesInFolder(
              folderId: currentState.currentFolderId!,
            )
          : await _repository.listFiles();

      emit(DriveSuccess("Folder created successfully"));
      emit(DriveSignedIn(
        files: files,
        isInFolder:
            currentState is DriveSignedIn ? currentState.isInFolder : false,
        currentFolderId:
            currentState is DriveSignedIn ? currentState.currentFolderId : null,
      ));
    } catch (e) {
      emit(DriveError(e.toString()));
    }
  }

  Future<void> _handleDeleteItem(
    DeleteItemRequested event,
    Emitter<DriveState> emit,
  ) async {
    final currentState = state;
    if (currentState is DriveSignedIn) {
      final bool isFolder =
          currentState.isInFolder && currentState.currentFolderId != null;

      emit(DriveLoading());
      try {
        await _repository.deleteItem(event.fileId, event.file);
        final files = isFolder
            ? await _repository.listFilesInFolder(
                folderId: currentState.currentFolderId!,
              )
            : await _repository.listFiles();

        final bool fileType = _repository.isFolder(event.file);
        emit(DriveSuccess(
            "${fileType ? "Folder" : "File"} deleted successfully"));
        emit(DriveSignedIn(
            files: files,
            currentFolderId: state.currentFolderId,
            isInFolder: state.isInFolder));
      } catch (e) {
        emit(DriveError(e.toString()));
        emit(DriveSignedIn(
          files: currentState.files,
          isInFolder: currentState.isInFolder,
          currentFolderId: currentState.currentFolderId,
        ));
      }
    }
  }
}
