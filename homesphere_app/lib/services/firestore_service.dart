import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'notification_service.dart';
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
    final docRef = await _subscriptionsRef.add(sub.toMap());
    _scheduleSubscriptionNotification(sub, docRef.id);
  }

  Future<void> updateSubscription(Subscription sub) async {
    if (sub.id == null) return;
    await _subscriptionsRef.doc(sub.id).update(sub.toMap());
    _scheduleSubscriptionNotification(sub, sub.id!);
  }

  Future<void> deleteSubscription(String docId) async {
    await _subscriptionsRef.doc(docId).delete();
    NotificationService().cancel(docId.hashCode);
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
    final docRef = await _appliancesRef.add(appliance.toMap());
    _scheduleApplianceNotification(appliance, docRef.id);
  }

  Future<void> updateAppliance(Appliance appliance) async {
    if (appliance.id == null) return;
    await _appliancesRef.doc(appliance.id).update(appliance.toMap());
    _scheduleApplianceNotification(appliance, appliance.id!);
  }

  Future<void> deleteAppliance(String docId) async {
    await _appliancesRef.doc(docId).delete();
    NotificationService().cancel(docId.hashCode);
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
    final docRef = await _vehiclesRef.add(vehicle.toMap());
    _scheduleVehicleNotification(vehicle, docRef.id);
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    if (vehicle.id == null) return;
    await _vehiclesRef.doc(vehicle.id).update(vehicle.toMap());
    _scheduleVehicleNotification(vehicle, vehicle.id!);
  }

  Future<void> deleteVehicle(String docId) async {
    await _vehiclesRef.doc(docId).delete();
    NotificationService().cancel(docId.hashCode);
    NotificationService().cancel('${docId}_puc'.hashCode);
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

  // ══════════════════════════════════════════════════════════════════════
  // NOTIFICATION HELPERS
  // ══════════════════════════════════════════════════════════════════════

  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      // Common format is 'MMM dd, yyyy' from the UI
      return DateFormat('MMM dd, yyyy').parse(dateStr);
    } catch (_) {
      try {
        return DateFormat('MM/dd/yyyy').parse(dateStr);
      } catch (_) {}
    }
    return null;
  }

  void _scheduleSubscriptionNotification(Subscription sub, String id) {
    if (!sub.isActive) {
      NotificationService().cancel(id.hashCode);
      return;
    }
    final date = _parseDate(sub.nextBilling);
    if (date == null) return;
    
    // Remind 1 day before at 10 AM
    final scheduleTime = DateTime(date.year, date.month, date.day, 10, 0)
        .subtract(const Duration(days: 1));
        
    NotificationService().scheduleNotification(
      id: id.hashCode,
      title: 'Upcoming Subscription Renewal',
      body: '${sub.name} is renewing tomorrow for ${sub.price}.',
      scheduledDate: scheduleTime,
    );
  }

  void _scheduleApplianceNotification(Appliance appliance, String id) {
    final date = _parseDate(appliance.warrantyExpiry);
    if (date == null) return;
    
    // Remind 7 days before
    final scheduleTime = DateTime(date.year, date.month, date.day, 10, 0)
        .subtract(const Duration(days: 7));

    NotificationService().scheduleNotification(
      id: id.hashCode,
      title: 'Warranty Expiring Soon',
      body: 'Your ${appliance.brand} ${appliance.name} warranty expires in 7 days.',
      scheduledDate: scheduleTime,
    );
  }

  void _scheduleVehicleNotification(Vehicle vehicle, String id) {
    // Insurance Reminder
    final insuranceDate = _parseDate(vehicle.insuranceExpiry);
    if (insuranceDate != null) {
      final scheduleTime = DateTime(insuranceDate.year, insuranceDate.month, insuranceDate.day, 10, 0)
          .subtract(const Duration(days: 7));
      NotificationService().scheduleNotification(
        id: id.hashCode,
        title: 'Vehicle Insurance Expiring',
        body: 'Insurance for ${vehicle.name} (${vehicle.regNumber}) expires in 7 days.',
        scheduledDate: scheduleTime,
      );
    }
    
    // PUC Reminder
    final pucDate = _parseDate(vehicle.pucExpiry);
    if (pucDate != null) {
      final scheduleTime = DateTime(pucDate.year, pucDate.month, pucDate.day, 10, 0)
          .subtract(const Duration(days: 5));
      NotificationService().scheduleNotification(
        id: '${id}_puc'.hashCode,
        title: 'Vehicle PUC Expiring',
        body: 'PUC for ${vehicle.name} (${vehicle.regNumber}) expires in 5 days.',
        scheduledDate: scheduleTime,
      );
    }
  }
}

