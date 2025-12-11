// lib/features/transaction/blocs/transaction_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/transaction_response.dart';
import '../repository/transaction_repository.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository repository;

  TransactionBloc(this.repository) : super(TransactionInitial()) {
    on<LoadTransactions>(_onLoad);
    on<AddTransaction>(_onAdd);
    on<UpdateTransaction>(_onUpdate);
    on<DeleteTransaction>(_onDelete);
    on<UpsertTransactionFromServer>(_onUpsertFromServer);
  }

  Future<void> _onLoad(LoadTransactions event, Emitter<TransactionState> emit) async {
    emit(TransactionLoading());
    try {
      final transactions = await repository.getTransactions(
        type: event.type,
        categoryId: event.categoryId,
        periodType: event.periodType,
        year: event.year,
        month: event.month,
        day: event.day,
        dateFrom: event.dateFrom,
        dateTo: event.dateTo,
        page: event.page,
        size: event.size,
        lang: 'ru',
      );
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError('Ошибка загрузки транзакций: $e'));
    }
  }

  Future<void> _onAdd(AddTransaction event, Emitter<TransactionState> emit) async {
    try {
      final created = await repository.create(event.transaction); // ResponseDto
      _emitUpsert(created, emit);
      // emit(TransactionSuccess(created)); // если нужно
    } catch (e) {
      emit(TransactionError('Ошибка добавления транзакции: $e'));
    }
  }

  Future<void> _onUpdate(UpdateTransaction event, Emitter<TransactionState> emit) async {
    try {
      final updated = await repository.update(event.transaction); // ResponseDto
      _emitUpsert(updated, emit);
    } catch (e) {
      emit(TransactionError('Ошибка обновления транзакции: $e'));
    }
  }

  Future<void> _onDelete(DeleteTransaction event, Emitter<TransactionState> emit) async {
    try {
      await repository.delete(event.id);
      final current = _currentList();
      if (current != null) {
        final next = List<TransactionResponseDto>.from(current)
          ..removeWhere((t) => t.id == event.id);
        emit(TransactionLoaded(next));
      } else {
        add(const LoadTransactions());
      }
    } catch (e) {
      emit(TransactionError('Ошибка удаления транзакции: $e'));
    }
  }

  void _onUpsertFromServer(
      UpsertTransactionFromServer event,
      Emitter<TransactionState> emit,
      ) {
    _emitUpsert(event.tx, emit);
  }

  // ───────── helpers ─────────
  List<TransactionResponseDto>? _currentList() =>
      state is TransactionLoaded ? (state as TransactionLoaded).transactions : null;

  void _emitUpsert(TransactionResponseDto tx, Emitter<TransactionState> emit) {
    final current = _currentList();
    if (current == null) {
      emit(TransactionLoaded([tx]));
      return;
    }
    final list = List<TransactionResponseDto>.from(current);
    final idx = list.indexWhere((e) => e.id == tx.id);
    if (idx >= 0) {
      list[idx] = tx;
    } else {
      list.insert(0, tx); // новые — наверх
    }
    emit(TransactionLoaded(list));
  }
}
