import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

/// Auth Status
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
  needsInterests,
  otpSent,
  phoneLinkOtpSent, // OTP تم إرسال رمز ربط الهاتف
  phoneLinked, // تم ربط الهاتف بنجاح
  needsPhoneLink, // يحتاج ربط الهاتف (بعد التسجيل)
  awaitingEmailVerification, // بانتظار تأكيد البريد الإلكتروني
}

/// Auth State
class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;
  final bool isLoggingOut;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isLoggingOut = false,
  });

  // ============ Factory Constructors ============

  const AuthState.initial() : this();

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.authenticated(UserEntity user)
      : this(
          status: AuthStatus.authenticated,
          user: user,
        );

  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  const AuthState.error(String message)
      : this(
          status: AuthStatus.error,
          errorMessage: message,
        );

  const AuthState.otpSent() : this(status: AuthStatus.otpSent);

  const AuthState.phoneLinkOtpSent({UserEntity? user})
      : this(status: AuthStatus.phoneLinkOtpSent, user: user);

  const AuthState.phoneLinked(UserEntity user)
      : this(status: AuthStatus.phoneLinked, user: user);

  const AuthState.needsPhoneLink(UserEntity user)
      : this(status: AuthStatus.needsPhoneLink, user: user);

  const AuthState.awaitingEmailVerification()
      : this(status: AuthStatus.awaitingEmailVerification);

  // ============ Getters ============

  bool get isInitial => status == AuthStatus.initial;
  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isError => status == AuthStatus.error;
  bool get needsInterests => status == AuthStatus.needsInterests;
  bool get isOtpSent => status == AuthStatus.otpSent;
  bool get isPhoneLinkOtpSent => status == AuthStatus.phoneLinkOtpSent;
  bool get isPhoneLinked => status == AuthStatus.phoneLinked;
  bool get needsPhoneLink => status == AuthStatus.needsPhoneLink;
  bool get isAwaitingEmailVerification => status == AuthStatus.awaitingEmailVerification;

  bool get isLoggedIn =>
      status == AuthStatus.authenticated ||
      status == AuthStatus.needsInterests ||
      status == AuthStatus.needsPhoneLink ||
      status == AuthStatus.phoneLinked;

  // ============ Copy With ============

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
    bool? isLoggingOut,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, isLoggingOut];
}
