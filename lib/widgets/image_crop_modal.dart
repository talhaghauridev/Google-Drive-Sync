import 'dart:io';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class ImageCropScreen extends StatefulWidget {
  final Uint8List imageData;
  final void Function(File croppedFile) onUpload;
  final VoidCallback onCancel;

  const ImageCropScreen({
    super.key,
    required this.imageData,
    required this.onUpload,
    required this.onCancel,
  });

  @override
  _ImageCropScreenState createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  final CropController _cropController = CropController();
  bool _isProcessing = false;

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(
                color: Color(0xFFa2d39b),
              ),
              SizedBox(height: 16),
              Text(
                'Processing image...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _performCrop() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      _showLoadingDialog();
      _cropController.crop();
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Crop error: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to crop image: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_isProcessing) {
          widget.onCancel();
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F140E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F140E),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: !_isProcessing ? widget.onCancel : null,
          ),
          title: const Text(
            'Crop Image',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: !_isProcessing ? _performCrop : null,
              child: Text(
                'Crop',
                style: TextStyle(
                  color: !_isProcessing ? const Color(0xFFa2d39b) : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Crop(
                controller: _cropController,
                image: widget.imageData,
                onCropped: (croppedData) async {
                  try {
                    final img.Image? originalImage =
                        img.decodeImage(croppedData);
                    if (originalImage != null) {
                      final processedData =
                          img.encodeJpg(originalImage, quality: 100);

                      final tempDir = await getTemporaryDirectory();
                      final file = File(
                        '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg',
                      );
                      await file.writeAsBytes(processedData);

                      if (mounted) {
                        Navigator.pop(context);
                        widget.onUpload(file);
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Failed to process image: ${e.toString()}')),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isProcessing = false;
                      });
                    }
                  }
                },
                maskColor: Colors.black.withOpacity(0.7),
                baseColor: Colors.black,
                onStatusChanged: (status) {
                  if (status == CropStatus.loading) {
                    setState(() => _isProcessing = true);
                  }
                },
                progressIndicator: const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
