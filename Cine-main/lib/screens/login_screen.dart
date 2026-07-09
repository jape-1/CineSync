import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/cs_logo.dart';
import '../widgets/cs_button.dart';
import '../widgets/input_field.dart';
import '../features/auth/presentation/auth_cubit.dart';
import 'forgot_password_dialog.dart';

/// Pantalla de inicio de sesión. Conectada al backend vía [AuthCubit].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _onLogin() {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa correo y contraseña')),
      );
      return;
    }
    // Al autenticarse, go_router redirige automáticamente según el rol.
    context.read<AuthCubit>().login(email, pass);
  }

  void _onRegister() => context.push('/register');

  void _onForgot() => showForgotPasswordDialog(context);

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (p, c) => c.error != null && c.error != p.error,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.error!)));
        context.read<AuthCubit>().clearError();
      },
      child: Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CSLogo(size: 32),
                  const SizedBox(width: 10),
                  Text.rich(
                    TextSpan(
                      style: AppTextStyles.display.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        letterSpacing: -0.4,
                        color: AppColors.text,
                      ),
                      children: const [
                        TextSpan(text: 'Cine'),
                        TextSpan(text: 'Sync', style: TextStyle(color: AppColors.red)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 64),

              Text('BIENVENIDO DE VUELTA', style: AppTextStyles.eyebrow),

              const SizedBox(height: 12),

              Text(
                'Inicia sesión\nen tu butaca.',
                style: AppTextStyles.h1.copyWith(fontSize: 34, letterSpacing: -0.85),
              ),

              const SizedBox(height: 8),

              Text(
                'Reserva en tiempo real con tu equipo.',
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: AppColors.textDim,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 36),

              InputField(
                icon: const Icon(Icons.mail_outline),
                placeholder: 'correo@cinesync.app',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              InputField(
                icon: const Icon(Icons.lock_outline),
                placeholder: 'contraseña',
                controller: _passCtrl,
                obscureText: true,
              ),

              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _onForgot,
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              BlocBuilder<AuthCubit, AuthState>(
                buildWhen: (p, c) => p.submitting != c.submitting,
                builder: (context, state) => CSButton(
                  label: state.submitting ? 'Ingresando…' : 'Iniciar sesión',
                  onPressed: state.submitting ? null : _onLogin,
                  icon: const Icon(Icons.arrow_forward),
                  fullWidth: true,
                ),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(child: Container(height: 1, color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'O CONTINÚA CON',
                      style: AppTextStyles.mono.copyWith(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ),
                  Expanded(child: Container(height: 1, color: AppColors.border)),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: CSButton(
                      label: 'Apple',
                      onPressed: () => debugPrint('login Apple'),
                      variant: CSButtonVariant.secondary,
                      icon: const Icon(Icons.apple),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CSButton(
                      label: 'Google',
                      onPressed: () => debugPrint('login Google'),
                      variant: CSButtonVariant.secondary,
                      icon: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Color(0xFFEA4335),
                              Color(0xFFFBBC05),
                              Color(0xFF34A853),
                              Color(0xFF4285F4),
                              Color(0xFFEA4335),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 38),

              Center(
                child: GestureDetector(
                  onTap: _onRegister,
                  child: Text.rich(
                    TextSpan(
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        color: AppColors.textDim,
                      ),
                      children: const [
                        TextSpan(text: '¿Nuevo aquí? '),
                        TextSpan(
                          text: 'Crear cuenta',
                          style: TextStyle(
                            color: AppColors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}