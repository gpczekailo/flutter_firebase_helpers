part of firebase_helpers;


abstract class DatabaseItem {
  final String id;
  DatabaseItem(this.id);
}


class DatabaseService<T> {
  String _collection;
  final Firestore _db = Firestore.instance;
  final T Function(String, Map<String,dynamic>) fromDS;
  final Map<String,dynamic> Function(T) toMap;
  DatabaseService(String collection, {this.fromDS,this.toMap}):
    _collection=collection;

  Firestore get db => _db;

  set collection(String collection){
    _collection = collection;
  }

  Future<T> getSingle(String id) async {
    var snap = await _db.collection(_collection).document(id).get();
    if(!snap.exists) return null;
    return fromDS(snap.documentID,snap.data);
  }

  Stream<T> streamSingle(String id) {
    return _db
        .collection(_collection)
        .document(id)
        .snapshots()
        .map((snap) => snap.exists ? fromDS(snap.documentID,snap.data) : null);
  }

  Stream<List<T>> streamList() {
    var ref = _db.collection(_collection);
    return ref.snapshots().map((list) =>
        list.documents.map((doc) => fromDS(doc.documentID,doc.data)).toList());
  }

  Future<List<T>> getQueryList({List<OrderBy> orderBy, List<QueryArgs> args, int limit, dynamic startAfter}) async {
    CollectionReference collref = _db.collection(_collection);
    Query ref;
    if(args != null ) {
      for(QueryArgs arg in args) {
        if(ref == null)
          ref = collref.where(arg.key,isEqualTo: arg.value);
        else
          ref = ref.where(arg.key, isEqualTo: arg.value);
      }
    }
    if(orderBy != null) {
      orderBy.forEach((order) {
        if(ref == null)
          ref = collref.orderBy(order.field,descending: order.descending);
        else
          ref = ref.orderBy(order.field,descending: order.descending);
      });
    }
    if(limit != null) {
      if(ref==null)
        ref = collref.limit(limit);
      else
        ref = ref.limit(limit);
    }
    if(startAfter != null && orderBy != null) {
      ref = ref.startAfter([startAfter]);
    }
      QuerySnapshot query;
    if(ref != null)
      query = await ref.getDocuments();
    else
      query = await collref.getDocuments();
      
    return query.documents.map((doc) => fromDS(doc.documentID,doc.data)).toList();
  }

  Stream<List<T>> streamQueryList({List<OrderBy> orderBy,List<QueryArgs> args, int limit, dynamic startAfter}) {
    CollectionReference collref = _db.collection(_collection);
    Query ref;
    if(orderBy != null) {
      orderBy.forEach((order) {
        if(ref == null)
          ref = collref.orderBy(order.field,descending: order.descending);
        else
          ref = ref.orderBy(order.field,descending: order.descending);
      });
    }
    if(args != null) {
      for(QueryArgs arg in args) {
        if(ref == null)
          ref = collref.where(arg.key,isEqualTo: arg.value);
        else
          ref = ref.where(arg.key, isEqualTo: arg.value);
      }
    }
    if(limit != null) {
      if(ref==null)
        ref = collref.limit(limit);
      else
        ref = ref.limit(limit);
    }
    if(startAfter != null && orderBy != null) {
      ref = ref.startAfter([startAfter]);
    }
    if(ref != null )
      return ref.snapshots().map((snap) => snap.documents.map((doc) => fromDS(doc.documentID,doc.data)).toList());
    else
      return collref.snapshots().map((snap) => snap.documents.map((doc) => fromDS(doc.documentID,doc.data)).toList());
  }

  Future<List<T>> getListFromTo(String field, DateTime from, DateTime to,{List<QueryArgs> args = const []}) async {
    var ref = _db.collection(_collection)
      .orderBy(field);
    for(QueryArgs arg in args) {
      ref = ref.where(arg.key, isEqualTo: arg.value);
    }
    QuerySnapshot query = await ref.startAt([from])
      .endAt([to])
      .getDocuments();
    return query.documents.map((doc) => fromDS(doc.documentID,doc.data)).toList();
  }
  
  Stream<List<T>> streamListFromTo(String field, DateTime from, DateTime to,{List<QueryArgs> args = const[]}) {
    var ref = _db.collection(_collection)
      .orderBy(field,descending: true);
    for(QueryArgs arg in args) {
      ref = ref.where(arg.key, isEqualTo: arg.value);
    }
    var query = ref.startAfter([to])
      .endAt([from])
      .snapshots();
    return query.map((snap) => snap.documents.map((doc) => fromDS(doc.documentID,doc.data)).toList());
  }

  Future<dynamic> createItem(T item, {String id}) {
    if(id != null) {
      return _db
        .collection(_collection)
        .document(id)
        .setData(toMap(item));
    }else{
      return _db
          .collection(_collection)
          .add(toMap(item));
    }
  }

  Future<void> updateData(String id, Map<String,dynamic> data) {
    return _db
      .collection(_collection)
      .document(id)
      .updateData(data);
  }

  Future<void> removeItem(String id) {
    return _db
        .collection(_collection)
        .document(id)
        .delete();
  }
}

class QueryArgs {
  final String key;
  final dynamic value;

  QueryArgs(this.key, this.value);
}

class OrderBy {
  final String field;
  final bool descending;

  OrderBy(this.field, {this.descending = false});
  
}