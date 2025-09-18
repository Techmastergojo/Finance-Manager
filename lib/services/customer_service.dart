import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerService {
  static final CollectionReference peopleCollection =
      FirebaseFirestore.instance.collection('people');

  // Find customer by unique ID
  static Future<Map<String, dynamic>?> findCustomerByUniqueId(String uniqueId) async {
    try {
      final querySnapshot = await peopleCollection
          .where('uniqueId', isEqualTo: uniqueId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>
        };
      } else {
        return null;
      }
    } catch (e) {
      print('Error finding customer: $e');
      return null;
    }
  }

  // Get due items for a customer
  static Stream<QuerySnapshot> getDueItemsStream(String personId) {
    return peopleCollection
        .doc(personId)
        .collection('dueItems')
        .orderBy('time', descending: true)
        .snapshots();
  }

  // Get payments for a customer
  static Stream<QuerySnapshot> getPaymentsStream(String personId) {
    return peopleCollection
        .doc(personId)
        .collection('payments')
        .orderBy('time', descending: true)
        .snapshots();
  }

  // Calculate total due amount for a customer
  static Future<Map<String, double>> getCustomerTotals(String personId) async {
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
    
    double totalPaid = 0;
    for (var payment in paymentSnapshot.docs) {
      totalPaid += (payment.data()['amount'] ?? 0).toDouble();
    }
    
    return {
      'totalDue': totalDue,
      'totalPaid': totalPaid,
      'netDue': totalDue - totalPaid
    };
  }
}