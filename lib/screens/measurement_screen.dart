import 'package:flutter/material.dart';
import '../models/product_model.dart';

class MeasurementScreen extends StatefulWidget {
  const MeasurementScreen({Key? key}) : super(key: key);

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  double? measurementDistance;
  String? errorMessage;
  bool isLoading = false;
  bool isMeasuring = false;
  Product? selectedProduct;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the product passed from the previous screen if any
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Product) {
      selectedProduct = args;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurement Tool'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetMeasurement,
            tooltip: 'Reset',
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _takeScreenshot,
            tooltip: 'Take Screenshot',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Placeholder for the AR view
          Container(
            color: Colors.grey[300],
            width: double.infinity,
            height: double.infinity,
            child: const Center(
              child: Text('AR View Would Appear Here'),
            ),
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
                      color: Colors.red,
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

          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  measurementDistance != null
                      ? 'Distance: ${measurementDistance!.toStringAsFixed(2)} cm'
                      : 'Tap to place measurement points',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),

          // Mock buttons to simulate measurement functionality
          if (measurementDistance == null)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Simulate measuring a distance
                    setState(() {
                      measurementDistance = 120.5; // Mock distance
                    });
                  },
                  child: const Text('Simulate Measurement'),
                ),
              ),
            ),

          if (selectedProduct != null && measurementDistance != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Product Dimensions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _buildProductDimensions(),
                      const SizedBox(height: 16),
                      _buildComparisonResult(),
                    ],
                  ),
                ),
              ),
            ),

          if (measurementDistance == null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: _completeMeasurement,
                icon: const Icon(Icons.check),
                label: const Text('Complete Measurement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _resetMeasurement() {
    setState(() {
      measurementDistance = null;
      isMeasuring = false;
    });
  }

  void _completeMeasurement() {
    // Simulate completing a measurement
    setState(() {
      measurementDistance = 120.5; // Mock measurement
    });
  }

  void _takeScreenshot() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Screenshot taken (simulated)'),
      ),
    );
  }

  Widget _buildProductDimensions() {
    if (selectedProduct == null || selectedProduct!.dimensions.isEmpty) {
      return const Text('No product dimensions available');
    }

    return Row(
      children: [
        _buildDimensionItem(
          'Width',
          '${selectedProduct!.dimensions['width']} cm',
        ),
        _buildDimensionItem(
          'Height',
          '${selectedProduct!.dimensions['height']} cm',
        ),
        _buildDimensionItem(
          'Depth',
          '${selectedProduct!.dimensions['depth']} cm',
        ),
      ],
    );
  }

  Widget _buildDimensionItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonResult() {
    if (selectedProduct == null ||
        selectedProduct!.dimensions.isEmpty ||
        measurementDistance == null) {
      return const SizedBox.shrink();
    }

    // For simplicity, compare with the width
    final productWidth = selectedProduct!.dimensions['width'] as double;
    final difference = (measurementDistance! - productWidth).abs();
    final isLargeEnough = measurementDistance! >= productWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isLargeEnough ? Icons.check_circle : Icons.warning,
              color: isLargeEnough ? Colors.green : Colors.amber,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isLargeEnough
                    ? 'Your space is large enough for this product!'
                    : 'Your space is too small for this product',
                style: TextStyle(
                  color: isLargeEnough ? Colors.green : Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isLargeEnough
              ? 'The measured space is ${difference.toStringAsFixed(2)} cm larger than needed.'
              : 'You need ${difference.toStringAsFixed(2)} cm more space.',
        ),
      ],
    );
  }
}