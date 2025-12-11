  import '../model/entitlement_status.dart';
  import '../repository/iap_repository.dart';

  class GetEntitlement {
    final IapRepository repo;
    GetEntitlement(this.repo);

    Future<EntitlementStatus> call({bool forceRemote = false}) async {
      if (!forceRemote) {
        final c = repo.getCachedEntitlement();
        if (c != EntitlementStatus.none) return c;
      }
      final r = await repo.getMyEntitlement();
      await repo.cacheEntitlement(r);
      return r;
    }
  }
