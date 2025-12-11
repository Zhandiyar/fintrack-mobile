import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../blocs/currency/currency_bloc.dart';
import '../blocs/currency/currency_event.dart';
import '../blocs/currency/currency_state.dart';
import '../blocs/settings_event.dart';
import '../blocs/settings_state.dart';
import '../model/currency_formatter.dart';
import '../blocs/settings_bloc.dart';
import '../model/currency.dart';
import '../blocs/theme/theme_bloc.dart';
import '../blocs/theme/theme_event.dart';
import '../blocs/theme/theme_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dialogFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Добавляем слушатели для обновления формы при изменении текста
    _newPasswordController.addListener(_validatePasswords);
    _confirmPasswordController.addListener(_validatePasswords);
  }

  void _validatePasswords() {
    if (_formKey.currentState != null) {
      _formKey.currentState!.validate();
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_dialogFormKey.currentState!.validate()) return;

    if (_newPasswordController.text == _currentPasswordController.text) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ошибка'),
          content: const Text('Новый пароль не должен совпадать с текущим'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    context.read<SettingsBloc>().add(
      ChangePasswordEvent(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        elevation: 0,
      ),
      body: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsSuccess) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            if (state.message == 'Аккаунт успешно удален') {
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            } else {
              _currentPasswordController.clear();
              _newPasswordController.clear();
              _confirmPasswordController.clear();
            }
          } else if (state is SettingsError) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Ошибка'),
                content: Text(state.message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        },
        child: ListView(
          children: [
            _buildSection(
              context,
              'Внешний вид',
              [
                BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, state) {
                    return ListTile(
                      leading: const Icon(Icons.palette),
                      title: const Text('Тема'),
                      trailing: DropdownButton<ThemeMode>(
                        value: state.themeMode,
                        underline: const SizedBox(),
                        items: ThemeMode.values.map((ThemeMode mode) {
                          return DropdownMenuItem<ThemeMode>(
                            value: mode,
                            child: Text(_getThemeModeText(mode)),
                          );
                        }).toList(),
                        onChanged: (ThemeMode? newMode) {
                          if (newMode != null) {
                            context.read<ThemeBloc>().add(ThemeChanged(newMode));
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            _buildSection(
              context,
              'Валюта',
              [
                BlocBuilder<CurrencyBloc, CurrencyState>(
                  builder: (context, state) {
                    return ListTile(
                      leading: const Icon(Icons.currency_exchange),
                      title: const Text('Валюта'),
                      subtitle: Text(state.currency.name),
                      trailing: DropdownButton<Currency>(
                        value: state.currency,
                        underline: const SizedBox(),
                        items: Currency.currencies.map((Currency currency) {
                          return DropdownMenuItem<Currency>(
                            value: currency,
                            child: Text('${currency.code} - ${currency.symbol}'),
                          );
                        }).toList(),
                        onChanged: (Currency? newCurrency) {
                          if (newCurrency != null) {
                            context.read<CurrencyBloc>().add(CurrencyChanged(newCurrency));
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            _buildSection(
              context,
              'Безопасность',
              [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock),
                        title: const Text('Изменить пароль'),
                        trailing: BlocBuilder<SettingsBloc, SettingsState>(
                          builder: (context, state) {
                            if (state is SettingsLoading) {
                              return const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              );
                            }
                            return const Icon(Icons.arrow_forward_ios);
                          },
                        ),
                        onTap: () => _showChangePasswordDialog(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _buildSection(
              context,
              'Опасная зона',
              [
                ListTile(
                  leading: Icon(
                    Icons.delete_forever,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Удалить аккаунт',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  subtitle: const Text(
                    'Это действие нельзя отменить. Все ваши данные будут удалены.',
                  ),
                  trailing: BlocBuilder<SettingsBloc, SettingsState>(
                    builder: (context, state) {
                      if (state is SettingsLoading) {
                        return const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      return const Icon(Icons.arrow_forward_ios);
                    },
                  ),
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ],
            ),
            _buildSection(
              context,
              'О приложении',
              [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Политика конфиденциальности'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _openPrivacyPolicy(context),
                ),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Версия приложения'),
                  trailing: const Text('1.0.0'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    
    showDialog(
      context: context,
      builder: (context) => BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return AlertDialog(
            title: const Text('Изменить пароль'),
            content: Form(
              key: _dialogFormKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _currentPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Текущий пароль',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите текущий пароль';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Новый пароль',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите новый пароль';
                      }
                      if (value.length < 6) {
                        return 'Пароль должен содержать минимум 6 символов';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Подтвердите новый пароль',
                      border: const OutlineInputBorder(),
                      errorText: _confirmPasswordController.text.isNotEmpty && 
                               _confirmPasswordController.text != _newPasswordController.text
                          ? 'Пароли не совпадают'
                          : null,
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Подтвердите новый пароль';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Пароли не совпадают';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: state is SettingsLoading ? null : () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: state is SettingsLoading ? null : _changePassword,
                child: state is SettingsLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить аккаунт?'),
        content: const Text(
          'Вы уверены, что хотите удалить свой аккаунт? '
          'Это действие нельзя отменить. Все ваши данные будут удалены безвозвратно.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<SettingsBloc>().add(DeleteAccountEvent());
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Системная';
      case ThemeMode.light:
        return 'Светлая';
      case ThemeMode.dark:
        return 'Темная';
    }
  }

  void _openPrivacyPolicy(BuildContext context) async {
    final Uri url = Uri.parse('https://zhandiyar.github.io/fintrack-mobile/privacy-policy.html');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть политику конфиденциальности')),
        );
      }
    }
  }
}
