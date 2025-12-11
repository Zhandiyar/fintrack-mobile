import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fintrack/widgets/custom_text_field.dart';
import 'package:fintrack/widgets/primary_button.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';

class ResetPasswordScreen extends StatefulWidget {
  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final Object? args = ModalRoute.of(context)?.settings.arguments;

    if (args == null || args is! String || args.isEmpty) {
      // 🔍 Можно отправить в логи или аналитическую систему:
      debugPrint('❌ Deep link: токен не передан или невалидный');

      return Scaffold(
        appBar: AppBar(title: Text("Ошибка")),
        body: const Center(
          child: Text('Токен сброса пароля не передан или невалиден'),
        ),
      );
    }

    final String token = args;

    return Scaffold(
      appBar: AppBar(title: const Text("Сброс пароля")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Введите новый пароль.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _passwordController,
                hintText: "Новый пароль",
                obscureText: true,
                validator: (value) => value == null || value.length < 6
                    ? "Пароль должен быть не менее 6 символов"
                    : null,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: _confirmPasswordController,
                hintText: "Повторите пароль",
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Подтвердите пароль";
                  }
                  if (value != _passwordController.text) {
                    return "Пароли не совпадают";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is TokenInvalid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                    Navigator.pop(context); // Возвращаемся, если токен невалиден
                  }

                  if (state is AuthFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else if (state is PasswordResetSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Пароль успешно изменён!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pushReplacementNamed(context, "/login");
                  }
                },
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return PrimaryButton(
                    text: "Сменить пароль",
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        context.read<AuthBloc>().add(
                          ResetPasswordRequested(
                            token,
                            _passwordController.text,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
