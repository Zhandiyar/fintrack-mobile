import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fintrack/widgets/custom_text_field.dart';
import 'package:fintrack/widgets/primary_button.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isFormValidated = false; // Флаг для валидации формы

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Восстановление пароля')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          autovalidateMode: _isFormValidated
              ? AutovalidateMode.always
              : AutovalidateMode.disabled, // Включение валидации после первой попытки
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Введите ваш email, и мы отправим инструкции для сброса пароля.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _emailController,
                hintText: "Email",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Введите email";
                  }
                  final emailRegex = RegExp(
                      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
                  if (!emailRegex.hasMatch(value)) {
                    return "Введите корректный email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else if (state is PasswordResetEmailSent) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                        Text("Инструкции по сбросу пароля отправлены на email"),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context); // Вернуть пользователя на экран логина
                  }
                },
                builder: (context, state) {
                  return PrimaryButton(
                    text: "Отправить инструкцию",
                    onPressed: () {
                      setState(() {
                        _isFormValidated = true; // Включаем валидацию
                      });

                      if (_formKey.currentState!.validate()) {
                        context.read<AuthBloc>().add(
                          ForgotPasswordRequested(_emailController.text),
                        );
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Вернуться ко входу"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
