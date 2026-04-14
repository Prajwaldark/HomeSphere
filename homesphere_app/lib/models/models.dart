class Subscription {
  final String? id;
  final String name;
  final String price;
  final String nextBilling;
  final String category;
  final bool isActive;

  Subscription({
    this.id,
    required this.name,
    required this.price,
    required this.nextBilling,
    required this.category,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'nextBilling': nextBilling,
    'category': category,
    'isActive': isActive,
  };

  factory Subscription.fromMap(Map<String, dynamic> map, String id) {
    return Subscription(
      id: id,
      name: map['name'] ?? '',
      price: map['price'] ?? '',
      nextBilling: map['nextBilling'] ?? '',
      category: map['category'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }
}

class Appliance {
  static const List<String> categoryOptions = [
    'Fan',
    'Refrigerator',
    'TV',
    'Washing Machine',
    'Air Conditioner',
    'Microwave',
    'Water Purifier',
    'Geyser',
    'Vacuum Cleaner',
    'Dishwasher',
    'Air Purifier',
    'Other',
  ];

  static const List<String> statusOptions = [
    'Healthy',
    'Needs Repair',
    'Under Warranty',
  ];

  final String? id;
  final String name;
  final String brand;
  final String category;
  final String model;
  final String status;
  final String warrantyExpiry;
  final String purchaseDate;

  Appliance({
    this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.model,
    required this.status,
    required this.warrantyExpiry,
    required this.purchaseDate,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'brand': brand,
    'category': category,
    'model': model,
    'status': status,
    'warrantyExpiry': warrantyExpiry,
    'purchaseDate': purchaseDate,
  };

  factory Appliance.fromMap(Map<String, dynamic> map, String id) {
    return Appliance(
      id: id,
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      category: map['category'] ?? '',
      model: map['model'] ?? '',
      status: map['status'] ?? '',
      warrantyExpiry: map['warrantyExpiry'] ?? '',
      purchaseDate: map['purchaseDate'] ?? '',
    );
  }
}

class Vehicle {
  final String? id;
  final String name;
  final String regNumber;
  final String mileage;
  final String nextService;
  final String insuranceExpiry;
  final String pucExpiry;

  Vehicle({
    this.id,
    required this.name,
    required this.regNumber,
    required this.mileage,
    required this.nextService,
    required this.insuranceExpiry,
    required this.pucExpiry,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'regNumber': regNumber,
    'mileage': mileage,
    'nextService': nextService,
    'insuranceExpiry': insuranceExpiry,
    'pucExpiry': pucExpiry,
  };

  factory Vehicle.fromMap(Map<String, dynamic> map, String id) {
    return Vehicle(
      id: id,
      name: map['name'] ?? '',
      regNumber: map['regNumber'] ?? '',
      mileage: map['mileage'] ?? '',
      nextService: map['nextService'] ?? '',
      insuranceExpiry: map['insuranceExpiry'] ?? '',
      pucExpiry: map['pucExpiry'] ?? '',
    );
  }
}

class ServiceProvider {
  final String? id;
  final String name;
  final String category;
  final double rating;
  final String phone;
  final String location;

  ServiceProvider({
    this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.phone,
    required this.location,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'rating': rating,
    'phone': phone,
    'location': location,
  };

  factory ServiceProvider.fromMap(Map<String, dynamic> map, String id) {
    return ServiceProvider(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
    );
  }
}
