import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/shopping_list_model.dart';
import '../../models/product_model.dart';
import '../../services/ShoppingListService.dart';

// Events
abstract class ShoppingListEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadShoppingLists extends ShoppingListEvent {}

class CreateShoppingList extends ShoppingListEvent {
  final String name;
  final String description;
  final double budgetLimit;
  final bool isPublic;

  CreateShoppingList({
    required this.name,
    this.description = '',
    this.budgetLimit = 0,
    this.isPublic = false,
  });

  @override
  List<Object> get props => [name, description, budgetLimit, isPublic];
}

class UpdateShoppingList extends ShoppingListEvent {
  final ShoppingList shoppingList;

  UpdateShoppingList({required this.shoppingList});

  @override
  List<Object> get props => [shoppingList];
}

class DeleteShoppingList extends ShoppingListEvent {
  final String listId;

  DeleteShoppingList({required this.listId});

  @override
  List<Object> get props => [listId];
}

class AddToShoppingList extends ShoppingListEvent {
  final String listId;
  final Product product;
  final int quantity;
  final String? notes;

  AddToShoppingList({
    required this.listId,
    required this.product,
    this.quantity = 1,
    this.notes,
  });

  @override
  List<Object> get props => [listId, product, quantity, notes ?? ''];
}

class RemoveFromShoppingList extends ShoppingListEvent {
  final String listId;
  final String productId;

  RemoveFromShoppingList({
    required this.listId,
    required this.productId,
  });

  @override
  List<Object> get props => [listId, productId];
}

class UpdateShoppingItem extends ShoppingListEvent {
  final String listId;
  final ShoppingItem item;

  UpdateShoppingItem({
    required this.listId,
    required this.item,
  });

  @override
  List<Object> get props => [listId, item];
}

class ToggleItemPurchased extends ShoppingListEvent {
  final String listId;
  final String productId;
  final bool purchased;

  ToggleItemPurchased({
    required this.listId,
    required this.productId,
    required this.purchased,
  });

  @override
  List<Object> get props => [listId, productId, purchased];
}

class ShareShoppingList extends ShoppingListEvent {
  final String listId;
  final String email;

  ShareShoppingList({
    required this.listId,
    required this.email,
  });

  @override
  List<Object> get props => [listId, email];
}

// States
abstract class ShoppingListState extends Equatable {
  @override
  List<Object> get props => [];
}

class ShoppingListInitial extends ShoppingListState {}

class ShoppingListLoading extends ShoppingListState {}

class ShoppingListsLoaded extends ShoppingListState {
  final List<ShoppingList> shoppingLists;

  ShoppingListsLoaded({required this.shoppingLists});

  @override
  List<Object> get props => [shoppingLists];
}

class ShoppingListDetailLoaded extends ShoppingListState {
  final ShoppingList shoppingList;

  ShoppingListDetailLoaded({required this.shoppingList});

  @override
  List<Object> get props => [shoppingList];
}

class ShoppingListError extends ShoppingListState {
  final String message;

  ShoppingListError({required this.message});

  @override
  List<Object> get props => [message];
}

// Bloc
class ShoppingListBloc extends Bloc<ShoppingListEvent, ShoppingListState> {
  final ShoppingListService _shoppingListService = ShoppingListService();

  ShoppingListBloc() : super(ShoppingListInitial()) {
    on<LoadShoppingLists>(_onLoadShoppingLists);
    on<CreateShoppingList>(_onCreateShoppingList);
    on<UpdateShoppingList>(_onUpdateShoppingList);
    on<DeleteShoppingList>(_onDeleteShoppingList);
    on<AddToShoppingList>(_onAddToShoppingList);
    on<RemoveFromShoppingList>(_onRemoveFromShoppingList);
    on<UpdateShoppingItem>(_onUpdateShoppingItem);
    on<ToggleItemPurchased>(_onToggleItemPurchased);
    on<ShareShoppingList>(_onShareShoppingList);
  }

  Future<void> _onLoadShoppingLists(
      LoadShoppingLists event,
      Emitter<ShoppingListState> emit,
      ) async {
    emit(ShoppingListLoading());
    try {
      final shoppingLists = await _shoppingListService.getShoppingLists();
      emit(ShoppingListsLoaded(shoppingLists: shoppingLists));
    } catch (e) {
      emit(ShoppingListError(message: e.toString()));
    }
  }

  Future<void> _onCreateShoppingList(
      CreateShoppingList event,
      Emitter<ShoppingListState> emit,
      ) async {
    emit(ShoppingListLoading());
    try {
      await _shoppingListService.createShoppingList(
        name: event.name,
        description: event.description,
        budgetLimit: event.budgetLimit,
        isPublic: event.isPublic,
      );

      final shoppingLists = await _shoppingListService.getShoppingLists();
      emit(ShoppingListsLoaded(shoppingLists: shoppingLists));
    } catch (e) {
      emit(ShoppingListError(message: e.toString()));
    }
  }

