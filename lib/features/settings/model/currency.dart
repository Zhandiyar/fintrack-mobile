class Currency {
  final String code;
  final String symbol;
  final String name;
  final String country;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.country,
  });

  static const List<Currency> currencies = [
    Currency(code: 'KZT', symbol: '₸', name: 'Казахстанский тенге', country: 'Казахстан'),
    Currency(code: 'USD', symbol: '\$', name: 'Доллар США', country: 'США'),
    Currency(code: 'EUR', symbol: '€', name: 'Евро', country: 'Европейский союз'),
    Currency(code: 'GBP', symbol: '£', name: 'Фунт стерлингов', country: 'Великобритания'),
    Currency(code: 'JPY', symbol: '¥', name: 'Иена', country: 'Япония'),
    Currency(code: 'CNY', symbol: '¥', name: 'Юань', country: 'Китай'),
    Currency(code: 'RUB', symbol: '₽', name: 'Российский рубль', country: 'Россия'),
    Currency(code: 'INR', symbol: '₹', name: 'Индийская рупия', country: 'Индия'),
    Currency(code: 'BRL', symbol: 'R\$', name: 'Бразильский реал', country: 'Бразилия'),
    Currency(code: 'KRW', symbol: '₩', name: 'Южнокорейская вона', country: 'Южная Корея'),
    Currency(code: 'AUD', symbol: 'A\$', name: 'Австралийский доллар', country: 'Австралия'),
    Currency(code: 'CAD', symbol: 'C\$', name: 'Канадский доллар', country: 'Канада'),
    Currency(code: 'CHF', symbol: 'Fr', name: 'Швейцарский франк', country: 'Швейцария'),
    Currency(code: 'SGD', symbol: 'S\$', name: 'Сингапурский доллар', country: 'Сингапур'),
    Currency(code: 'NZD', symbol: 'NZ\$', name: 'Новозеландский доллар', country: 'Новая Зеландия'),
    Currency(code: 'MXN', symbol: 'Mex\$', name: 'Мексиканское песо', country: 'Мексика'),
    Currency(code: 'HKD', symbol: 'HK\$', name: 'Гонконгский доллар', country: 'Гонконг'),
    Currency(code: 'TRY', symbol: '₺', name: 'Турецкая лира', country: 'Турция'),
    Currency(code: 'SAR', symbol: '﷼', name: 'Саудовский риял', country: 'Саудовская Аравия'),
    Currency(code: 'SEK', symbol: 'kr', name: 'Шведская крона', country: 'Швеция'),
    Currency(code: 'NOK', symbol: 'kr', name: 'Норвежская крона', country: 'Норвегия'),
    Currency(code: 'DKK', symbol: 'kr', name: 'Датская крона', country: 'Дания'),
    Currency(code: 'PLN', symbol: 'zł', name: 'Польский злотый', country: 'Польша'),
    Currency(code: 'ILS', symbol: '₪', name: 'Израильский шекель', country: 'Израиль'),
    Currency(code: 'ZAR', symbol: 'R', name: 'Южноафриканский рэнд', country: 'ЮАР'),
    Currency(code: 'HUF', symbol: 'Ft', name: 'Венгерский форинт', country: 'Венгрия'),
    Currency(code: 'CZK', symbol: 'Kč', name: 'Чешская крона', country: 'Чехия'),
    Currency(code: 'CLP', symbol: 'CL\$', name: 'Чилийское песо', country: 'Чили'),
    Currency(code: 'PHP', symbol: '₱', name: 'Филиппинское песо', country: 'Филиппины'),
    Currency(code: 'AED', symbol: 'د.إ', name: 'Дирхам ОАЭ', country: 'ОАЭ'),
    Currency(code: 'COP', symbol: 'CO\$', name: 'Колумбийское песо', country: 'Колумбия'),
    Currency(code: 'TWD', symbol: 'NT\$', name: 'Тайваньский доллар', country: 'Тайвань'),
  ];

  static Currency getCurrencyByCode(String code) {
    return currencies.firstWhere(
      (currency) => currency.code == code,
      orElse: () => currencies.first,
    );
  }

  static Currency get defaultCurrency => currencies.first;
} 