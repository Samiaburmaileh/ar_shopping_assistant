// lib/screens/shopping_list/shopping_list_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/shopping_list/shopping_list_bloc.dart';
import '../../models/shopping_list_model.dart';
import '../../models/product_model.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class ShoppingListDetailScreen extends StatefulWidget {
  const ShoppingListDetailScreen({Key? key}) : super(key: key);

  @override
  State<ShoppingListDetailScreen> createState() => _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends State<ShoppingListDetailScreen> {
  late ShoppingList shoppingList;
  bool isEditing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ShoppingList) {
      shoppingList = args;
      _nameController.text = shoppingList.name;
      _descriptionController.text = shoppingList.description;
      _budgetController.text = shoppingList.budgetLimit.toString();
    } else {
      // Handle error - no shopping list passed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isEditing
            ? const Text('Edit Shopping List')
            : Text(shoppingList.name),
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _startEditing,
              tooltip: 'Edit List',
            ),
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareList,
              tooltip: 'Share List',
            ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: BlocListener<ShoppingListBloc, ShoppingListState>(
        listener: (context, state) {
          if (state is ShoppingListDetailLoaded) {
            setState(() {
              shoppingList = state.shoppingList;
            });
          } else if (state is ShoppingListError) {
            Helpers.showSnackBar(
              context,
              state.message,
              isError: true,
            );
          }
        },
        child: isEditing
            ? _buildEditForm()
            : _buildListDetails(),
      ),
      floatingActionButton: !isEditing
          ? FloatingActionButton(
        onPressed: _navigateToAddItem,
        child: const Icon(Icons.add),
        tooltip: 'Add Item',
      )
          : null,
    );
  }

  Widget _buildListDetails() {
    return Column(
      children: [
        _buildListHeader(),
        Expanded(
          child: shoppingList.items.isEmpty
              ? _buildEmptyList()
              : _buildItemsList(),
        ),
      ],
    );
  }

  Widget _buildListHeader() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shoppingList.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (shoppingList.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          shoppingList.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (shoppingList.isPublic)
                  const Chip(
                    label: Text('Shared'),
                    backgroundColor: AppColors.secondary,
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(
                  Icons.shopping_bag_outlined,
                  '${shoppingList.items.length} items',
                ),
                _buildInfoChip(
                  Icons.check_circle_outline,
                  '${shoppingList.purchasedItems} purchased',
                ),
                _buildInfoChip(
                  Icons.attach_money,
                  Helpers.formatCurrency(shoppingList.totalCost),
                ),
              ],
            ),
            if (shoppingList.budgetLimit > 0) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: shoppingList.totalCost / shoppingList.budgetLimit,
                backgroundColor: Colors.grey[200],
                color: shoppingList.isOverBudget
                    ? AppColors.error
                    : AppColors.success,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget: ${Helpers.formatCurrency(shoppingList.budgetLimit)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    shoppingList.isOverBudget
                        ? 'Over by ${Helpers.formatCurrency(shoppingList.totalCost - shoppingList.budgetLimit)}'
                        : 'Under by ${Helpers.formatCurrency(shoppingList.budgetLimit - shoppingList.totalCost)}',
                    style: TextStyle(
                      color: shoppingList.isOverBudget
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

  Widget _buildEmptyList() {
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
            'No Items Yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to your shopping list',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddItem,
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    final sortedItems = List<ShoppingItem>.from(shoppingList.items);
    sortedItems.sort((a, b) {
      if (a.purchased && !b.purchased) return 1;
      if (!a.purchased && b.purchased) return -1;
      return a.productName.compareTo(b.productName);
    });

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: sortedItems.length,
      itemBuilder: (context, index) {
        final item = sortedItems[index];
        return Dismissible(
          key: Key(item.productId),
          background: Container(
            color: AppColors.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _removeItem(item),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Checkbox(
                value: item.purchased,
                activeColor: AppColors.primary,
                onChanged: (value) => _toggleItemPurchased(item, value ?? false),
              ),
              title: Text(
                item.productName,
                style: TextStyle(
                  decoration: item.purchased
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: item.purchased
                      ? AppColors.textTertiary
                      : AppColors.textPrimary,
                ),
              ),
              subtitle: Row(
                children: [
                  Text(
                    'Qty: ${item.quantity}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  if (item.notes != null && item.notes!.isNotEmpty)
                    Icon(
                      Icons.note,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                ],
              ),
              trailing: Text(
                Helpers.formatCurrency(item.totalPrice),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: item.purchased
                      ? AppColors.textTertiary
                      : AppColors.primary,
                ),
              ),
              onTap: () => _editItem(item),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'List Name',
              hintText: 'e.g., Kitchen Remodel',
              prefixIcon: Icon(Icons.list_alt),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
              hintText: 'e.g., Items for kitchen renovation',
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _budgetController,
            decoration: const InputDecoration(
              labelText: 'Budget (Optional)',
              hintText: '0.00',
              prefixIcon: Icon(Icons.account_balance_wallet),
              prefixText: '\$ ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelEditing,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Danger Zone',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showDeleteConfirmation,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete Shopping List'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startEditing() {
    setState(() {
      isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      isEditing = false;
      _nameController.text = shoppingList.name;
      _descriptionController.text = shoppingList.description;
      _budgetController.text = shoppingList.budgetLimit.toString();
    });
  }

  void _saveChanges() {
    if (_nameController.text.trim().isEmpty) {
      Helpers.showSnackBar(
        context,
        'List name cannot be empty',
        isError: true,
      );
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final budgetText = _budgetController.text.trim();
    final budget = budgetText.isEmpty
        ? 0.0
        : double.tryParse(budgetText) ?? 0.0;

    final updatedList = ShoppingList(
      id: shoppingList.id,
      name: name,
      description: description,
      items: shoppingList.items,
      budgetLimit: budget,
      sharedWithUsers: shoppingList.sharedWithUsers,
      isPublic: shoppingList.isPublic,
      createdAt: shoppingList.createdAt,
      updatedAt: DateTime.now(),
    );

    context.read<ShoppingListBloc>().add(
      UpdateShoppingList(shoppingList: updatedList),
    );

    setState(() {
      shoppingList = updatedList;
      isEditing = false;
    });
  }

  void _shareList() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Share Shopping List'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'friend@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
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
                if (emailController.text.trim().isNotEmpty) {
                  context.read<ShoppingListBloc>().add(
                    ShareShoppingList(
                      listId: shoppingList.id,
                      email: emailController.text.trim(),
                    ),
                  );
                  Navigator.pop(context);
                  Helpers.showSnackBar(
                    context,
                    'Shopping list shared with ${emailController.text.trim()}',
                  );
                }
              },
              child: const Text('Share'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Shopping List'),
          content: const Text(
            'Are you sure you want to delete this shopping list? This action cannot be undone.',
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
                Navigator.pop(context);
                context.read<ShoppingListBloc>().add(
                  DeleteShoppingList(listId: shoppingList.id),
                );
                Navigator.pop(context); // Return to shopping lists screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAddItem() {
    Navigator.pushNamed(
      context,
      '/product_search',
      arguments: {
        'onProductSelected': (Product product) {
          _showAddItemDialog(product);
        },
      },
    );
  }

  void _showAddItemDialog(Product product) {
    final quantityController = TextEditingController(text: '1');
    final notesController = TextEditingController();

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
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    'Add to Shopping List',
    style: Theme.of(context).textTheme.titleLarge,
    textAlign: TextAlign.center,
    ),
    const SizedBox(height: 16),
    ListTile(
    contentPadding: EdgeInsets.zero,
    leading: product.images.isNotEmpty
    ? ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: Image.network(
    product.images.first,
    width: 48,
    height: 48,
    fit: BoxFit.cover,
    ),
    )
        : Container(
    width: 48,
    height: 48,
    color: Colors.grey[300],
    child: const Icon(Icons.image),
    ),
    title: Text(product.name),
    subtitle: Text(Helpers.formatCurrency(product.price)),
    ),
    const SizedBox(height: 16),
    Row(
    children: [
    Expanded(
    child: TextField(
    controller: quantityController,
    decoration: const InputDecoration(
    labelText: 'Quantity',
    prefixIcon: Icon(Icons.numbers),
    ),
    keyboardType: TextInputType.number,
    ),
    ),
    ],
    ),
      const SizedBox(height: 16),
      TextField(
        controller: notesController,
        decoration: const InputDecoration(
          labelText: 'Notes (Optional)',
          prefixIcon: Icon(Icons.note),
          hintText: 'e.g., Get the blue one if available',
        ),
        maxLines: 2,
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            final quantity = int.tryParse(quantityController.text) ?? 1;
            final notes = notesController.text.trim();

            context.read<ShoppingListBloc>().add(
              AddToShoppingList(
                listId: shoppingList.id,
                product: product,
                quantity: quantity,
                notes: notes.isNotEmpty ? notes : null,
              ),
            );

            Navigator.pop(context);

            Helpers.showSnackBar(
              context,
              '${product.name} added to shopping list',
            );
          },
          child: const Text('Add to List'),
        ),
      ),
    ],
    ),
    );
    },
    );
  }

  void _toggleItemPurchased(ShoppingItem item, bool purchased) {
    context.read<ShoppingListBloc>().add(
      ToggleItemPurchased(
        listId: shoppingList.id,
        productId: item.productId,
        purchased: purchased,
      ),
    );
  }

  void _removeItem(ShoppingItem item) {
    context.read<ShoppingListBloc>().add(
      RemoveFromShoppingList(
        listId: shoppingList.id,
        productId: item.productId,
      ),
    );

    Helpers.showSnackBar(
      context,
      '${item.productName} removed from list',
    );
  }

  void _editItem(ShoppingItem item) {
    final quantityController = TextEditingController(text: item.quantity.toString());
    final notesController = TextEditingController(text: item.notes ?? '');

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Item',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                item.productName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Price: ${Helpers.formatCurrency(item.price)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: Icon(Icons.note),
                  hintText: 'e.g., Get the blue one if available',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final quantity = int.tryParse(quantityController.text) ?? 1;
                        final notes = notesController.text.trim();

                        final updatedItem = ShoppingItem(
                          productId: item.productId,
                          productName: item.productName,
                          price: item.price,
                          quantity: quantity,
                          purchased: item.purchased,
                          notes: notes.isNotEmpty ? notes : null,
                          arAnnotationReference: item.arAnnotationReference,
                        );

                        context.read<ShoppingListBloc>().add(
                          UpdateShoppingItem(
                            listId: shoppingList.id,
                            item: updatedItem,
                          ),
                        );

                        Navigator.pop(context);
                      },
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}