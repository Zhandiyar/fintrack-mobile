import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository repository;

  DashboardBloc(this.repository) : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
  }

  Future<void> _onLoadDashboard(
      LoadDashboard event,
      Emitter<DashboardState> emit,
      ) async {
    print('LoadDashboard: ${event.year} ${event.month}');
    emit(DashboardLoading());


    try {
      final data = await repository.getDashboard(
        year: event.year,
        month: event.month,
        day: event.day,
      );
      emit(DashboardLoaded(data));
    } catch (e) {
      emit(DashboardError('Ошибка загрузки дашборда: $e'));
    }
  }
}
