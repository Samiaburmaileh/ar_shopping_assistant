import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/product_model.dart';
import '../../services/product_service.dart';


// Events
abstract class ProductEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadFeaturedProducts extends ProductEvent {}

class LoadRecommendedProducts extends ProductEvent {}

class LoadRecentlyViewedProducts extends ProductEvent {}

class SearchProducts extends ProductEvent {
  final String query;

  SearchProducts({required this.query});

  @override
  List<Object> get props => [query];
}

class ViewProduct extends ProductEvent {
  final Product product;

  ViewProduct({required this.product});

  @override
  List<Object> get props => [product];
}

// States
abstract class ProductState extends Equatable {
  @override
  List<Object> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class FeaturedProductsLoaded extends ProductState {
  final List<Product> products;

  FeaturedProductsLoaded({required this.products});

  @override
  List<Object> get props => [products];
}

class RecommendedProductsLoaded extends ProductState {
  final List<Product> products;

  RecommendedProductsLoaded({required this.products});

  @override
  List<Object> get props => [products];
}

class RecentlyViewedProductsLoaded extends ProductState {
  final List<Product> products;

  RecentlyViewedProductsLoaded({required this.products});

  @override
  List<Object> get props => [products];
}

class SearchResultsLoaded extends ProductState {
  final List<Product> products;
  final String query;

  SearchResultsLoaded({required this.products, required this.query});

  @override
  List<Object> get props => [products, query];
}

class ProductError extends ProductState {
  final String message;

  ProductError({required this.message});

  @override
  List<Object> get props => [message];
}

// Bloc
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductService _productService = ProductService();

  ProductBloc() : super(ProductInitial()) {
    on<LoadFeaturedProducts>(_onLoadFeaturedProducts);
    on<LoadRecommendedProducts>(_onLoadRecommendedProducts);
    on<LoadRecentlyViewedProducts>(_onLoadRecentlyViewedProducts);
    on<SearchProducts>(_onSearchProducts);
    on<ViewProduct>(_onViewProduct);
  }

  Future<void> _onLoadFeaturedProducts(
      LoadFeaturedProducts event,
      Emitter<ProductState> emit,
      ) async {
    emit(ProductLoading());
    try {
      final products = await _productService.getFeaturedProducts();
      emit(FeaturedProductsLoaded(products: products));

      // Also load recommended and recently viewed
      add(LoadRecommendedProducts());
      add(LoadRecentlyViewedProducts());
    } catch (e) {
      emit(ProductError(message: e.toString()));
    }
  }

  Future<void> _onLoadRecommendedProducts(
      LoadRecommendedProducts event,
      Emitter<ProductState> emit,
      ) async {
    try {
      final products = await _productService.getRecommendedProducts();
      emit(RecommendedProductsLoaded(products: products));
    } catch (e) {
      // Silently fail for recommendations
    }
  }

  Future<void> _onLoadRecentlyViewedProducts(
      LoadRecentlyViewedProducts event,
      Emitter<ProductState> emit,
      ) async {
    try {
      final products = await _productService.getRecentlyViewedProducts();
      emit(RecentlyViewedProductsLoaded(products: products));
    } catch (e) {
      // Silently fail for history
    }
  }

  Future<void> _onSearchProducts(
      SearchProducts event,
      Emitter<ProductState> emit,
      ) async {
    emit(ProductLoading());
    try {
      final products = await _productService.searchProducts(event.query);
      emit(SearchResultsLoaded(products: products, query: event.query));
    } catch (e) {
      emit(ProductError(message: e.toString()));
    }
  }

  Future<void> _onViewProduct(
      ViewProduct event,
      Emitter<ProductState> emit,
      ) async {
    try {
      await _productService.recordProductView(event.product);
    } catch (e) {
      // Silently fail for view tracking
    }
  }
}