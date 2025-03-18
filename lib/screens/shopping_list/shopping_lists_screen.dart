import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/shopping_list/shopping_list_bloc.dart';
import '../../models/shopping_list_model.dart';
import '../../utils/constants.dart';


class ShoppingListsScreen extends StatefulWidget {
  const ShoppingListsScreen({Key? key}) : super(key: key);

  @override
  State<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ShoppingListBloc>().add(LoadShoppingLists());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search functionality
            },
            tooltip: 'Search Lists',
          ),
        ],
      ),
      body: BlocBuilder<ShoppingListBloc, ShoppingListState>(
        builder: (context, state) {
          if (state is ShoppingListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ShoppingListsLoaded) {
            if (state.shoppingLists.isEmpty) {
              return _buildEmptyState();
            }

            return _buildShoppingLists(state.shoppingLists);
          }

          if (state is ShoppingListError) {
            return Center(
              child: Text('Error: ${state.message}'),
            );
          }

          return const Center(child: Text('No shopping lists found'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateListDialog();
        },
        child: const Icon(Icons.add),
        tooltip: 'Create New List',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Shopping Lists Yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first shopping list to keep track of items you want to buy',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showCreateListDialog();
            },
            icon: const Icon(Icons.add),
            label: const Text('Create New List'),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingLists(List<ShoppingList> lists) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/shopping_list_details',
                arguments: list,
              );
            },
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          list.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (list.isPublic)
                        const Chip(
                          label: Text('Shared'),
                          backgroundColor: AppColors.secondary,
                          labelStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                  if (list.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      list.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoChip(
                        Icons.shopping_bag_outlined,
                        '${list.totalItems} items',
                      ),
                      _buildInfoChip(
                        Icons.check_circle_outline,
                        '${list.purchasedItems}/${list.items.length} purchased',
                      ),
                      _buildInfoChip(
                        Icons.attach_money,
                        '\$${list.totalCost.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                  if (list.budgetLimit > 0) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: list.totalCost / list.budgetLimit,
                      backgroundColor: Colors.grey[200],
                      color: list.isOverBudget
                          ? AppColors.error
                          : AppColors.success,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Budget: \$${list.budgetLimit.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          list.isOverBudget
                              ? 'Over by \$${(list.totalCost - list.budgetLimit).toStringAsFixed(2)}'
                              : 'Under by \$${(list.budgetLimit - list.totalCost).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: list.isOverBudget
                                ? AppColors.error
                                : AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showCreateListDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final budgetController = TextEditingController();
    bool isPublic = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    'Create New Shopping List',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'List Name',
                      hintText: 'e.g., Kitchen Remodel',
                      prefixIcon: Icon(Icons.list_alt),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'e.g., Items for kitchen renovation',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: budgetController,
                    decoration: const InputDecoration(
                      labelText: 'Budget (Optional)',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: isPublic,
                        onChanged: (value) {
                          setState(() {
                            isPublic = value ?? false;
                          });
                        },
                      ),
                      const Text('Share this list with others'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) {
                        return;
                      }

                      final name = nameController.text.trim();
                      final description = descriptionController.text.trim();
                      final budgetText = budgetController.text.trim();
                      final budget = budgetText.isEmpty
                          ? 0.0
                          : double.tryParse(budgetText) ?? 0.0;

                      context.read<ShoppingListBloc>().add(
                        CreateShoppingList(
                          name: name,
                          description: description,
                          budgetLimit: budget,
                          isPublic: isPublic,
                        ),
                      );

                      Navigator.pop(context);
                    },
                    child: const Text('Create List'),
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
      },
    );
  }
}