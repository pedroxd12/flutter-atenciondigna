import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../providers/auth_providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombres = TextEditingController();
  final _apellidoPaterno = TextEditingController();
  final _apellidoMaterno = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  static final _passwordStrength = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$',
  );

  // Validacion estricta de correo: usuario@dominio.tld
  static final _emailRegex = RegExp(
    r"^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$",
  );

  // Solo letras (incluye acentos), espacios, apostrofes y guiones.
  static final _nameRegex = RegExp(
    r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ\s'\-]+$",
  );

  // Telefono: 10 digitos (formato MX), permite espacios opcionales.
  static final _phoneRegex = RegExp(r'^\d{10}$');

  String? _validateName(String? v, {required String campo}) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Escribe tu $campo';
    if (value.length < 2) return 'Minimo 2 caracteres';
    if (!_nameRegex.hasMatch(value)) {
      return 'Solo letras, espacios y guiones';
    }
    return null;
  }

  @override
  void dispose() {
    _nombres.dispose();
    _apellidoPaterno.dispose();
    _apellidoMaterno.dispose();
    _email.dispose();
    _telefono.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    debugPrint('[Register] tap Crear cuenta');
    if (!_formKey.currentState!.validate()) {
      debugPrint('[Register] validacion local fallo — no se llama al backend');
      return;
    }
    debugPrint('[Register] validacion OK, enviando POST /auth/register');
    await ref
        .read(authControllerProvider.notifier)
        .register(
          email: _email.text.trim(),
          password: _password.text,
          nombre: _nombres.text.trim(),
          apellidoPaterno: _apellidoPaterno.text.trim().isEmpty
              ? null
              : _apellidoPaterno.text.trim(),
          apellidoMaterno: _apellidoMaterno.text.trim().isEmpty
              ? null
              : _apellidoMaterno.text.trim(),
          telefono: _telefono.text.trim().isEmpty
              ? null
              : _telefono.text.trim(),
        );
    debugPrint('[Register] register() retorno (revisar estado)');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final loading = state.isLoading;

    ref.listen(authControllerProvider, (_, next) {
      next.whenOrNull(
        data: (patient) {
          if (patient != null) context.go('/home');
        },
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_humanError(e)),
              backgroundColor: AppColors.danger,
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogo(height: 76)),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'LA ATENCION DIGNA ES PARA TODOS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Solo necesitamos algunos datos',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Crear cuenta',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _FieldLabel('NOMBRE(S)'),
                    TextFormField(
                      controller: _nombres,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      autofillHints: const [AutofillHints.givenName],
                      decoration: const InputDecoration(hintText: 'Ana'),
                      validator: (v) => _validateName(v, campo: 'nombre'),
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel('APELLIDO PATERNO'),
                    TextFormField(
                      controller: _apellidoPaterno,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      autofillHints: const [AutofillHints.familyName],
                      decoration: const InputDecoration(hintText: 'Garcia'),
                      validator: (v) =>
                          _validateName(v, campo: 'apellido paterno'),
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel('APELLIDO MATERNO (OPCIONAL)'),
                    TextFormField(
                      controller: _apellidoMaterno,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(hintText: 'Lopez'),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return null; // opcional
                        if (value.length < 2) return 'Minimo 2 caracteres';
                        if (!_nameRegex.hasMatch(value)) {
                          return 'Solo letras, espacios y guiones';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel('CORREO ELECTRONICO'),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'tucorreo@ejemplo.com',
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Escribe tu correo';
                        if (!_emailRegex.hasMatch(value)) {
                          return 'Correo invalido (ej. ana@ejemplo.com)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel('TELEFONO (OPCIONAL)'),
                    TextFormField(
                      controller: _telefono,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '5512345678',
                      ),
                      validator: (v) {
                        final value = (v ?? '').replaceAll(RegExp(r'\s+'), '');
                        if (value.isEmpty) return null; // opcional
                        if (!_phoneRegex.hasMatch(value)) {
                          return 'Telefono invalido (10 digitos)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel('CONTRASENA'),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            '8+ caracteres con mayuscula, numero y simbolo',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Escribe una contrasena';
                        }
                        if (!_passwordStrength.hasMatch(v)) {
                          return 'Usa 8+ caracteres, mayuscula, minuscula, numero y simbolo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel('CONFIRMAR CONTRASENA'),
                    TextFormField(
                      controller: _confirmPassword,
                      obscureText: _obscureConfirm,
                      autofillHints: const [AutofillHints.newPassword],
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Repite tu contrasena',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Confirma tu contrasena';
                        }
                        if (v != _password.text) {
                          return 'Las contrasenas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: loading ? null : _submit,
                      child: loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.6,
                              ),
                            )
                          : const Text('Crear cuenta'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Ya tienes cuenta? ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const Text(
                            'Iniciar Sesion',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _humanError(Object e) {
    final s = e.toString();
    if (s.startsWith('Exception: ')) return s.substring(11);
    return s;
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
