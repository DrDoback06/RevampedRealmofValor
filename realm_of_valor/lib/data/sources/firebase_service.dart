import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  FirebaseService(this._db);

  final FirebaseFirestore _db;

  Future<void> setData({required String path, required Map<String, dynamic> data, bool merge = true}) async {
    final ref = _db.doc(path);
    await ref.set(data, SetOptions(merge: merge));
  }

  Future<void> deleteData({required String path}) async {
    final ref = _db.doc(path);
    await ref.delete();
  }

  Future<Map<String, dynamic>?> getDocument({required String path}) async {
    final ref = _db.doc(path);
    final snap = await ref.get();
    return snap.data();
  }

  Future<List<Map<String, dynamic>>> getCollection({required String path}) async {
    final ref = _db.collection(path);
    final snap = await ref.get();
    return snap.docs.map((d) => d.data()).toList();
  }

  WriteBatch batch() => _db.batch();
}