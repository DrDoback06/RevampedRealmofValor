import '../../core/errors.dart';
import '../../core/result.dart';
import '../../data/models/character_model.dart';
import '../../data/sources/firebase_service.dart';
import '../../data/sources/firestore_paths.dart';

abstract class CharacterRepository {
  Future<Result<Character, AppError>> load(String uid, String characterId);
  Future<Result<void, AppError>> save(Character character);
}

class FirebaseCharacterRepository implements CharacterRepository {
  FirebaseCharacterRepository(this._service);
  final FirebaseService _service;

  @override
  Future<Result<Character, AppError>> load(String uid, String characterId) async {
    try {
      final data = await _service.getDocument(path: FirestorePaths.characterDoc(uid, characterId));
      if (data == null) return Err(NotFoundError('Character $characterId'));
      return Ok(Character.fromJson(data));
    } catch (e) {
      return Err(NetworkError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> save(Character character) async {
    try {
      await _service.setData(
        path: FirestorePaths.characterDoc(character.uid, character.id),
        data: character.toJson(),
      );
      return const Ok(null);
    } catch (e) {
      return Err(NetworkError(e.toString()));
    }
  }
}
