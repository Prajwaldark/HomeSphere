import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns the current user's UID, or throws if not signed in.
  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not signed in');
    return user.uid;
  }

  /// Reference to the current user's document.
  DocumentReference get _userDoc => _db.collection('users').doc(_uid);

  // ══════════════════════════════════════════════════════════════════════
  // SUBSCRIPTIONS
  // ══════════════════════════════════════════════════════════════════════

  CollectionReference get _subscriptionsRef =>
      _userDoc.collection('subscriptions');

  Stream<List<Subscription>> streamSubscriptions() {
    return _subscriptionsRef.snapshots().map(
      (snap) => snap.docs
          .map(
            (doc) => Subscription.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList(),
    );
  }

  Future<void> addSubscription(Subscription sub) async {
    await _subscriptionsRef.add(sub.toMap());
  }

  Future<void> updateSubscription(Subscription sub) async {
    if (sub.id == null) return;
    await _subscriptionsRef.doc(sub.id).update(sub.toMap());
  }

  Future<void> deleteSubscription(String docId) async {
    await _subscriptionsRef.doc(docId).delete();
  }

  // ══════════════════════════════════════════════════════════════════════
  // APPLIANCES
  // ══════════════════════════════════════════════════════════════════════

  CollectionReference get _appliancesRef => _userDoc.collection('appliances');

  Stream<List<Appliance>> streamAppliances() {
    return _appliancesRef.snapshots().map(
      (snap) => snap.docs
          .map(
            (doc) =>
                Appliance.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList(),
    );
  }

  Future<void> addAppliance(Appliance appliance) async {
    await _appliancesRef.add(appliance.toMap());
  }

  Future<void> updateAppliance(Appliance appliance) async {
    if (appliance.id == null) return;
    await _appliancesRef.doc(appliance.id).update(appliance.toMap());
  }

  Future<void> deleteAppliance(String docId) async {
    await _appliancesRef.doc(docId).delete();
  }

  // ══════════════════════════════════════════════════════════════════════
  // VEHICLES
  // ══════════════════════════════════════════════════════════════════════

  CollectionReference get _vehiclesRef => _userDoc.collection('vehicles');

  Stream<List<Vehicle>> streamVehicles() {
    return _vehiclesRef.snapshots().map(
      (snap) => snap.docs
          .map(
            (doc) =>
                Vehicle.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList(),
    );
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    await _vehiclesRef.add(vehicle.toMap());
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    if (vehicle.id == null) return;
    await _vehiclesRef.doc(vehicle.id).update(vehicle.toMap());
  }

  Future<void> deleteVehicle(String docId) async {
    await _vehiclesRef.doc(docId).delete();
  }

  // ══════════════════════════════════════════════════════════════════════
  // SERVICE PROVIDERS
  // ══════════════════════════════════════════════════════════════════════

  CollectionReference get _providersRef =>
      _userDoc.collection('serviceProviders');

  Stream<List<ServiceProvider>> streamServiceProviders() {
    return _providersRef.snapshots().map(
      (snap) => snap.docs
          .map(
            (doc) => ServiceProvider.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList(),
    );
  }

  Future<void> addServiceProvider(ServiceProvider provider) async {
    await _providersRef.add(provider.toMap());
  }

  Future<void> updateServiceProvider(ServiceProvider provider) async {
    if (provider.id == null) return;
    await _providersRef.doc(provider.id).update(provider.toMap());
  }

  Future<void> deleteServiceProvider(String docId) async {
    await _providersRef.doc(docId).delete();
  }
}
