import '../../core/errors.dart';
import '../../core/result.dart';
import '../../data/models/quest_model.dart';
import '../../data/sources/firebase_service.dart';
import '../../data/sources/firestore_paths.dart';

abstract class QuestRepository {
  Future<Result<List<Quest>, AppError>> list(String uid);
  Future<Result<Quest, AppError>> getById(String uid, String questId);
  Future<Result<void, AppError>> save(String uid, Quest quest);
}

class FirebaseQuestRepository implements QuestRepository {
  FirebaseQuestRepository(this._service);
  final FirebaseService _service;

  @override
  Future<Result<List<Quest>, AppError>> list(String uid) async {
    try {
      final docs = await _service.getCollection(path: FirestorePaths.questsCol(uid));
      return Ok(docs.map((e) => Quest.fromJson(e)).toList());
    } catch (e) {
      return Err(NetworkError(e.toString()));
    }
  }

  @override
  Future<Result<Quest, AppError>> getById(String uid, String questId) async {
    try {
      final data = await _service.getDocument(path: FirestorePaths.questDoc(uid, questId));
      if (data == null) return Err(NotFoundError('Quest $questId'));
      return Ok(Quest.fromJson(data));
    } catch (e) {
      return Err(NetworkError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> save(String uid, Quest quest) async {
    try {
      await _service.setData(path: FirestorePaths.questDoc(uid, quest.id), data: quest.toJson());
      return const Ok(null);
    } catch (e) {
      return Err(NetworkError(e.toString()));
    }
  }
}