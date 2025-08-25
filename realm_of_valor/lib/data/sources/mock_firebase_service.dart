import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

/// Mock implementation of PersistenceStore for demo mode
class MockFirebaseService implements PersistenceStore {
  final Map<String, Map<String, dynamic>> _mockData = {};

  @override
  Future<void> setData({
    required String path,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    // Simulate async operation
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (merge && _mockData.containsKey(path)) {
      _mockData[path] = {..._mockData[path]!, ...data};
    } else {
      _mockData[path] = Map<String, dynamic>.from(data);
    }
  }

  @override
  Future<Map<String, dynamic>?> getDocument({required String path}) async {
    // Simulate async operation
    await Future.delayed(const Duration(milliseconds: 50));
    return _mockData[path] != null ? Map<String, dynamic>.from(_mockData[path]!) : null;
  }

  Future<void> deleteData({required String path}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _mockData.remove(path);
  }

  Future<void> batchSet(List<({String path, Map<String, dynamic> data, bool merge})> ops) async {
    await Future.delayed(const Duration(milliseconds: 50));
    for (final op in ops) {
      await setData(path: op.path, data: op.data, merge: op.merge);
    }
  }

  Future<List<Map<String, dynamic>>> getCollection({required String path}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    
    // Return all documents that start with the collection path
    final collectionPath = path.endsWith('/') ? path : '$path/';
    final results = <Map<String, dynamic>>[];
    
    for (final entry in _mockData.entries) {
      if (entry.key.startsWith(collectionPath)) {
        results.add(Map<String, dynamic>.from(entry.value));
      }
    }
    
    return results;
  }

  WriteBatch batch() {
    throw UnimplementedError('WriteBatch not implemented in mock');
  }
}
