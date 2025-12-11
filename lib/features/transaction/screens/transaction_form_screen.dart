import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../category/blocs/category_bloc.dart';
import '../../category/blocs/category_event.dart';
import '../../category/blocs/category_state.dart';
import '../../category/models/transaction_category.dart';
import '../../dashboard/notifiers/dashboard_refresh_notifier.dart';
import '../models/transaction_response.dart';
import '../models/transaction_type.dart';
import '../models/transaction_request.dart';
import '../repository/transaction_repository.dart';

class TransactionFormScreen extends StatefulWidget {
  final TransactionResponseDto? transaction;
  final TransactionType type;

  const TransactionFormScreen({
    super.key,
    this.transaction,
    this.type = TransactionType.EXPENSE,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late DateTime _selectedDate;
  int? _selectedCategoryId;
  TransactionCategory? _selectedCategory;
  TransactionType _currentType = TransactionType.EXPENSE;

  // focus
  final _noteFocus = FocusNode();
  // для суммы не даём системе поднимать клавиатуру
  final _amountFocus = FocusNode(canRequestFocus: false);

  bool _saving = false; // защита от повторных запросов
  bool _popped = false; // защита от двойного pop

  static const double _keypadHeight = 280;

  @override
  void initState() {
    super.initState();
    _currentType = widget.type;

    _amountController = TextEditingController(
      text: _formatAmountForInput(widget.transaction?.amount),
    );
    _descriptionController = TextEditingController(text: widget.transaction?.comment ?? '');

    _selectedDate = widget.transaction?.date ?? DateTime.now();
    _selectedCategoryId = widget.transaction?.category.id;

    _noteFocus.addListener(() => setState(() {}));
    context.read<CategoryBloc>().add(LoadCategories(_currentType));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  // ───────────────────────── helpers ─────────────────────────

  bool get _systemKeyboardVisible => MediaQuery.of(context).viewInsets.bottom > 0;
  bool get _showCustomKeypad => !_systemKeyboardVisible && !_noteFocus.hasFocus;

  String _formatAmountForInput(double? amount) {
    if (amount == null) return '';
    final s = amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
    return s.replaceAll(',', '.');
  }

  String _displayAmount(String raw) {
    if (raw.isEmpty) return '0';
    final parts = raw.split('.');
    final intPart = int.tryParse(parts[0]) ?? 0;
    final formattedInt = NumberFormat('#,###', 'ru').format(intPart);
    if (parts.length == 1) return formattedInt;
    final frac = parts[1];
    return '$formattedInt.$frac';
  }

  void _appendKey(String key) {
    var t = _amountController.text;
    if (key == 'C') {
      if (t.isNotEmpty) _amountController.text = t.substring(0, t.length - 1);
      return;
    }
    if (key == '.') {
      if (t.isEmpty) {
        _amountController.text = '0.';
        return;
      }
      if (t.contains('.')) return;
      _amountController.text = '$t.';
      return;
    }
    if (RegExp(r'^\d$').hasMatch(key)) {
      if (t.contains('.')) {
        final after = t.split('.').elementAtOrNull(1) ?? '';
        if (after.length >= 2) return;
      }
      _amountController.text = t + key;
    }
  }

  double? _parseAmount(String raw) {
    if (raw.isEmpty) return null;
    final n = double.tryParse(raw.replaceAll(',', '.'));
    if (n == null) return null;
    if (n > 999999999) return null;
    return n;
  }

  void _loadCategories() {
    context.read<CategoryBloc>().add(LoadCategories(_currentType));
  }

  void _onTypeChanged(TransactionType? newType) {
    if (newType == null) return;
    setState(() {
      _currentType = newType;
      _selectedCategoryId = null;
      _selectedCategory = null;
      _loadCategories();
    });
  }

  Future<void> _submit() async {
    if (_saving || _popped) return;

    final amount = _parseAmount(_amountController.text);
    if (amount == null || _selectedCategory == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректную сумму и выберите категорию')),
      );
      return;
    }

    final req = TransactionRequestDto(
      id: widget.transaction?.id,
      amount: amount,
      date: _selectedDate,
      comment: _descriptionController.text.trim(),
      type: _currentType,
      categoryId: _selectedCategory!.id,
      lang: 'ru',
    );

    final repo = context.read<TransactionRepository>();

    setState(() => _saving = true);
    try {
      final TransactionResponseDto response =
      widget.transaction == null ? await repo.create(req) : await repo.update(req);

      if (!mounted) return;
      dashboardRefreshNotifier.value = !dashboardRefreshNotifier.value;
      _safePop(response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onClosePressed() {
    if (_saving || _popped) return;
    _safePop(null);
  }

  void _safePop(TransactionResponseDto? result) {
    if (_popped) return;
    _popped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop<TransactionResponseDto?>(result);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDate.hour,
        _selectedDate.minute,
      ));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (picked != null) {
      setState(() => _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        picked.hour,
        picked.minute,
      ));
    }
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _onClosePressed,
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Транзакция',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<TransactionType>(
                        value: _currentType,
                        onChanged: _onTypeChanged,
                        items: TransactionType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type == TransactionType.INCOME ? 'Доход' : 'Расход'),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    // нижний паддинг, чтобы контент не прятался за системной клавой
                    _systemKeyboardVisible ? keyboardInset : 16,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Text('₸', style: Theme.of(context).textTheme.headlineSmall),

                      // красивое отображение суммы
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _amountController,
                        builder: (context, value, _) {
                          final display = _displayAmount(value.text);
                          return Text(
                            display,
                            key: ValueKey(display.length > 8),
                            style: TextStyle(
                              fontSize: display.length > 8 ? 36 : 48,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountController,
                        focusNode: _amountFocus,
                        readOnly: true,
                        enableInteractiveSelection: true,
                        decoration: const InputDecoration(
                          hintText: 'Сумма',
                          prefixIcon: Icon(Icons.numbers),
                          filled: true,
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
                        ],
                        onTap: () => FocusScope.of(context).unfocus(),
                      ),

                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        focusNode: _noteFocus,
                        textInputAction: TextInputAction.done,
                        maxLines: 1,
                        decoration: const InputDecoration(
                          hintText: 'Добавить заметку',
                          prefixIcon: Icon(Icons.edit_outlined),
                          filled: true,
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                        ),
                      ),

                      const SizedBox(height: 12),
                      BlocBuilder<CategoryBloc, CategoryState>(
                        builder: (context, state) {
                          if (state is CategoryLoading) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (state is CategoryLoaded) {
                            final categories = state.categories;

                            if (_selectedCategory == null && _selectedCategoryId != null) {
                              _selectedCategory = categories.firstWhereOrNull(
                                    (c) => c.id == _selectedCategoryId,
                              );
                            }

                            final lastUsed = categories.take(4).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: -6,
                                  children: lastUsed.map((cat) {
                                    return ChoiceChip(
                                      label: Text(cat.displayName('ru')),
                                      avatar: Icon(cat.iconData, color: cat.colorValue),
                                      selected: _selectedCategory?.id == cat.id,
                                      onSelected: (_) =>
                                          setState(() => _selectedCategory = cat),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<TransactionCategory>(
                                  value: _selectedCategory,
                                  hint: const Text('Выбрать категорию'),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor:
                                    Theme.of(context).colorScheme.surfaceVariant,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  items: categories.map((cat) {
                                    return DropdownMenuItem(
                                      value: cat,
                                      child: Row(
                                        children: [
                                          Icon(cat.iconData, color: cat.colorValue),
                                          const SizedBox(width: 8),
                                          Text(cat.displayName('ru')),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedCategory = val),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickDate,
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 8),
                            Text(DateFormat('d MMMM y', 'ru').format(_selectedDate)),
                            const Spacer(),
                            InkWell(
                              onTap: _pickTime,
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time),
                                  const SizedBox(width: 8),
                                  Text(DateFormat('HH:mm').format(_selectedDate)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Кейпад + кнопка сохранения переехали в bottomNavigationBar
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  SizeTransition(sizeFactor: anim, axisAlignment: -1.0, child: child),
              child: _showCustomKeypad
                  ? Container(
                key: const ValueKey('custom-keypad'),
                height: _keypadHeight,
                color: Theme.of(context).colorScheme.surfaceVariant,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    for (final row in const [
                      ['7', '8', '9'],
                      ['4', '5', '6'],
                      ['1', '2', '3'],
                      ['.', '0', 'C'],
                    ])
                      Row(
                        children: row.map((key) {
                          return Expanded(
                            child: InkWell(
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                setState(() => _appendKey(key));
                              },
                              child: Container(
                                height: 64,
                                alignment: Alignment.center,
                                child: key == 'C'
                                    ? const Icon(Icons.backspace_outlined)
                                    : Text(
                                  key,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              )
                  : const SizedBox.shrink(key: ValueKey('no-keypad')),
            ),

            // Кнопка сохранения
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  widget.transaction == null ? 'Добавить' : 'Сохранить',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
