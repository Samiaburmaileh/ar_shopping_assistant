// lib/screens/visual_search_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/product/product_bloc.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/camera_view.dart';
import '../widgets/product_card.dart';

class VisualSearchScreen extends StatefulWidget {
  const VisualSearchScreen({Key? key}) : super(key: key);

  @override
  State<VisualSearchScreen> createState() => _VisualSearchScreenState();
}

class _VisualSearchScreenState extends State<VisualSearchScreen> {
  File? _capturedImage;
  bool _isSearching = false;
  List<Product> _searchResults = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Search'),
        actions: [
          if (_capturedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetSearch,
              tooltip: 'Take New Photo',
            ),
        ],
      ),
      body: _capturedImage == null
          ? _buildCameraView()
          : _isSearching
          ? _buildSearchingState()
          : _buildSearchResults(),
    );
  }

  Widget _buildCameraView() {
    return Column(
      children: [
        Expanded(
          child: CameraView(
            onImageCaptured: _onImageCaptured,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black87,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                'Take a photo to search for similar products',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchingState() {
    return Column(
      children: [
        _buildCapturedImagePreview(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Searching for similar products...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        _buildCapturedImagePreview(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _searchResults.isEmpty
                ? 'No matching products found'
                : 'Found ${_searchResults.length} similar products',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty
              ? _buildNoResultsFound()
              : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final product = _searchResults[index];
              return ProductCard(
                product: product,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/product_details',
                    arguments: product,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCapturedImagePreview() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: Stack(
        children: [
          Image.file(
            _capturedImage!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 16,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
                onPressed: _resetSearch,
                tooltip: 'Take New Photo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No matching products found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try taking another photo or searching with different keywords',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _resetSearch,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Another Photo'),
          ),
        ],
      ),
    );
  }

  void _onImageCaptured(File image) {
    setState(() {
      _capturedImage = image;
      _isSearching = true;
    });

    // Simulate search process
    Future.delayed(const Duration(seconds: 2), () {
      _mockSearchResults();
    });
  }

  void _resetSearch() {
    setState(() {
      _capturedImage = null;
      _isSearching = false;
      _searchResults = [];
    });
  }

  void _mockSearchResults() {
    // In a real app, this would call an API to identify products in the image
    // For demo purposes, we'll just use some mock data
    final mockProducts = List.generate(
      6,
          (index) => Product(
        id: 'visual-search-result-$index',
        name: 'Modern ${index % 2 == 0 ? "Chair" : "Table"}',
        description: 'Stylish home furniture for your living space.',
        price: 149.99 + (index * 10),
        brand: 'HomeStyles',
        categories: ['Furniture', 'Living Room'],
        images: [
          'https://images.unsplash.com/photo-1592078615290-033ee584e267',
        ],
        modelUrl: index % 3 == 0
            ? 'https://example.com/models/furniture_${index + 1}.glb'
            : '',
        dimensions: {
          'width': 60.0 + index,
          'height': 80.0 + index,
          'depth': 50.0 + index,
        },
      ),
    );

    setState(() {
      _searchResults = mockProducts;
      _isSearching = false;
    });
  }
}