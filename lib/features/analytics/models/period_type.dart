import 'package:json_annotation/json_annotation.dart';

enum PeriodType {
  @JsonValue("YEAR")
  YEAR,
  @JsonValue("MONTH")
  MONTH,
  @JsonValue("WEEK")
  WEEK,
  @JsonValue("DAY")
  DAY,
}

extension PeriodTypeApi on PeriodType {
  String asApiString() {
    switch (this) {
      case PeriodType.YEAR:
        return "YEAR";
      case PeriodType.MONTH:
        return "MONTH";
      case PeriodType.WEEK:
        return "WEEK";
      case PeriodType.DAY:
        return "DAY";
    }
  }
}
