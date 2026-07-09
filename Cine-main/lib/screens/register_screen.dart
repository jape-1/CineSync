
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/cs_logo.dart';
import '../widgets/icon_btn.dart';
import '../widgets/cs_button.dart';
import '../widgets/input_field.dart';
import '../features/auth/presentation/auth_cubit.dart';

/// Pantalla de registro. Conectada al backend vía [AuthCubit].
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _acceptedTerms = true;

  int get _passStrength => 3;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _onContinue() {
    final nombre = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (nombre.isEmpty || email.isEmpty || pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa nombre, correo y contraseña (6+)')),
      );
      return;
    }
    // Al registrarse + autenticarse, go_router redirige al home del rol.
    context.read<AuthCubit>().register(nombre, email, pass);
  }

  void _onGoLogin() => context.pop();

  void _onBack() => context.pop();

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
                  IconBtn(
                    size: 36,
                    onTap: _onBack,
                    child: const Icon(Icons.arrow_back, size: 20),
                  ),
                  const Spacer(),
                  const CSLogo(size: 26),
                ],
              ),

              const SizedBox(height: 48),

              Text('REGISTRO', style: AppTextStyles.eyebrow),

              const SizedBox(height: 12),

              Text(
                'Crea tu\ncuenta.',
                style: AppTextStyles.h1.copyWith(fontSize: 34, letterSpacing: -0.85),
              ),

              const SizedBox(height: 8),

              Text(
                'Únete a la sincronización. Empieza con tu primer ticket gratis.',
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: AppColors.textDim,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              InputField(
                icon: const Icon(Icons.person_outline),
                placeholder: 'nombre completo',
                controller: _nameCtrl,
              ),
              const SizedBox(height: 12),
              InputField(
                icon: const Icon(Icons.mail_outline),
                placeholder: 'correo',
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

              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: List.generate(4, (i) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 3 ? 4 : 0),
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: i < _passStrength
                                ? AppColors.green
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 6),

              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'contraseña segura · 8+ caracteres',
                  style: AppTextStyles.mono.copyWith(
                    fontSize: 11,
                    color: AppColors.textDim,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              GestureDetector(
                onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: _acceptedTerms ? AppColors.red : Colors.transparent,
                        border: _acceptedTerms
                            ? null
                            : Border.all(color: AppColors.borderStrong, width: 1.5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: _acceptedTerms
                          ? const Icon(Icons.check, size: 13, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: AppTextStyles.body.copyWith(
                            fontSize: 13,
                            color: AppColors.textDim,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(text: 'Acepto los '),
                            TextSpan(
                              text: 'términos',
                              style: TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const TextSpan(text: ' y la '),
                            TextSpan(
                              text: 'política de privacidad',
                              style: TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              BlocBuilder<AuthCubit, AuthState>(
                buildWhen: (p, c) => p.submitting != c.submitting,
                builder: (context, state) => CSButton(
                  label: state.submitting ? 'Creando cuenta…' : 'Continuar',
                  onPressed: (_acceptedTerms && !state.submitting)
                      ? _onContinue
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  fullWidth: true,
                ),
              ),

              const SizedBox(height: 38),

              Center(
                child: GestureDetector(
                  onTap: _onGoLogin,
                  child: Text.rich(
                    TextSpan(
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        color: AppColors.textDim,
                      ),
                      children: const [
                        TextSpan(text: '¿Ya tienes cuenta? '),
                        TextSpan(
                          text: 'Iniciar sesión',
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