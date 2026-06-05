import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseFirestore get db => _db;

  /// Returns a [DocumentReference] for [collection]/[docId].
  DocumentReference<Map<String, dynamic>> docRef(
    String collection,
    String docId,
  ) =>
      _db.collection(collection).doc(docId);

  /// Reads a single document. Returns null if it does not exist.
  Future<Map<String, dynamic>?> getDoc(
    String collection,
    String docId,
  ) async {
    final snap = await _db.collection(collection).doc(docId).get();
    return snap.exists ? snap.data() : null;
  }

  /// Writes (merge) a document.
  Future<void> setDoc(
    String collection,
    String docId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    await _db
        .collection(collection)
        .doc(docId)
        .set(data, SetOptions(merge: merge));
  }

  /// Updates specific fields in a document.
  Future<void> updateDoc(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection(collection).doc(docId).update(data);
  }

  /// Queries a collection with an optional where clause.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> queryCollection(
    String collection, {
    String? field,
    dynamic isEqualTo,
    dynamic arrayContains,
    String? orderByField,
    bool descending = false,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection(collection);

    if (field != null && isEqualTo != null) {
      query = query.where(field, isEqualTo: isEqualTo);
    }

    if (field != null && arrayContains != null) {
      query = query.where(field, arrayContains: arrayContains);
    }

    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snap = await query.get();
    return snap.docs;
  }

  /// Streams a collection with a where clause.
  Stream<QuerySnapshot<Map<String, dynamic>>> collectionStream(
    String collection, {
    String? field,
    dynamic isEqualTo,
    dynamic arrayContains,
    String? orderByField,
    bool descending = false,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(collection);

    if (field != null && isEqualTo != null) {
      query = query.where(field, isEqualTo: isEqualTo);
    }

    if (field != null && arrayContains != null) {
      query = query.where(field, arrayContains: arrayContains);
    }

    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }

    return query.snapshots();
  }

  /// Adds a document to a subcollection and returns its ID.
  Future<String> addToSubcollection(
    String collection,
    String docId,
    String subcollection,
    Map<String, dynamic> data,
  ) async {
    final ref = await _db
        .collection(collection)
        .doc(docId)
        .collection(subcollection)
        .add(data);
    return ref.id;
  }

  /// Streams a subcollection ordered by a field.
  Stream<QuerySnapshot<Map<String, dynamic>>> subcollectionStream(
    String collection,
    String docId,
    String subcollection, {
    String? orderByField,
    bool descending = false,
  }) {
    Query<Map<String, dynamic>> query =
        _db.collection(collection).doc(docId).collection(subcollection);

    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }

    return query.snapshots();
  }
}
