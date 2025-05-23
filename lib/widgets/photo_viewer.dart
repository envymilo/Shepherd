import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shepherd_mo/utils/toast.dart';

class PhotoViewer extends StatefulWidget {
  final String imageUrl;

  const PhotoViewer({super.key, required this.imageUrl});

  @override
  PhotoViewerState createState() => PhotoViewerState();
}

class PhotoViewerState extends State<PhotoViewer>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  final double _minScale = 0.5;
  final double _maxScale = 4.0;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Handle double tap to zoom
  void _handleDoubleTap() {
    Matrix4 currentMatrix = _transformationController.value;
    double currentScale = currentMatrix.getMaxScaleOnAxis();

    if (currentScale < 2.0) {
      // Zoom in to 2x
      _animateScale(2.0);
    } else {
      // Reset to original size
      _animateScale(1.0);
    }
  }

  // Animation for scaling
  void _animateScale(double targetScale) {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity()..scale(targetScale),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward(from: 0);
  }

  // Handle manual zoom in
  void _zoomIn() {
    double currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale < _maxScale) {
      _animateScale(currentScale + 0.5);
    }
  }

  // Handle manual zoom out
  void _zoomOut() {
    double currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > _minScale) {
      _animateScale(currentScale - 0.5);
    }
  }

  // Handle image download
  Future<void> onDownload(
      BuildContext context, AppLocalizations localizations) async {
    if (isDownloading) return;

    try {
      // Prompt user to choose location
      final location = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(localizations.downloadImage),
            content: Text(localizations.whereToSaveImage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'file'),
                child: Text(localizations.file),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'gallery'),
                child: Text(localizations.gallery),
              ),
            ],
          );
        },
      );

      if (location == null) return;

      setState(() {
        isDownloading = true;
      });

      // Download image
      final response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode != 200) {
        throw Exception(localizations.failedToDownloadImg);
      }

      final imageBytes = response.bodyBytes;

      // Save the file temporarily
      final tempDir = await getTemporaryDirectory();
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(imageBytes);

      if (location == 'file') {
        // Save to private app directory
        final appDir = await getApplicationDocumentsDirectory();
        final savedFile = File('${appDir.path}/$fileName');
        await tempFile.copy(savedFile.path);
        showToast(localizations.imageSavedFile);
      } else if (location == 'gallery') {
        // Save to gallery (Android and iOS)

        final result = await ImageGallerySaver.saveImage(
          imageBytes,
          quality: 100,
          name: fileName,
        );

        if (result['isSuccess'] == true) {
          showToast(localizations.imageSavedGallery);
        } else {
          throw Exception(localizations.failedToSaveToGallery);
        }
      }
    } catch (e) {
      showToast(localizations.failedToDownloadImg);
    } finally {
      setState(() {
        isDownloading = false;
      });
    }
  }

  // Reset zoom to original size
  void onResetZoom() {
    _animateScale(1.0);
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context)!;
    return Stack(
      children: [
        // Main image viewer
        GestureDetector(
          onDoubleTap: _handleDoubleTap,
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: _minScale,
            maxScale: _maxScale,
            child: Hero(
              tag: 'profileImage',
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.fitWidth,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                          SizedBox(height: screenHeight * 0.008),
                          Text(
                            localizations.loadingImage,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenHeight * 0.014,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: screenHeight * 0.048,
                        ),
                        SizedBox(height: screenHeight * 0.008),
                        Text(
                          '${localizations.failedToLoadImg}\n$error',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red[300],
                            fontSize: screenHeight * 0.016,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Positioned(
          top: screenHeight * 0.016,
          right: screenHeight * 0.016,
          child: Row(
            children: [
              IconButton(
                icon: isDownloading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.download, color: Colors.white),
                onPressed: isDownloading
                    ? null
                    : () {
                        onDownload(context, localizations);
                      },
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: onResetZoom,
              ),
            ],
          ),
        ),
        // Bottom gradient overlay with controls
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.zoom_out, color: Colors.white),
                  onPressed: _zoomOut,
                ),
                IconButton(
                  icon: const Icon(Icons.center_focus_strong,
                      color: Colors.white),
                  onPressed: onResetZoom,
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_in, color: Colors.white),
                  onPressed: _zoomIn,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
