import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get peopleCollection => _db.collection('people');
  CollectionReference get cashbookCollection => _db.collection('cashbook');
  DocumentReference get shopProfileDoc =>
      _db.collection('userSettings').doc(user?.uid);

  // ============ PEOPLE / CUSTOMERS ============

  Future<void> addPerson(
    String name,
    String phone,
    String uniqueId, {
    DateTime? dueDate,
    String? whatsappPhone,
  }) async {
    await peopleCollection.add({
      'name': name.trim(),
      'phone': phone.trim(),
      'uniqueId': uniqueId,
      'createdBy': user!.email,
      'createdAt': FieldValue.serverTimestamp(),
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate),
      if (whatsappPhone != null && whatsappPhone.isNotEmpty)
        'whatsappPhone': whatsappPhone.trim(),
    });
  }

  Future<void> updatePerson(
    String personId, {
    required String name,
    required String phone,
    String? whatsappPhone,
    DateTime? dueDate,
  }) async {
    final Map<String, dynamic> data = {
      'name': name.trim(),
      'phone': phone.trim(),
      'whatsappPhone': whatsappPhone?.trim() ?? '',
    };
    if (dueDate != null) {
      data['dueDate'] = Timestamp.fromDate(dueDate);
    } else {
      data['dueDate'] = FieldValue.delete();
    }
    await peopleCollection.doc(personId).update(data);
  }

  Future<void> deletePerson(String personId) async {
    final dueItems = await peopleCollection
        .doc(personId)
        .collection('dueItems')
        .get();
    for (var doc in dueItems.docs) {
      await doc.reference.delete();
    }
    final payments = await peopleCollection
        .doc(personId)
        .collection('payments')
        .get();
    for (var doc in payments.docs) {
      await doc.reference.delete();
    }
    await peopleCollection.doc(personId).delete();
  }

  Stream<QuerySnapshot> get peopleStream {
    return peopleCollection
        .where('createdBy', isEqualTo: user!.email)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ============ DUE ITEMS ============

  Future<void> addDueItem(
    String personId,
    String item,
    double price, {
    String? note,
  }) async {
    await peopleCollection.doc(personId).collection('dueItems').add({
      'item': item,
      'price': price,
      if (note != null && note.isNotEmpty) 'note': note,
      'time': Timestamp.now(),
    });
  }

  Future<void> updateDueItem(
    String personId,
    String itemId,
    String item,
    double price,
  ) async {
    await peopleCollection
        .doc(personId)
        .collection('dueItems')
        .doc(itemId)
        .update({'item': item, 'price': price});
  }

  Future<void> deleteDueItem(String personId, String itemId) async {
    await peopleCollection
        .doc(personId)
        .collection('dueItems')
        .doc(itemId)
        .delete();
  }

  Stream<QuerySnapshot> getDueItemsStream(String personId) {
    return peopleCollection
        .doc(personId)
        .collection('dueItems')
        .orderBy('time', descending: false)
        .snapshots();
  }

  // ============ PAYMENTS ============

  Future<void> addPayment(
    String personId,
    double amount,
    String description,
  ) async {
    await peopleCollection.doc(personId).collection('payments').add({
      'amount': amount,
      'description': description.isEmpty ? 'Payment received' : description,
      'time': Timestamp.now(),
    });
  }

  Future<void> deletePayment(String personId, String paymentId) async {
    await peopleCollection
        .doc(personId)
        .collection('payments')
        .doc(paymentId)
        .delete();
  }

  Stream<QuerySnapshot> getPaymentsStream(String personId) {
    return peopleCollection
        .doc(personId)
        .collection('payments')
        .orderBy('time', descending: false)
        .snapshots();
  }

  // ============ TOTALS ============

  Future<double> getTotalDue(String personId) async {
    final dueSnapshot = await peopleCollection
        .doc(personId)
        .collection('dueItems')
        .get();
    double totalDue = 0;
    for (var item in dueSnapshot.docs) {
      totalDue += ((item.data() as Map)['price'] ?? 0).toDouble();
    }
    final paymentSnapshot = await peopleCollection
        .doc(personId)
        .collection('payments')
        .get();
    double totalPayments = 0;
    for (var payment in paymentSnapshot.docs) {
      totalPayments += ((payment.data() as Map)['amount'] ?? 0).toDouble();
    }
    return totalDue - totalPayments;
  }

  Future<Map<String, double>> getAllPeopleWithTotals() async {
    final peopleSnapshot = await peopleCollection
        .where('createdBy', isEqualTo: user!.email)
        .get();
    Map<String, double> totals = {};
    for (var person in peopleSnapshot.docs) {
      final total = await getTotalDue(person.id);
      totals[person.id] = total;
    }
    return totals;
  }

  // ============ CASHBOOK (ROZNAMCHA) ============

  Future<void> addCashEntry({
    required String type, // 'in' or 'out'
    required double amount,
    required String description,
    required String category,
    DateTime? date,
  }) async {
    await cashbookCollection.add({
      'type': type,
      'amount': amount,
      'description': description,
      'category': category,
      'date': Timestamp.fromDate(date ?? DateTime.now()),
      'createdBy': user!.uid,
    });
  }

  Future<void> deleteCashEntry(String entryId) async {
    await cashbookCollection.doc(entryId).delete();
  }

  Stream<QuerySnapshot> get cashbookStream {
    return cashbookCollection
        .where('createdBy', isEqualTo: user!.uid)
        .orderBy('date', descending: true)
        .snapshots();
  }

  // ============ SHOP PROFILE ============

  Future<void> saveShopProfile({
    required String shopName,
    required String ownerName,
    required String phone,
    String address = '',
  }) async {
    await shopProfileDoc.set({
      'shopName': shopName.trim(),
      'ownerName': ownerName.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot> get shopProfileStream => shopProfileDoc.snapshots();

  Future<Map<String, dynamic>> getShopProfile() async {
    final doc = await shopProfileDoc.get();
    if (doc.exists) return doc.data() as Map<String, dynamic>;
    return {
      'shopName': 'My Shop',
      'ownerName': '',
      'phone': '',
      'address': '',
    };
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;
  Future<void> signOut() async => await _auth.signOut();
}
