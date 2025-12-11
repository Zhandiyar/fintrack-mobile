

import '../../transaction/models/localized_transaction_response.dart';
import '../../transaction/models/transaction_request.dart';
import '../../transaction/models/transaction_response.dart';

extension LocalizedTxMapper on LocalizedTransactionResponseDto {
  TransactionResponseDto toResponse() => TransactionResponseDto(
    id: id,
    amount: amount,
    date: date,
    createdAt: date,
    updatedAt: date,
    comment: comment,
    type: type,
    category: category
  );

  // из "лайт" → DTO-запрос (когда редактируем)
  TransactionRequestDto toRequest() => TransactionRequestDto(
    id: id,
    amount: amount,
    date: date,
    comment: comment,
    type: type,
    categoryId: category.id,
    lang: 'ru',
  );
}
