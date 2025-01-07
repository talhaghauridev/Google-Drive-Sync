import 'package:file_upload_app/blocs/drive/drive_bloc.dart';
import 'package:file_upload_app/blocs/drive/drive_event.dart';
import 'package:file_upload_app/repository/drive_repository.dart';
import 'package:file_upload_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:file_upload_app/screens/home/home_screen.dart';
import 'package:file_upload_app/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final DriveRepository driveRepository = DriveRepository();
  final storageService = StorageService();
  MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DriveBloc>(
            create: (context) => DriveBloc(driveRepository, storageService)
              ..add(CheckAuthStatusRequested()))
      ],
      child: MaterialApp(
        title: 'Google Drive Sync',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: HomeScreen(),
      ),
    );
  }
}
