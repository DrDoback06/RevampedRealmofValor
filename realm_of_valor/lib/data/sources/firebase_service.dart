import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class PersistenceStore {
  Future<void> setData({required String path, required Map<String, dynamic> data, bool merge = true});
  Future<Map<String, dynamic>?> getDocument({required String path});
}

class FirebaseService implements PersistenceStore {
  FirebaseService(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  @override
  Future<void> setData({required String path, required Map<String, dynamic> data, bool merge = true}) async {
    // Check if user is authenticated
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    final ref = _db.doc(path);
    await ref.set(data, SetOptions(merge: merge));
  }

  Future<void> deleteData({required String path}) async {
    final ref = _db.doc(path);
    await ref.delete();
  }

  @override
  Future<Map<String, dynamic>?> getDocument({required String path}) async {
    // Check if user is authenticated
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    final ref = _db.doc(path);
    final snap = await ref.get();
    return snap.data();
  }

  Future<void> batchSet(List<({String path, Map<String, dynamic> data, bool merge})> ops) async {
    final batch = _db.batch();
    for (final op in ops) {
      final ref = _db.doc(op.path);
      batch.set(ref, op.data, SetOptions(merge: op.merge));
    }
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getCollection({required String path}) async {
    final ref = _db.collection(path);
    final snap = await ref.get();
    return snap.docs.map((d) => d.data()).toList();
  }

  WriteBatch batch() => _db.batch();
}
