import 'package:flutter/foundation.dart';

final dashboardRefreshNotifier = ValueNotifier<bool>(false);

void triggerDashboardRefresh() {
  dashboardRefreshNotifier.value = !dashboardRefreshNotifier.value;
}
