// lib/screens/ar_history_screen.dart
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/ar_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ArHistoryScreen extends StatefulWidget {
  const ArHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ArHistoryScreen> createState() => _ArHistoryScreenState();
}

class _ArHistoryScreenState extends State<ArHistoryScreen> {
  final ArService _arService = ArService();
  List<Map<String, dynamic>> _arHistory = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadArHistory();
  }

  Future<void> _loadArHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final history = await _arService.getArHistory();

      setState(() {
        _arHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load AR history: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR History'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadArHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorState()
            : _arHistory.isEmpty
            ? _buildEmptyState()
            : _buildHistoryList(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading AR History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadArHistory,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_in_ar,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No AR History Yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Products you view in AR will appear here',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/product_search');
              },
              icon: const Icon(Icons.search),
              label: const Text('Browse Products'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _arHistory.length,
      itemBuilder: (context, index) {
        final item = _arHistory[index];
        final product = item['product'] as Product;
        final lastViewed = item['lastViewed'] as DateTime;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/ar_view',
                arguments: product,
              );
            },
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: product.images.isNotEmpty
                        ? Image.network(
                      product.images.first,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 100,
                      height: 100,
                      color: AppColors.textTertiary.withOpacity(0.2),
                      child: const Icon(
                        Icons.image,
                        size: 40,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.brand,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Last viewed: ${Helpers.getRelativeTime(lastViewed)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/ar_view',
                                  arguments: product,
                                );
                              },
                              icon: const Icon(Icons.view_in_ar),
                              label: const Text('View in AR'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/product_details',
                                  arguments: product,
                                );
                              },
                              child: const Text('Details'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}