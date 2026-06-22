import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/login_with_google_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/send_phone_otp_usecase.dart';
import '../../domain/usecases/update_interests_usecase.dart';
import '../../domain/usecases/verify_phone_otp_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final LoginWithGoogleUseCase _loginWithGoogleUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final UpdateInterestsUseCase _updateInterestsUseCase;
  final SendPhoneOtpUseCase _sendPhoneOtpUseCase;
  final VerifyPhoneOtpUseCase _verifyPhoneOtpUseCase;

  AuthCubit({
    required LoginUseCase loginUseCase,
    required LoginWithGoogleUseCase loginWithGoogleUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required UpdateInterestsUseCase updateInterestsUseCase,
    required SendPhoneOtpUseCase sendPhoneOtpUseCase,
    required VerifyPhoneOtpUseCase verifyPhoneOtpUseCase,
  })  : _loginUseCase = loginUseCase,
        _loginWithGoogleUseCase = loginWithGoogleUseCase,
        _registerUseCase = registerUseCase,
        _logoutUseCase = logoutUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        _forgotPasswordUseCase = forgotPasswordUseCase,
        _updateInterestsUseCase = updateInterestsUseCase,
        _sendPhoneOtpUseCase = sendPhoneOtpUseCase,
        _verifyPhoneOtpUseCase = verifyPhoneOtpUseCase,
        super(const AuthState.initial());

  /// Check current auth status
  Future<void> checkAuthStatus() async {
    emit(const AuthState.loading());

    final result = await _getCurrentUserUseCase();

    result.fold(
      (failure) => emit(const AuthState.unauthenticated()),
      (user) {
        if (user != null) {
          emit(AuthState.authenticated(user));
        } else {
          emit(const AuthState.unauthenticated());
        }
      },
    );
  }

  /// Login with email and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthState.loading());

    final result = await _loginUseCase(LoginParams(
      email: email,
      password: password,
    ));

    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  /// Login or sign up with Google.
  Future<void> loginWithGoogle() async {
    emit(const AuthState.loading());

    final result = await _loginWithGoogleUseCase();

    result.fold(
      (failure) {
        if (failure.code == 'oauth_redirect_started') {
          emit(const AuthState.unauthenticated());
        } else {
          emit(AuthState.error(failure.message));
        }
      },
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  /// Register new user
  Future<void> register({
    required String email,
    required String password,
    required String name,
    UserRole role = UserRole.student,
    String? phone,
    String? headline,
    String? bio,
    List<String>? expertise,
    Uint8List? avatarBytes,
  }) async {
    debugPrint(
        '📝 [AuthCubit] Register called with email: $email, phone: $phone');
    emit(const AuthState.loading());

    final result = await _registerUseCase(RegisterParams(
      email: email,
      password: password,
      name: name,
      role: role,
      phone: phone,
      headline: headline,
      bio: bio,
      expertise: expertise,
      avatarBytes: avatarBytes,
    ));

    result.fold(
      (failure) {
        debugPrint('❌ [AuthCubit] Register failed: ${failure.message}');
        emit(AuthState.error(failure.message));
      },
      (user) {
        debugPrint(
            '✅ [AuthCubit] Register successful: ${user.email}, id: ${user.id}');

        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          debugPrint('📧 [AuthCubit] Session is null, user must confirm email');
          emit(const AuthState.awaitingEmailVerification());
        } else {
          debugPrint(
              '✅ [AuthCubit] Emitting authenticated state after registration');
          emit(AuthState.authenticated(user));
        }
      },
    );
  }

  /// Logout
  Future<void> logout() async {
    emit(state.copyWith(isLoggingOut: true));

    final result = await _logoutUseCase();

    result.fold(
      (failure) => emit(state.copyWith(
        isLoggingOut: false,
        errorMessage: failure.message,
      )),
      (_) => emit(const AuthState.unauthenticated()),
    );
  }

  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    emit(const AuthState.loading());

    final result = await _forgotPasswordUseCase(email);

    return result.fold(
      (failure) {
        emit(AuthState.error(failure.message));
        return false;
      },
      (_) {
        emit(const AuthState.unauthenticated());
        return true;
      },
    );
  }

  /// Update interests
  Future<void> updateInterests(List<String> interests) async {
    if (state.user == null) return;

    if (isClosed) return;
    emit(const AuthState.loading());

    final result = await _updateInterestsUseCase(interests);

    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  /// Send OTP to phone number
  Future<bool> sendPhoneOtp(String phoneNumber) async {
    if (isClosed) return false;
    emit(const AuthState.loading());

    final result = await _sendPhoneOtpUseCase(phoneNumber);

    if (isClosed) return false;
    return result.fold(
      (failure) {
        emit(AuthState.error(failure.message));
        return false;
      },
      (_) {
        emit(const AuthState.otpSent());
        return true;
      },
    );
  }

  /// Verify OTP and login
  Future<void> verifyPhoneOtp(String phoneNumber, String otp) async {
    debugPrint(
        '🔐 [AuthCubit] verifyPhoneOtp called with phone: $phoneNumber, otp: $otp');
    emit(const AuthState.loading());

    // Development bypass: accept 000000 as valid OTP
    if (otp == '000000') {
      debugPrint('🔓 [AuthCubit] Using development bypass with OTP 000000');

      // استدعاء الـ use case مع 000000 لتفعيل الـ bypass في الـ data source
      debugPrint('[AuthCubit] Calling verifyPhoneOtpUseCase with bypass OTP');
      final result = await _verifyPhoneOtpUseCase(
        VerifyPhoneOtpParams(phoneNumber: phoneNumber, otp: otp),
      );

      result.fold(
        (failure) {
          debugPrint(
              '❌ [AuthCubit] OTP verification failed: ${failure.message}');
          emit(AuthState.error(failure.message));
        },
        (user) {
          debugPrint(
              '✅ [AuthCubit] OTP verified successfully (bypass): ${user.email}');
          emit(AuthState.authenticated(user));
        },
      );
      return;
    }

    debugPrint('📞 [AuthCubit] Calling Supabase OTP verification');
    final result = await _verifyPhoneOtpUseCase(
      VerifyPhoneOtpParams(phoneNumber: phoneNumber, otp: otp),
    );

    result.fold(
      (failure) {
        debugPrint('❌ [AuthCubit] OTP verification failed: ${failure.message}');
        emit(AuthState.error(failure.message));
      },
      (user) {
        debugPrint('✅ [AuthCubit] OTP verified successfully: ${user.email}');
        emit(AuthState.authenticated(user));
      },
    );
  }

  // ============ ربط الهاتف بحساب موجود ============

  /// إرسال OTP لربط الهاتف بالحساب الحالي
  Future<bool> sendLinkPhoneOtp(String phoneNumber) async {
    debugPrint('📱 [AuthCubit] sendLinkPhoneOtp called with: $phoneNumber');
    final currentUser = state.user;
    debugPrint('👤 [AuthCubit] Current user: ${currentUser?.email ?? "null"}');

    if (isClosed) return false;
    emit(const AuthState.loading());

    try {
      final result = await _sendPhoneOtpUseCase.sendLinkOtp(phoneNumber);

      if (isClosed) return false;
      return result.fold(
        (failure) {
          debugPrint(
              '❌ [AuthCubit] sendLinkPhoneOtp failed: ${failure.message}');
          emit(AuthState.error(failure.message));
          return false;
        },
        (_) {
          debugPrint('✅ [AuthCubit] Phone added successfully');
          emit(AuthState.phoneLinkOtpSent(user: currentUser));
          return true;
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [AuthCubit] Unexpected error in sendLinkPhoneOtp: $e');
      debugPrint('   Stack trace: $stackTrace');
      if (!isClosed) {
        emit(AuthState.error('حدث خطأ غير متوقع: $e'));
      }
      return false;
    }
  }

  /// تأكيد OTP وربط الهاتف بالحساب
  Future<void> verifyLinkPhoneOtp(String phoneNumber, String otp) async {
    debugPrint(
        '🔗 [AuthCubit] verifyLinkPhoneOtp called with phone: $phoneNumber, otp: $otp');
    debugPrint('👤 [AuthCubit] Current user: ${state.user?.email ?? "null"}');

    // If no user in state, try to get current user first
    var currentUser = state.user;
    if (currentUser == null) {
      debugPrint('⚠️ [AuthCubit] No user in state, fetching current user...');
      final currentUserResult = await _getCurrentUserUseCase();
      await currentUserResult.fold(
        (failure) {
          debugPrint(
              '❌ [AuthCubit] Failed to get current user: ${failure.message}');
        },
        (user) {
          if (user != null) {
            debugPrint('✅ [AuthCubit] Current user fetched: ${user.email}');
            currentUser = user;
          }
        },
      );
    }

    if (isClosed) return;
    emit(const AuthState.loading());

    // Development bypass: accept 000000 as valid OTP
    if (otp == '000000') {
      debugPrint(
          '🔓 [AuthCubit] Using development bypass with OTP 000000 for phone linking');

      // استدعاء verifyLinkOtp مع 000000 لتفعيل الـ bypass في الـ data source
      debugPrint('📞 [AuthCubit] Calling verifyLinkOtp with bypass OTP');
      final result = await _verifyPhoneOtpUseCase.verifyLinkOtp(
        phoneNumber: phoneNumber,
        otp: otp,
      );

      if (isClosed) return;
      result.fold(
        (failure) {
          debugPrint(
              '❌ [AuthCubit] Phone link verification failed: ${failure.message}');
          emit(AuthState.error(failure.message));
        },
        (user) {
          debugPrint(
              '✅ [AuthCubit] Phone linked successfully (bypass): ${user.email}');
          emit(AuthState.phoneLinked(user));
        },
      );
      return;
    }

    debugPrint('📞 [AuthCubit] Calling Supabase phone link verification');
    final result = await _verifyPhoneOtpUseCase.verifyLinkOtp(
      phoneNumber: phoneNumber,
      otp: otp,
    );

    if (isClosed) return;
    result.fold(
      (failure) {
        debugPrint(
            '❌ [AuthCubit] Phone link verification failed: ${failure.message}');
        emit(AuthState.error(failure.message));
      },
      (user) {
        debugPrint('✅ [AuthCubit] Phone linked successfully: ${user.email}');
        emit(AuthState.phoneLinked(user));
      },
    );
  }

  /// Resend verification email
  Future<bool> resendVerificationEmail(String email) async {
    emit(const AuthState.loading());
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: AppConstants.authRedirectUrl,
      );
      emit(const AuthState.awaitingEmailVerification());
      return true;
    } catch (e) {
      emit(AuthState.error(e.toString()));
      return false;
    }
  }

  /// Clear error
  void clearError() {
    if (state.isError) {
      emit(state.copyWith(
        status: state.user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        errorMessage: null,
      ));
    }
  }
}
