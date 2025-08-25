import '../../core/errors.dart';
import '../../core/result.dart';
import '../../data/models/inventory_model.dart';
import '../../data/sources/firebase_service.dart';
import '../../data/sources/firestore_paths.dart';

abstract class InventoryRepository {
  Future<Result<Inventory, AppError>> load(String uid);
  Future<Result<void, AppError>> save(Inventory inventory);
}

class FirebaseInventoryRepository implements InventoryRepository {
  FirebaseInventoryRepository(this._service);
  final FirebaseService _service;

  @override
  Future<Result<Inventory, AppError>> load(String uid) async {
    try {
      final data = await _service.getDocument(path: FirestorePaths.inventoryDoc(uid));
      if (data == null) return Err(NotFoundError('Inventory'));
      return Ok(Inventory.fromJson(data));
    } catch (e) {
      return Err(NetworkError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> save(Inventory inventory) async {
    try {
      await _service.setData(
        path: FirestorePaths.inventoryDoc(inventory.ownerUid),
        data: inventory.toJson(),
      );
      return const Ok(null);
    } catch (e) {
      return Err(NetworkError(e.toString()));
    }
  }
}
