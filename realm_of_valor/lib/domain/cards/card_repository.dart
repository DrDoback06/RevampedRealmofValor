import '../../core/result.dart';
import '../../core/errors.dart';
import '../../data/models/card_model.dart';
import '../../data/sources/firebase_service.dart';
import '../../data/sources/firestore_paths.dart';

abstract class CardRepository {
  Future<Result<List<GameCard>, AppError>> fetchAllCards();
  Future<Result<GameCard, AppError>> getCardById(String id);
}

class FirebaseCardRepository implements CardRepository {
  FirebaseCardRepository(this._service);
  final FirebaseService _service;

  @override
  Future<Result<List<GameCard>, AppError>> fetchAllCards() async {
    try {
      final docs = await _service.getCollection(path: FirestorePaths.cardsCol());
      final cards = docs.map((j) => GameCard.fromJson(j)).toList();
      return Ok(cards);
    } catch (e) {
      return Err(NetworkError(e.toString()));
    }
  }

  @override
  Future<Result<GameCard, AppError>> getCardById(String id) async {
    try {
      final doc = await _service.getDocument(path: FirestorePaths.cardDoc(id));
      if (doc == null) return Err(NotFoundError('Card $id'));
      return Ok(GameCard.fromJson(doc));
    } catch (e) {
      return Err(NetworkError(e.toString()));
    }
  }
}
