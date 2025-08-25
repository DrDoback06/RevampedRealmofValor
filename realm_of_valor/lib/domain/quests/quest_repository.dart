import '../../core/errors.dart';
import '../../core/result.dart';
import '../../data/models/quest_model.dart';
import '../../data/sources/firebase_service.dart';
import '../../data/sources/firestore_paths.dart';

abstract class QuestRepository {
  Future<Result<List<Quest>, AppError>> list(String uid);
  Future<Result<Quest, AppError>> getById(String uid, String questId);
  Future<Result<void, AppError>> save(String uid, Quest quest);
  
  // New methods for quest management
  Future<List<Quest>> getActiveQuests(String uid);
  Future<List<Quest>> getAvailableQuests(String uid);
  Future<void> addQuest(String uid, Quest quest);
  Future<void> updateQuest(String uid, Quest quest);
  Future<void> completeQuest(String uid, Quest quest);
  Future<void> abandonQuest(String uid, Quest quest);
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

  @override
  Future<List<Quest>> getActiveQuests(String uid) async {
    try {
      final result = await list(uid);
      return result.when(
        ok: (quests) => quests.where((q) => q.status == QuestStatus.inProgress).toList(),
        err: (_) => [],
      );
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Quest>> getAvailableQuests(String uid) async {
    try {
      final result = await list(uid);
      return result.when(
        ok: (quests) => quests.where((q) => q.status == QuestStatus.notStarted).toList(),
        err: (_) => [],
      );
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addQuest(String uid, Quest quest) async {
    try {
      await _service.setData(path: FirestorePaths.questDoc(uid, quest.id), data: quest.toJson());
    } catch (e) {
      // Log error but don't throw - this allows the app to continue working
      print('Failed to add quest to Firebase: $e');
      // In a production app, you might want to store locally as fallback
      // await _localStorage.saveQuest(uid, quest);
    }
  }

  @override
  Future<void> updateQuest(String uid, Quest quest) async {
    try {
      await _service.setData(path: FirestorePaths.questDoc(uid, quest.id), data: quest.toJson());
    } catch (e) {
      // Log error but don't throw
      print('Failed to update quest: $e');
    }
  }

  @override
  Future<void> completeQuest(String uid, Quest quest) async {
    try {
      final completedQuest = Quest(
        id: quest.id,
        title: quest.title,
        type: quest.type,
        category: quest.category,
        status: QuestStatus.completed,
        description: quest.description,
        objectives: quest.objectives,
        rewards: quest.rewards,
        location: quest.location,
        timeLimit: quest.timeLimit,
        prerequisites: quest.prerequisites,
        tags: quest.tags,
        createdAt: quest.createdAt,
        completedAt: DateTime.now(),
      );
      await _service.setData(path: FirestorePaths.questDoc(uid, quest.id), data: completedQuest.toJson());
    } catch (e) {
      // Log error but don't throw
      print('Failed to complete quest: $e');
    }
  }

  @override
  Future<void> abandonQuest(String uid, Quest quest) async {
    try {
      final abandonedQuest = Quest(
        id: quest.id,
        title: quest.title,
        type: quest.type,
        category: quest.category,
        status: QuestStatus.abandoned,
        description: quest.description,
        objectives: quest.objectives,
        rewards: quest.rewards,
        location: quest.location,
        timeLimit: quest.timeLimit,
        prerequisites: quest.prerequisites,
        tags: quest.tags,
        createdAt: quest.createdAt,
        completedAt: DateTime.now(),
      );
      await _service.setData(path: FirestorePaths.questDoc(uid, quest.id), data: abandonedQuest.toJson());
    } catch (e) {
      // Log error but don't throw
      print('Failed to abandon quest: $e');
    }
  }
}
