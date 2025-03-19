// lib/screens/product/product_search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/product/product_bloc.dart';
import '../../models/product_model.dart';
import '../../utils/constants.dart';
import '../../widgets/product_card.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({Key? key}) : super(key: key);

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _currentQuery = '';
  Function(Product)? _onProductSelected;

  @override
  void initState() {
    super.initState();
    // Load featured products initially
    context.read<ProductBloc>().add(LoadFeaturedProducts());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['onProductSelected'] != null) {
      _onProductSelected = args['onProductSelected'] as Function(Product);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _currentQuery = query;
    });

    context.read<ProductBloc>().add(SearchProducts(query: query));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Products'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _isSearching = false;
                      _currentQuery = '';
                    });
                    context.read<ProductBloc>().add(LoadFeaturedProducts());
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (_) => _performSearch(),
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isSearching && _currentQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Search results for "$_currentQuery"',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _isSearching = false;
                        _currentQuery = '';
                      });
                      context.read<ProductBloc>().add(LoadFeaturedProducts());
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SearchResultsLoaded) {
                  return _buildSearchResults(state.products);
                }

                if (state is FeaturedProductsLoaded) {
                  return _buildFeaturedProducts(state.products);
                }

                if (state is ProductError) {
                  return Center(
                    child: Text('Error: ${state.message}'),
                  );
                }

                return const Center(
                  child: Text('Start searching for products'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<Product> products) {
    if (products.isEmpty) {
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
              'No products found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () {
            if (_onProductSelected != null) {
              _onProductSelected!(product);
              Navigator.pop(context);
            } else {
              Navigator.pushNamed(
                context,
                '/product_details',
                arguments: product,
              );
            }
          },
        );
      },
    );
  }

  Widget _buildFeaturedProducts(List<Product> products) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Featured Products',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () {
                  if (_onProductSelected != null) {
                    _onProductSelected!(product);
                    Navigator.pop(context);
                  } else {
                    Navigator.pushNamed(
                      context,
                      '/product_details',
                      arguments: product,
                    );
                  }
                },
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Categories',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _buildCategoryGrid(),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {'name': 'Furniture', 'icon': Icons.chair},
      {'name': 'Decor', 'icon': Icons.home},
      {'name': 'Lighting', 'icon': Icons.lightbulb_outline},
      {'name': 'Kitchen', 'icon': Icons.kitchen},
      {'name': 'Bath', 'icon': Icons.bathtub_outlined},
      {'name': 'Bedroom', 'icon': Icons.bed},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return InkWell(
          onTap: () {
            _searchController.text = category['name'] as String;
            _performSearch();
          },
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                ),
                child: Icon(
                  category['icon'] as IconData,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category['name'] as String,
                style: Theme.of(context).textTheme.labelLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}