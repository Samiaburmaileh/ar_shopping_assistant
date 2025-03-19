import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../utils/constants.dart';

class CameraView extends StatefulWidget {
  final Function(File) onImageCaptured;
  final bool showControls;
  final bool enableFlash;

  const CameraView({
    Key? key,
    required this.onImageCaptured,
    this.showControls = true,
    this.enableFlash = true,
  }) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRearCamera = true;
  bool _isFlashOn = false;
  bool _isInitialized = false;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes to properly manage the camera
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        return;
      }

      // Start with the rear camera
      CameraDescription camera = _cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: ${e.toString()}');
    }
  }

  void _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() {
      _isInitialized = false;
      _isRearCamera = !_isRearCamera;
    });

    // Dispose of the current controller
    await _controller?.dispose();

    // Get the new camera
    CameraDescription camera = _cameras!.firstWhere(
          (camera) => _isRearCamera
          ? camera.lensDirection == CameraLensDirection.back
          : camera.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );

    // Create a new controller
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    // Initialize the new controller
    try {
      await _controller!.initialize();

      if (_isFlashOn && _isRearCamera) {
        await _controller!.setFlashMode(FlashMode.torch);
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error switching camera: ${e.toString()}');
    }
  }

  void _toggleFlash() async {
    if (!widget.enableFlash || !_isRearCamera) return;

    try {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });

      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      print('Error toggling flash: ${e.toString()}');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_isInitialized || _isTakingPicture) {
      return;
    }

    try {
      setState(() {
        _isTakingPicture = true;
      });

      final image = await _controller!.takePicture();

      if (mounted) {
        widget.onImageCaptured(File(image.path));
      }
    } catch (e) {
      print('Error taking picture: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Stack(
      children: [
        // Camera preview
        CameraPreview(_controller!),

        // Controls overlay
        if (widget.showControls)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              color: Colors.black45,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Flash toggle
                  if (widget.enableFlash && _isRearCamera)
                    IconButton(
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                      ),
                      onPressed: _toggleFlash,
                      tooltip: 'Toggle Flash',
                    ),

                  // Capture button
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          height: 56,
                          width: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: _isTakingPicture
                              ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          )
                              : const SizedBox(),
                        ),
                      ),
                    ),
                  ),

                  // Camera switch
                  if (_cameras != null && _cameras!.length > 1)
                    IconButton(
                      icon: const Icon(
                        Icons.switch_camera,
                        color: Colors.white,
                      ),
                      onPressed: _switchCamera,
                      tooltip: 'Switch Camera',
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}