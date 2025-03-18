import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import '../blocs/product/product_bloc.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';

class PriceComparisonScreen extends StatefulWidget {
  const PriceComparisonScreen({Key? key}) : super(key: key);

  @override
  State<PriceComparisonScreen> createState() => _PriceComparisonScreenState();
}

class _PriceComparisonScreenState extends State<PriceComparisonScreen> {
  Product? scannedProduct;
  bool isLoading = false;
  List<Map<String, dynamic>> retailers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Comparison'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : scannedProduct == null
          ? _buildInitialScreen()
          : _buildProductComparisonScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanBarcode,
        child: const Icon(Icons.qr_code_scanner),
        tooltip: 'Scan Barcode',
      ),
    );
  }

  Widget _buildInitialScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 80,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 24),
          Text(
            'Scan a Product Barcode',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Scan any product barcode to see price comparisons across retailers',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _scanBarcode,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Now'),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _enterCodeManually,
            icon: const Icon(Icons.edit),
            label: const Text('Enter Code Manually'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductComparisonScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductHeader(),
          const SizedBox(height: 24),
          _buildPriceComparison(),
          const SizedBox(height: 24),
          _buildPriceHistory(),
          const SizedBox(height: 24),
          _buildSimilarProducts(),
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: scannedProduct!.images.isNotEmpty
                  ? Image.network(
                scannedProduct!.images.first,
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
                    scannedProduct!.brand,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scannedProduct!.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Best Price: \$${_getBestPrice().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/product_details',
                        arguments: scannedProduct,
                      );
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Comparison',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...retailers.map((retailer) => _buildRetailerItem(retailer)),
      ],
    );
  }

  Widget _buildRetailerItem(Map<String, dynamic> retailer) {
    final logoMap = {
      'Amazon': 'assets/images/amazon_logo.png',
      'Walmart': 'assets/images/walmart_logo.png',
      'Target': 'assets/images/target_logo.png',
      'Best Buy': 'assets/images/bestbuy_logo.png',
      'Home Depot': 'assets/images/homedepot_logo.png',
    };

    final isBestPrice = retailer['price'] == _getBestPrice();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: logoMap.containsKey(retailer['name'])
            ? Image.asset(
          logoMap[retailer['name']]!,
          width: 40,
          height: 40,
        )
            : CircleAvatar(
          child: Text(retailer['name'][0]),
        ),
    title: Text(retailer['name']),
    subtitle: Text(
    retailer['inStock'] ? 'In Stock' : 'Out of Stock',
    style: TextStyle(
    color: retailer['inStock'] ? AppColors.success : AppColors.error,
    ),
    ),
    trailing: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
    Text(
    '\$${retailer['price'].toStringAsFixed(2)}',
    style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: isBestPrice ? AppColors.success : null,
    ),
    ),
    if (isBestPrice)
    Container(
    padding: const EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 2,
    ),
    decoration: BoxDecoration(
    color: AppColors.success,
    borderRadius: BorderRadius.circular(4),
    ),
    child: const Text(
    'BEST PRICE',
    style: TextStyle(
    color: Colors.white,
    fontSize: 10,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    ],
    ),
    onTap: () {
    // Open retailer website
    },
    ),
    );
  }

  Widget _buildPriceHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price History',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: scannedProduct!.priceHistory.isEmpty
              ? Center(
            child: Text(
              'No price history available',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // In a real app, this would be a chart
              // For now, we'll just display some text
              const Text(
                '* Price chart would be displayed here *',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: scannedProduct!.priceHistory.length,
                  itemBuilder: (context, index) {
                    final entry = scannedProduct!.priceHistory[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${entry.date.month}/${entry.date.day}/${entry.date.year}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            entry.retailer,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '\$${entry.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: () {
              // Set up price alerts
              _showPriceAlertDialog();
            },
            icon: const Icon(Icons.notifications_active),
            label: const Text('Set Price Alert'),
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Similar Products',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state is RecommendedProductsLoaded) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    if (product.id == scannedProduct!.id) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(
                            context,
                            '/product_details',
                            arguments: product,
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: product.images.isNotEmpty
                                  ? Image.network(
                                product.images.first,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                                  : Container(
                                height: 120,
                                width: double.infinity,
                                color: AppColors.textTertiary.withOpacity(0.2),
                                child: const Icon(Icons.image),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              return const Center(
                child: Text('No similar products found'),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _scanBarcode() async {
    try {
      setState(() {
        isLoading = true;
      });

      final barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#FF6666',
        'Cancel',
        true,
        ScanMode.BARCODE,
      );

      if (barcodeScanRes == '-1') {
        // User canceled the scan
        setState(() {
          isLoading = false;
        });
        return;
      }

      // In a real app, you would call an API to get product info
      // For demo purposes, we'll create a mock product
      await _fetchProductFromBarcode(barcodeScanRes);

      // Mock retailers data
      _generateMockRetailerData();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning barcode: ${e.toString()}'),
        ),
      );
    }
  }

  void _enterCodeManually() {
    final codeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter Barcode Manually',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Barcode',
                  hintText: 'e.g., 9781234567890',
                  prefixIcon: Icon(Icons.qr_code),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (codeController.text.trim().isNotEmpty) {
                    Navigator.pop(context);
                    _fetchProductFromBarcode(codeController.text.trim());
                    _generateMockRetailerData();
                  }
                },
                child: const Text('Search'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fetchProductFromBarcode(String barcode) async {
    // In a real app, you would call an API with the barcode
    // For demo purposes, we'll create a mock product

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      scannedProduct = Product(
        id: 'prod-${barcode.substring(0, 4)}',
        name: 'Modern Coffee Table',
        description: 'Elegant coffee table with tempered glass top and solid wood legs. Perfect for any living room.',
        price: 149.99,
        brand: 'HomeStyles',
        categories: ['Furniture', 'Living Room', 'Tables'],
        images: [
          'https://images.unsplash.com/photo-1499933374294-4584851497cc',
        ],
        modelUrl: 'https://example.com/models/coffee_table.glb',
        dimensions: {
          'width': 120.0,
          'height': 45.0,
          'depth': 60.0,
        },
        priceHistory: [
          PriceHistoryEntry(
            date: DateTime.now().subtract(const Duration(days: 90)),
            price: 179.99,
            retailer: 'HomeStyles',
          ),
          PriceHistoryEntry(
            date: DateTime.now().subtract(const Duration(days: 60)),
            price: 169.99,
            retailer: 'Amazon',
          ),
          PriceHistoryEntry(
            date: DateTime.now().subtract(const Duration(days: 30)),
            price: 159.99,
            retailer: 'Walmart',
          ),
          PriceHistoryEntry(
            date: DateTime.now().subtract(const Duration(days: 7)),
            price: 149.99,
            retailer: 'Target',
          ),
        ],
      );
    });

    // In a real app, load similar products
    context.read<ProductBloc>().add(LoadRecommendedProducts());
  }

  void _generateMockRetailerData() {
    setState(() {
      retailers = [
        {
          'name': 'Amazon',
          'price': 149.99,
          'inStock': true,
          'shippingTime': '2 days',
          'rating': 4.5,
        },
        {
          'name': 'Walmart',
          'price': 154.99,
          'inStock': true,
          'shippingTime': '3-5 days',
          'rating': 4.2,
        },
        {
          'name': 'Target',
          'price': 159.99,
          'inStock': true,
          'shippingTime': '1-2 days',
          'rating': 4.3,
        },
        {
          'name': 'Home Depot',
          'price': 164.99,
          'inStock': false,
          'shippingTime': 'N/A',
          'rating': 4.1,
        },
        {
          'name': 'Best Buy',
          'price': 169.99,
          'inStock': true,
          'shippingTime': '4-6 days',
          'rating': 4.0,
        },
      ];
    });
  }

  double _getBestPrice() {
    if (retailers.isEmpty) return scannedProduct?.price ?? 0;

    double bestPrice = double.infinity;
    for (final retailer in retailers) {
      if (retailer['inStock'] && retailer['price'] < bestPrice) {
        bestPrice = retailer['price'];
      }
    }

    return bestPrice == double.infinity ? scannedProduct?.price ?? 0 : bestPrice;
  }

  void _showPriceAlertDialog() {
    final priceController = TextEditingController(
      text: (_getBestPrice() * 0.9).toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Price Alert'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'We\'ll notify you when the price drops below:',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Set up price alert logic
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Price alert set for \$${priceController.text}',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Set Alert'),
            ),
          ],
        );
      },
    );
  }
}