// File: home_configuration.dart
// Contains home configuration settings for the Digital EcoHome app

class HomeConfiguration {  // Home basic information
  String homeName;
  double homeSize; // in square feet/meters
  int occupants;
  String homeType; // House, Apartment, Condo, etc.

  // Rooms in the house
  List<Room> rooms;
  
  // Energy efficiency features
  bool hasSolarPanels;
  bool usesLedLighting;

  // Energy goals
  double monthlyEnergyGoal; // in kWh
  double monthlyCostGoal; // in currency

  // Utility provider information
  String utilityProvider;
  String accountNumber;
  String utilityPlan;
  String meterNumber;
  // Default constructor with initial values
  HomeConfiguration({
    this.homeName = 'My Home',
    this.homeSize = 2000,
    this.occupants = 4,
    this.homeType = 'House',
    List<Room>? rooms,
    this.monthlyEnergyGoal = 500,
    this.monthlyCostGoal = 100,
    this.utilityProvider = '',
    this.accountNumber = '',
    this.utilityPlan = '',
    this.meterNumber = '',
    this.hasSolarPanels = false,
    this.usesLedLighting = true,
  }) : rooms =
           rooms ??
           [
             Room(id: '1', name: 'Living Room'),
             Room(id: '2', name: 'Kitchen'),
             Room(id: '3', name: 'Master Bedroom'),
             Room(id: '4', name: 'Bathroom'),
           ];

  // Create a copy with modified values
  HomeConfiguration copyWith({
    String? homeName,
    double? homeSize,
    int? occupants,
    String? homeType,
    List<Room>? rooms,
    double? monthlyEnergyGoal,
    double? monthlyCostGoal,
    String? utilityProvider,
    String? accountNumber,
    String? utilityPlan,
    String? meterNumber,
  }) {
    return HomeConfiguration(
      homeName: homeName ?? this.homeName,
      homeSize: homeSize ?? this.homeSize,
      occupants: occupants ?? this.occupants,
      homeType: homeType ?? this.homeType,
      rooms: rooms ?? List.from(this.rooms),
      monthlyEnergyGoal: monthlyEnergyGoal ?? this.monthlyEnergyGoal,
      monthlyCostGoal: monthlyCostGoal ?? this.monthlyCostGoal,
      utilityProvider: utilityProvider ?? this.utilityProvider,
      accountNumber: accountNumber ?? this.accountNumber,
      utilityPlan: utilityPlan ?? this.utilityPlan,
      meterNumber: meterNumber ?? this.meterNumber,
    );
  }

  // Add a new room
  void addRoom(Room room) {
    rooms.add(room);
  }

  // Remove a room by id
  void removeRoom(String id) {
    rooms.removeWhere((room) => room.id == id);
  }

  // Update an existing room
  void updateRoom(Room updatedRoom) {
    final index = rooms.indexWhere((room) => room.id == updatedRoom.id);
    if (index != -1) {
      rooms[index] = updatedRoom;
    }
  }

  // List of available home types
  static List<String> get availableHomeTypes => [
    'House',
    'Apartment',
    'Condo',
    'Townhouse',
    'Mobile Home',
    'Other',
  ];
}

// Room model to represent a room in the home
class Room {
  final String id;
  String name;
  String? icon;
  String? notes;

  Room({required this.id, required this.name, this.icon, this.notes});

  // Create a copy with modified values
  Room copyWith({String? name, String? icon, String? notes}) {
    return Room(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      notes: notes ?? this.notes,
    );
  }
}
