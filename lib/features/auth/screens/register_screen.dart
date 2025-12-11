import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fintrack/features/auth/blocs/auth_bloc.dart';
import '../../../widgets/custom_text_field.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isFormValidated = false; // Флаг для активации валидации

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          autovalidateMode: _isFormValidated
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Создайте аккаунт',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Введите свои данные для регистрации',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _usernameController,
                hintText: "Имя пользователя",
                validator: (value) => value == null || value.isEmpty
                    ? 'Введите имя пользователя'
                    : null,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: _emailController,
                hintText: "Email",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Введите email";
                  }
                  // Проверка на корректный формат email
                  final emailRegex = RegExp(
                      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
                  if (!emailRegex.hasMatch(value)) {
                    return "Введите корректный email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: _passwordController,
                hintText: "Пароль",
                obscureText: true,
                validator: (value) => value == null || value.isEmpty
                    ? 'Введите пароль'
                    : null,
              ),
              const SizedBox(height: 20),
              BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthAuthenticated) {
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  } else if (state is AuthFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state is AuthLoading
                        ? null
                        : () {
                      setState(() {
                        _isFormValidated = true; // Включаем валидацию
                      });

                      if (_formKey.currentState!.validate()) {
                        context.read<AuthBloc>().add(
                          RegisterRequested(
                            _usernameController.text,
                            _emailController.text,
                            _passwordController.text,
                          ),
                        );
                      }
                    },
                    child: state is AuthLoading
                        ? const CircularProgressIndicator()
                        : const Text('Зарегистрироваться'),
                  );
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Уже есть аккаунт? Войти'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
