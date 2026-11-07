import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/auth_view_model.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      body: Stack(
        children: [
          // Background Campus Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/fpt_campus_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF385552), Color(0xFF637C78)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // Overlay Tint
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.25)),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'CAMPUS / STUDIO',
                            style: AppTypography.labelSmall.copyWith(
                              color: const Color(0xFFD6E9A4),
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Có mặt. Kết nối. Tiến xa.',
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Centered Auth Card
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 380),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space24,
                        vertical: AppDimens.space32,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // FPT Education Logo
                          Image.asset(
                            'assets/images/fpt_logo.png',
                            height: 44,
                            errorBuilder: (_, _, _) => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.school,
                                  color: AppColors.fptOrange,
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'FPT UNIVERSITY',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.fptOrange,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'FPT UNIVERSITY',
                            style: AppTypography.labelSmall.copyWith(
                              color: const Color(0xFFC45425),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Đăng nhập',
                            style: AppTypography.titleLarge.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Để tiếp tục sử dụng ứng dụng điểm danh FPT University',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Google Sign-In Button
                          Semantics(
                            button: true,
                            enabled: !authVm.isLoading,
                            label: 'Đăng nhập bằng Google',
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5383EC),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: authVm.isLoading
                                    ? null
                                    : () async {
                                        final success = await authVm
                                            .signInWithGoogle();
                                        if (!success &&
                                            context.mounted &&
                                            authVm.errorMessage != null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                authVm.errorMessage!,
                                              ),
                                              backgroundColor:
                                                  AppColors.textPrimary,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                child: authVm.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.g_mobiledata_rounded,
                                              color: Color(0xFF5383EC),
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Đăng nhập bằng Google',
                                            style: AppTypography.labelLarge
                                                .copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),

                          if (kDebugMode) ...[
                            const SizedBox(height: 12),
                            const _DebugDevLoginPanel(),
                          ],

                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'FPT UNIVERSITY',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textLight,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Kết nối bằng tài khoản Google của bạn',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugDevLoginPanel extends StatefulWidget {
  const _DebugDevLoginPanel();

  @override
  State<_DebugDevLoginPanel> createState() => _DebugDevLoginPanelState();
}

class _DebugDevLoginPanelState extends State<_DebugDevLoginPanel> {
  final _emailController = TextEditingController();
  String _role = 'TEACHER';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    return Semantics(
      container: true,
      label: 'Đăng nhập thử nghiệm chỉ dành cho debug',
      child: Column(
        children: [
          const Divider(),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !authVm.isLoading,
            decoration: const InputDecoration(
              labelText: 'Email kiểm thử',
              hintText: 'test@example.com',
              prefixIcon: Icon(Icons.bug_report_outlined),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _role,
            decoration: const InputDecoration(labelText: 'Vai trò kiểm thử'),
            items: const [
              DropdownMenuItem(value: 'TEACHER', child: Text('TEACHER')),
              DropdownMenuItem(value: 'STUDENT', child: Text('STUDENT')),
            ],
            onChanged: authVm.isLoading
                ? null
                : (value) => setState(() => _role = value ?? _role),
          ),
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: 'Đăng nhập thử nghiệm với vai trò $_role',
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bug_report_outlined),
                label: const Text('Đăng nhập thử nghiệm'),
                onPressed: authVm.isLoading
                    ? null
                    : () async {
                        final email = _emailController.text.trim();
                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nhập email kiểm thử trước.'),
                            ),
                          );
                          return;
                        }
                        final success = await authVm.signInWithDev(
                          email: email,
                          role: _role,
                        );
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                authVm.errorMessage ??
                                    'Đăng nhập không thành công.',
                              ),
                            ),
                          );
                        }
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
