import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/product/product_bloc.dart';
import '../../models/product_model.dart';
import '../../utils/constants.dart';


class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({Key? key}) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late Product product;
  int selectedImageIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Product) {
      product = args;
      // Record view in analytics
      context.read<ProductBloc>().add(ViewProduct(product: product));
    } else {
      // Handle error - no product passed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductInfo(),
                  const SizedBox(height: 24),
                  _buildPriceSection(),
                  const SizedBox(height: 24),
                  _buildDescriptionSection(),
                  const SizedBox(height: 24),
                  _buildDimensionsSection(),
                  const SizedBox(height: 24),
                  _buildRelatedProducts(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: product.images.isNotEmpty
            ? PageView.builder(
          itemCount: product.images.length,
          onPageChanged: (index) {
            setState(() {
              selectedImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return Image.network(
              product.images[index],
              fit: BoxFit.cover,
            );
          },
        )
            : Container(
          color: AppColors.textTertiary.withOpacity(0.2),
          child: const Icon(
            Icons.image,
            size: 100,
            color: AppColors.textTertiary,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {
            // Add to favorites
          },
          tooltip: 'Add to favorites',
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // Share product
          },
          tooltip: 'Share',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(30),
        child: product.images.length > 1
            ? Container(
          color: Colors.black45,
          height: 30,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                product.images.length,
                    (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == selectedImageIndex
                        ? AppColors.primary
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        )
            : Container(),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.brand,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.name,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(
              Icons.star,
              color: Colors.amber,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '4.5',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(124 reviews)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (product.priceHistory.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.trending_down,
                    size: 16,
                    color: AppColors.success,
                  ),
                  Text(
                    'Price dropped from \$${(product.price * 1.15).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
        if (product.modelUrl.isNotEmpty)
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
            ),
          ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(
          product.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildDimensionsSection() {
    if (product.dimensions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dimensions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildDimensionItem(
              'Width',
              '${product.dimensions['width']} cm',
            ),
            _buildDimensionItem(
              'Height',
              '${product.dimensions['height']} cm',
            ),
            _buildDimensionItem(
              'Depth',
              '${product.dimensions['depth']} cm',
            ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/measurement',
              arguments: product,
            );
          },
          icon: const Icon(Icons.straighten),
          label: const Text('Measure Your Space'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDimensionItem(String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelatedProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You Might Also Like',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state is RecommendedProductsLoaded) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final relatedProduct = state.products[index];
                    if (relatedProduct.id == product.id) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(
                            context,
                            '/product_details',
                            arguments: relatedProduct,
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: relatedProduct.images.isNotEmpty
                                  ? Image.network(
                                relatedProduct.images.first,
                                fit: BoxFit.cover,
                              )
                                  : Container(
                                color: AppColors.textTertiary.withOpacity(0.2),
                                child: const Icon(Icons.image),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              relatedProduct.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '\$${relatedProduct.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              return Container();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: () {
                // Add to shopping list
                _showAddToListDialog();
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add to List'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                // Add to cart and navigate to checkout
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Buy Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToListDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add to Shopping List',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // TODO: Implement a list of shopping lists here
              ElevatedButton.icon(
                onPressed: () {
                  // Create a new shopping list
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('Create New List'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        );
      },
    );
  }
}