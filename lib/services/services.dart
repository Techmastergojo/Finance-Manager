import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final User? user = FirebaseAuth.instance.currentUser;

  // People collection reference
  final CollectionReference peopleCollection = FirebaseFirestore.instance
      .collection('people');

  // Add a new person
  Future<void> addPerson(String name, String phone, String uniqueId) async {
    await peopleCollection.add({
      'name': name.trim(),
      'phone': phone.trim(),
      'uniqueId': uniqueId,
      'createdBy': user!.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get stream of people for current user
  Stream<QuerySnapshot> get peopleStream {
    return peopleCollection
        .where('createdBy', isEqualTo: user!.email)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Add due item for a person
  Future<void> addDueItem(String personId, String item, double price) async {
    await peopleCollection.doc(personId).collection('dueItems').add({
      'item': item,
      'price': price,
      'time': Timestamp.now(),
    });
  }

  // Add payment (clear due) for a person
  Future<void> addPayment(
    String personId,
    double amount,
    String description,
  ) async {
    await peopleCollection.doc(personId).collection('payments').add({
      'amount': amount,
      'description': description,
      'time': Timestamp.now(),
    });
  }

  // Get due items stream for a person
  Stream<QuerySnapshot> getDueItemsStream(String personId) {
    return peopleCollection
        .doc(personId)
        .collection('dueItems')
        .orderBy('time', descending: true)
        .snapshots();
  }

  // Get payments stream for a person
  Stream<QuerySnapshot> getPaymentsStream(String personId) {
    return peopleCollection
        .doc(personId)
        .collection('payments')
        .orderBy('time', descending: true)
        .snapshots();
  }

  // Calculate total due amount for a person
  Future<double> getTotalDue(String personId) async {
    final dueSnapshot = await peopleCollection
        .doc(personId)
        .collection('dueItems')
        .get();

    double totalDue = 0;
    for (var item in dueSnapshot.docs) {
      totalDue += (item.data()['price'] ?? 0).toDouble();
    }

    final paymentSnapshot = await peopleCollection
        .doc(personId)
        .collection('payments')
        .get();

    double totalPayments = 0;
    for (var payment in paymentSnapshot.docs) {
      totalPayments += (payment.data()['amount'] ?? 0).toDouble();
    }

    return totalDue - totalPayments;
  }

  // Get all people with their total due amounts
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
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
