import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/product/product_bloc.dart';
import '../../utils/constants.dart';
import '../../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load featured products when screen initializes
    context.read<ProductBloc>().add(LoadFeaturedProducts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 0:
      // Already on home
        break;
      case 1:
        Navigator.pushNamed(context, '/ar_view');
        return;
      case 2:
        Navigator.pushNamed(context, '/shopping_lists');
        return;
      case 3:
        Navigator.pushNamed(context, '/profile');
        return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () {
              // Launch visual search
              Navigator.pushNamed(context, '/camera_search');
            },
            tooltip: 'Visual Search',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Open notifications
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_in_ar_outlined),
            activeIcon: Icon(Icons.view_in_ar),
            label: 'AR View',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Lists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ProductBloc>().add(LoadFeaturedProducts());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 24),
              _buildCategorySection(),
              const SizedBox(height: 24),
              _buildFeaturedProductsSection(),
              const SizedBox(height: 24),
              _buildRecentlyViewedSection(),
              const SizedBox(height: 24),
              _buildRecommendedSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: AppStrings.searchHint,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
      onSubmitted: (value) {
        if (value.isNotEmpty) {
          context.read<ProductBloc>().add(SearchProducts(query: value));
          Navigator.pushNamed(context, '/search_results', arguments: value);
        }
      },
    );
  }

  Widget _buildCategorySection() {
    final categories = [
      {'name': 'Furniture', 'icon': Icons.chair},
      {'name': 'Decor', 'icon': Icons.home},
      {'name': 'Lighting', 'icon': Icons.lightbulb_outline},
      {'name': 'Kitchen', 'icon': Icons.kitchen},
      {'name': 'Bath', 'icon': Icons.bathtub_outlined},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == categories.length - 1 ? 0 : 16,
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/category',
                      arguments: category['name'],
                    );
                  },
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
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
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Products',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/featured');
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (state is FeaturedProductsLoaded) {
              return SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == state.products.length - 1 ? 0 : 16,
                      ),
                      child: SizedBox(
                        width: 180,
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
                      ),
                    );
                  },
                ),
              );
            }
            return const Center(
              child: Text('No featured products available'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentlyViewedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recently Viewed',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/history');
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is RecentlyViewedProductsLoaded) {
              return SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == state.products.length - 1 ? 0 : 16,
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/product_details',
                            arguments: product,
                          );
                        },
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                            color: AppColors.surface,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: product.images.isNotEmpty
                                    ? Image.network(
                                  product.images.first,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                                    : Container(
                                  color: AppColors.textTertiary.withOpacity(0.2),
                                  child: const Icon(Icons.image),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  product.name,
                                  style: Theme.of(context).textTheme.labelLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended For You',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is RecommendedProductsLoaded) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: state.products.length,
                itemBuilder: (context, index) {
                  final product = state.products[index];
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
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}