// Cart & Checkout Feature - Barrel file
// Domain
export 'domain/entities/cart_entity.dart';
export 'domain/entities/cart_item_entity.dart';
export 'domain/entities/coupon_entity.dart';
export 'domain/entities/payment_method_entity.dart';
export 'domain/entities/order_entity.dart';
export 'domain/repositories/cart_repository.dart';
export 'domain/usecases/get_cart_usecase.dart';
export 'domain/usecases/add_to_cart_usecase.dart';
export 'domain/usecases/remove_from_cart_usecase.dart';
export 'domain/usecases/apply_coupon_usecase.dart';
export 'domain/usecases/remove_coupon_usecase.dart';
export 'domain/usecases/checkout_usecase.dart';

// Data
export 'data/models/cart_model.dart';
export 'data/models/cart_item_model.dart';
export 'data/models/coupon_model.dart';
export 'data/models/payment_method_model.dart';
export 'data/models/order_model.dart';
export 'data/datasources/cart_remote_data_source.dart';
export 'data/datasources/cart_local_data_source.dart';
export 'data/repositories/cart_repository_impl.dart';

// Presentation
export 'presentation/cubit/cart_cubit.dart';
export 'presentation/cubit/cart_state.dart';
export 'presentation/cubit/checkout_cubit.dart';
export 'presentation/cubit/checkout_state.dart';
export 'presentation/screens/cart_screen.dart';
export 'presentation/screens/checkout_screen.dart';
export 'presentation/screens/payment_success_screen.dart';

// Widgets - Cart
export 'presentation/widgets/cart/cart_app_bar.dart';
export 'presentation/widgets/cart/cart_content.dart';
export 'presentation/widgets/cart/cart_empty_state.dart';
export 'presentation/widgets/cart/cart_error_state.dart';
export 'presentation/widgets/cart/cart_item_card.dart';
export 'presentation/widgets/cart/cart_loading_state.dart';
export 'presentation/widgets/cart/cart_summary_card.dart';
export 'presentation/widgets/cart/coupon_section.dart';