  Future<void> _onUpdateShoppingList(
      UpdateShoppingList event,
      Emitter<ShoppingListState> emit,
      ) async {
    emit(ShoppingListLoading());
    try {
      await _shoppingListService.updateShoppingList(event.shoppingList);

      final shoppingLists = await _shoppingListService.getShoppingLists();
      emit(ShoppingListsLoaded(shoppingLists: shoppingLists));
    } catch (e) {
      emit(ShoppingListError(message: e.toString()));
    }
  }

  Future<void> _onDeleteShoppingList(
      DeleteShoppingList event,
      Emitter<ShoppingListState> emit,
      ) async {
    emit(ShoppingListLoading());
    try {
      await _shoppingListService.deleteShoppingList(event.listId);

      final shoppingLists = await _shoppingListService.getShoppingLists();
      emit(ShoppingListsLoaded(shoppingLists: shoppingLists));
    } catch (e) {
      emit(ShoppingListError(message: e.toString()));
    }
  }

  Future<void> _onAddToShoppingList(
      AddToShoppingList event,
      Emitter<ShoppingListState> emit,
      ) async {
    try {
      // Create a new shopping item from the product
      final item = ShoppingItem(
        productId: event.product.id,
        productName: event.product.name,
        price: event.product.price,
        quantity: event.quantity,
        notes: event.notes,
      );

      await _shoppingListService.addItemToList(
        listId: event.listId,
        item: item,
      );

      // If we're in a list detail view, reload that specific list
      if (state is ShoppingListDetailLoaded) {
        final updatedList = await _shoppingListService.getShoppingList(event.listId);
        emit(ShoppingListDetailLoaded(shoppingList: updatedList));
      } else {
        // Otherwise reload all lists
        final shoppingLists = await _shoppingListService.getShoppingLists();
        emit(ShoppingListsLoaded(shoppingLists: shoppingLists));
      }
    } catch (e) {
      emit(ShoppingListError(message: e.toString()));
    }
  }

  Future<void> _onRemoveFromShoppingList(
      RemoveFromShoppingList event,
      Emitter<ShoppingListState> emit,
      ) async {
    try {
      await _shoppingListService.removeItemFromList(
        listId: event.listId,
        productId: event.productId,
      );

      // If we're in a list detail view, reload that specific list
      if (state is ShoppingListDetailLoaded) {
        final updatedList = await _shoppingListService.getShoppingList(event.listId);
        emit(ShoppingListDetailLoaded(shoppingList: updatedList));
      } else {
        // Otherwise reload all lists
        final shoppingLists = await _shoppingListService.getShoppingLists();
        emit(ShoppingListsLoaded(shoppingLists: shoppingLists));
      }
    } catch (e) {
      emit(ShoppingListError(message: e.toString()));
    }
  }

  Future<void> _onUpdateShoppingItem(
      UpdateShoppingItem event,
      Emitter<ShoppingListState> emit,
      ) async {
    try {
      await _shoppingListService.updateItemInList(
        listId: event.listId,
        item: event.item,
      );

      // If we're in a list detail view, reload that specific list
      if (state is ShoppingListDetailLoaded) {
        final updatedList = await _shoppingListService.getShoppingList(event.listId);
        emit(ShoppingListDetailLoaded(shoppingList: updatedList));
      }
    } catch (e) {
      emit(ShoppingListError(message: e.toString()));
    }
  }

  Future<void> _onToggleItemPurchased(
      ToggleItemPurchased event,
      Emitter<ShoppingListState> emit,
      ) async {
    try {
      await _shoppingListService.toggleItemPurchased(
        listId: event.listId,
        productId: event.productId,
        purchased: event.purchased,
      );

      // If we're in a list detail view, reload that specific list
      if (state is ShoppingListDetailLoaded) {
        final updatedList = await _shoppingListService.getShoppingList(event.listId);
        emit(ShoppingListDetailLoaded(shoppingList: updatedList));
      }
    } catch (e) {
      emit(ShoppingListError(message: e.toString()));
    }
  }

  Future<void> _onShareShoppingList(
      ShareShoppingList event,
      Emitter<ShoppingListState> emit,
      ) async {
    try {
      await _shoppingListService.shareShoppingList(
        listId: event.listId,
        email: event.email,
      );

      // If we're in a list detail view, reload that specific list
      if (state is ShoppingListDetailLoaded) {
        final updatedList = await _shoppingListService.getShoppingList(event.listId);
        emit(ShoppingListDetailLoaded(shoppingList: updatedList));
      } else {
        // Otherwise reload all lists
        final shoppingLists = await _shoppingListService.getShoppingLists();
        emit(ShoppingListsLoaded(shoppingLists: shoppingLists));
      }
    } catch (e) {
      emit(ShoppingListError(message: e.toString()));
    }
  }
}