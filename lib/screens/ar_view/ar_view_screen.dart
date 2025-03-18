import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
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
    arObjectManager!.onNodeTap = _onNodeTapped;

    arSessionManager!.onError = (error) {
      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    };

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
      final hit = hitTestResults.firstWhere(
            (hitTest) => hitTest.type == ARHitTestResultType.plane,
        orElse: () => hitTestResults.first,
      );

      // Check if a valid hit was found
      if (hit != null) {
        final modelUrl = selectedProduct!.modelUrl;

        // Create a node for the 3D model
        final node = ARNode(
          type: NodeType.webGLB,
          uri: modelUrl,
          scale: Vector3(1.0, 1.0, 1.0),
          position: Vector3(0.0, 0.0, 0.0),
          rotation: Vector4(1.0, 0.0, 0.0, 0.0),
        );

        // Add the node at the hit position
        bool? success = await arObjectManager?.addNode(node, planeAnchor: hit.anchor);

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
      }
    }
  }

  void _onNodeTapped(List<ARNode> nodes) {
    // Implement if you want to do something when the user taps on the placed object
  }

  void _onRotate(double angle) {
    if (currentNode != null) {
      final rotation = currentNode!.rotation.value;
      // Update Y-axis rotation (assuming Y is up)
      rotation.setValues(rotation.x, rotation.y + angle, rotation.z, rotation.w);
      arObjectManager?.updateRotation(currentNode!, rotation);
    }
  }

  void _onScale(double scale) {
    if (currentNode != null) {
      final currentScale = currentNode!.scale.value;
      final newScale = math.max(0.1, currentScale.x * scale);
      arObjectManager?.updateScale(currentNode!, Vector3(newScale, newScale, newScale));
    }
  }

  void _onReset() {
    if (currentNode != null) {
      // Reset rotation and scale to initial values
      arObjectManager?.updateRotation(currentNode!, Vector4(1.0, 0.0, 0.0, 0.0));
      arObjectManager?.updateScale(currentNode!, Vector3(1.0, 1.0, 1.0));
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
        await arSessionManager!.takeScreenshot();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Screenshot saved to gallery'),
          ),
        );
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