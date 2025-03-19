// lib/screens/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/product/product_bloc.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../widgets/product_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Product> _favoriteProducts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final favorites = await _firestoreService.getFavoriteProducts();

      setState(() {
        _favoriteProducts = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load favorites: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorState()
            : _favoriteProducts.isEmpty
            ? _buildEmptyState()
            : _buildFavoritesList(),
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
              'Error Loading Favorites',
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
              onPressed: _loadFavorites,
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
              Icons.favorite_border,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Favorites Yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Products you mark as favorites will appear here',
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

  Widget _buildFavoritesList() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _favoriteProducts.length,
      itemBuilder: (context, index) {
        final product = _favoriteProducts[index];
        return Dismissible(
          key: Key(product.id),
          direction: DismissDirection.horizontal,
          background: Container(
            color: AppColors.error,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          secondaryBackground: Container(
            color: AppColors.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          onDismissed: (_) async {
            await _firestoreService.toggleFavoriteProduct(product.id);
            setState(() {
              _favoriteProducts.removeAt(index);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.name} removed from favorites'),
                action: SnackBarAction(
                  label: 'UNDO',
                  onPressed: () async {
                    await _firestoreService.toggleFavoriteProduct(product.id);
                    _loadFavorites();
                  },
                ),
              ),
            );
          },
          child: ProductCard(
            product: product,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/product_details',
                arguments: product,
              );
            },
          ),
        );
      },
    );
  }
}