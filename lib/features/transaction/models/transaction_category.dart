class TransactionCategoryDto {
  final int id;
  final String name;
  final String icon;
  final String color;

  TransactionCategoryDto({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  factory TransactionCategoryDto.fromJson(Map<String, dynamic> json) =>
      TransactionCategoryDto(
        id: json['id'],
        name: json['name'],
        icon: json['icon'],
        color: json['color'],
      );
}
