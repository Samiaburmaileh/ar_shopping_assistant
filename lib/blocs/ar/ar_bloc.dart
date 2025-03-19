import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/product_model.dart';
import '../../services/ar_service.dart';

// Events
abstract class ArEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadArModels extends ArEvent {}

class LoadProductModel extends ArEvent {
  final Product product;

  LoadProductModel({required this.product});

  @override
  List<Object> get props => [product];
}

class SaveArMeasurement extends ArEvent {
  final double distance;
  final String productId;

  SaveArMeasurement({required this.distance, required this.productId});

  @override
  List<Object> get props => [distance, productId];
}

class SaveArScreenshot extends ArEvent {
  final String imagePath;
  final String productId;

  SaveArScreenshot({required this.imagePath, required this.productId});

  @override
  List<Object> get props => [imagePath, productId];
}

// States
abstract class ArState extends Equatable {
  @override
  List<Object> get props => [];
}

class ArInitial extends ArState {}

class ArLoading extends ArState {}

class ArModelLoaded extends ArState {
  final String modelUrl;
  final Product product;

  ArModelLoaded({required this.modelUrl, required this.product});

  @override
  List<Object> get props => [modelUrl, product];
}

class ArMeasurementSaved extends ArState {
  final double distance;

  ArMeasurementSaved({required this.distance});

  @override
  List<Object> get props => [distance];
}

class ArScreenshotSaved extends ArState {
  final String imagePath;

  ArScreenshotSaved({required this.imagePath});

  @override
  List<Object> get props => [imagePath];
}

class ArError extends ArState {
  final String message;

  ArError({required this.message});

  @override
  List<Object> get props => [message];
}

// Bloc
class ArBloc extends Bloc<ArEvent, ArState> {
  final ArService _arService = ArService();

  ArBloc() : super(ArInitial()) {
    on<LoadArModels>(_onLoadArModels);
    on<LoadProductModel>(_onLoadProductModel);
    on<SaveArMeasurement>(_onSaveArMeasurement);
    on<SaveArScreenshot>(_onSaveArScreenshot);
  }

  Future<void> _onLoadArModels(
      LoadArModels event,
      Emitter<ArState> emit,
      ) async {
    emit(ArLoading());
    try {
      await _arService.preloadCommonModels();
      emit(ArInitial());
    } catch (e) {
      emit(ArError(message: 'Failed to load AR models: ${e.toString()}'));
    }
  }

  Future<void> _onLoadProductModel(
      LoadProductModel event,
      Emitter<ArState> emit,
      ) async {
    emit(ArLoading());
    try {
      final modelUrl = await _arService.getModelUrl(event.product);
      emit(ArModelLoaded(modelUrl: modelUrl, product: event.product));
    } catch (e) {
      emit(ArError(message: 'Failed to load product model: ${e.toString()}'));
    }
  }

  Future<void> _onSaveArMeasurement(
      SaveArMeasurement event,
      Emitter<ArState> emit,
      ) async {
    try {
      await _arService.saveMeasurement(
        distance: event.distance,
        productId: event.productId,
      );
      emit(ArMeasurementSaved(distance: event.distance));
    } catch (e) {
      emit(ArError(message: 'Failed to save measurement: ${e.toString()}'));
    }
  }

  Future<void> _onSaveArScreenshot(
      SaveArScreenshot event,
      Emitter<ArState> emit,
      ) async {
    try {
      final savedPath = await _arService.saveScreenshot(
        imagePath: event.imagePath,
        productId: event.productId,
      );
      emit(ArScreenshotSaved(imagePath: savedPath));
    } catch (e) {
      emit(ArError(message: 'Failed to save screenshot: ${e.toString()}'));
    }
  }
}