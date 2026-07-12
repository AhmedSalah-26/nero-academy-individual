import 'package:equatable/equatable.dart';
import 'package:lms_platform/core/errors/failures.dart';

/// Base State Status
enum StateStatus {
  initial,
  loading,
  success,
  error,
}

/// Base State for Cubits/Blocs
abstract class BaseState extends Equatable {
  final StateStatus status;
  final Failure? failure;
  final String? message;

  const BaseState({
    this.status = StateStatus.initial,
    this.failure,
    this.message,
  });

  bool get isInitial => status == StateStatus.initial;
  bool get isLoading => status == StateStatus.loading;
  bool get isSuccess => status == StateStatus.success;
  bool get isError => status == StateStatus.error;

  String? get errorMessage => failure?.message ?? message;

  @override
  List<Object?> get props => [status, failure, message];
}

/// Simple State with data
class DataState<T> extends BaseState {
  final T? data;

  const DataState({
    super.status,
    super.failure,
    super.message,
    this.data,
  });

  DataState<T> copyWith({
    StateStatus? status,
    Failure? failure,
    String? message,
    T? data,
  }) {
    return DataState<T>(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  @override
  List<Object?> get props => [...super.props, data];
}

/// List State with pagination support
class ListState<T> extends BaseState {
  final List<T> items;
  final bool hasMore;
  final int page;
  final bool isLoadingMore;

  const ListState({
    super.status,
    super.failure,
    super.message,
    this.items = const [],
    this.hasMore = true,
    this.page = 1,
    this.isLoadingMore = false,
  });

  ListState<T> copyWith({
    StateStatus? status,
    Failure? failure,
    String? message,
    List<T>? items,
    bool? hasMore,
    int? page,
    bool? isLoadingMore,
  }) {
    return ListState<T>(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      message: message ?? this.message,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props =>
      [...super.props, items, hasMore, page, isLoadingMore];
}
