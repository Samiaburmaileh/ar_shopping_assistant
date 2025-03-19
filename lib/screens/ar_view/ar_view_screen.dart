import 'dart:math' as math;

import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../../models/product_model.dart';
import '../../widgets/ar_controls.dart';
import '../../utils/constants.dart';


class ArViewScreen extends StatefulWidget {
  const ArViewScreen({Key? key}) : super(key: key);

  @override
  State<ArViewScreen> createState() => _ArViewScreenState();
}

class _ArViewScreenState extends State<ArViewScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  ARNode? currentNode;
  Product? selectedProduct;
  bool isPlacementMode = true;
  bool isLoading = true;
  String? errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the product passed from the previous screen
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Product) {
      selectedProduct = args;
    }
  }

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedProduct != null
            ? 'AR View: ${selectedProduct!.name}'
            : 'AR View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _takeScreenshot,
            tooltip: 'Take Screenshot',
          ),
        ],
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (errorMessage != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'AR Error',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          if (isPlacementMode && errorMessage == null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black54,
                child: const Text(
                  'Tap on a surface to place the object',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (!isPlacementMode && errorMessage == null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ArControls(
                onRotate: _onRotate,
                onScale: _onScale,
                onReset: _onReset,
                onRemove: _onRemove,
              ),
            ),
        ],
      ),
    );
  }


  void _onARViewCreated(
      ARSessionManager sessionManager,
      ARObjectManager objectManager,
      ARAnchorManager anchorManager,
      ARLocationManager locationManager,
      ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;

    arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: "assets/images/triangle.png",
      showWorldOrigin: false,
    );

    arSessionManager!.onPlaneOrPointTap = _onPlaneOrPointTapped;
    arObjectManager!.onNodeTap = _onNodeTapped as NodeTapResultHandler?;

    arSessionManager!.onError("An error occurred");

    // Load the selected product model
    _loadModel();
  }


  Future<void> _loadModel() async {
    if (selectedProduct == null || selectedProduct!.modelUrl.isEmpty) {
      setState(() {
        errorMessage = 'No 3D model available for this product';
        isLoading = false;
      });
      return;
    }

    try {
      // In a real app, you would download and cache the model first
      // For demo purposes, we assume the URL is directly usable
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading 3D model: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    if (isPlacementMode && selectedProduct != null && selectedProduct!.modelUrl.isNotEmpty) {
      // Get the first hit result
      if (hitTestResults.isEmpty) return;

      final hit = hitTestResults.firstWhere(
            (hitTest) => hitTest.type == ARHitTestResultType.plane,
        orElse: () => hitTestResults.first,
      );

      // Check if a valid hit was found
      try {
        final modelUrl = selectedProduct!.modelUrl;

        // Create a node for the 3D model
        final node = ARNode(
          type: NodeType.webGLB,
          uri: modelUrl,
          scale: vector.Vector3(1.0, 1.0, 1.0),
          position: hit.worldTransform.getTranslation(),
          rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0),
        );

        // Use the basic addNode method without additional parameters
        bool? success = await arObjectManager?.addNode(node);

        if (success ?? false) {
          // Store the reference to the current node
          currentNode = node;

          // Switch to manipulation mode
          setState(() {
            isPlacementMode = false;
          });
        } else {
          // Handle failure
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to place object. Please try again.'),
            ),
          );
        }
      } catch (e) {
        print('Error placing object: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing object: ${e.toString()}'),
          ),
        );
      }
    }
  }

  void _onNodeTapped(List<ARNode> nodes) {
    // Implement if you want to do something when the user taps on the placed object
  }

  void _onRotate(double angle) {
    if (currentNode != null) {
      try {
        // Remove the node
        arObjectManager?.removeNode(currentNode!);

        // Create a rotation matrix for Y-axis rotation
        final rotationY = vector.Matrix4.rotationY(angle);

        // Create a new node with the rotation applied
        final newNode = ARNode(
          type: currentNode!.type,
          uri: currentNode!.uri,
          scale: currentNode!.scale,
          position: currentNode!.position,
          // For rotation, create a new Vector4 since we can't use Matrix3 directly
          rotation: vector.Vector4(0, 1, 0, angle), // Simple representation of rotation around Y axis
        );

        // Add the new node
        arObjectManager?.addNode(newNode);

        // Update our reference
        currentNode = newNode;
      } catch (e) {
        print('Error rotating object: $e');
      }
    }
  }

  void _onScale(double scale) {
    if (currentNode != null) {
      try {
        // Get current scale directly
        vector.Vector3 currentScale = currentNode!.scale;

        // Calculate new scale (min 0.1x, max 5x)
        double newScale = math.max(0.1, math.min(5.0, currentScale.x * scale));

        // Remove the node
        arObjectManager?.removeNode(currentNode!);

        // Create a new node with updated scale
        final newNode = ARNode(
          type: currentNode!.type,
          uri: currentNode!.uri,
          scale: vector.Vector3(newScale, newScale, newScale),
          position: currentNode!.position,
          // Keep the same rotation but make sure it's a Vector4
          rotation: vector.Vector4(0, 1, 0, 0), // Default rotation
        );

        // Add the node again
        arObjectManager?.addNode(newNode);

        // Update our reference
        currentNode = newNode;
      } catch (e) {
        print('Error scaling object: $e');
      }
    }
  }

  void _onReset() {
    if (currentNode != null) {
      try {
        // Store the position and other properties we want to keep
        final position = currentNode!.position;
        final type = currentNode!.type;
        final uri = currentNode!.uri;

        // Remove the current node
        arObjectManager?.removeNode(currentNode!);

        // Create a new node with reset rotation and scale, but same position
        final newNode = ARNode(
          type: type,
          uri: uri,
          scale: vector.Vector3(1.0, 1.0, 1.0),  // Reset scale
          position: position,  // Keep the same position
          rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0),  // Reset rotation
        );

        // Add the new node
        arObjectManager?.addNode(newNode);

        // Update our reference
        currentNode = newNode;
      } catch (e) {
        print('Error resetting object: $e');
      }
    }
  }

  void _onRemove() {
    if (currentNode != null) {
      arObjectManager?.removeNode(currentNode!);
      currentNode = null;

      // Switch back to placement mode
      setState(() {
        isPlacementMode = true;
      });
    }
  }

  Future<void> _takeScreenshot() async {
    if (arSessionManager != null) {
      try {
        // Use snapshot method instead of takeScreenshot
        final image = await arSessionManager!.snapshot();

        // The snapshot method returns the image data
        // We need to save this to the gallery or show it to the user
        if (image != null) {
          // You'll need to add a package like image_gallery_saver to save to gallery
          // For now, we'll just show a success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Screenshot captured'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take screenshot: ${e.toString()}'),
          ),
        );
      }
    }
  }
}