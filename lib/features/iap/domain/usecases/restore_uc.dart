import '../repository/iap_repository.dart';

class Restore {
  final IapRepository repo;
  Restore(this.repo);
  Future<void> call() => repo.restore();
}
