class HallModel {
  final int id;
  final String name;
  final String location;
  final int capacity;
  final double pricePerDay;
  final String description;
  final String imageUrl;
  final int ownerId;

  HallModel({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.pricePerDay,
    required this.description,
    required this.imageUrl,
    required this.ownerId,
  });

  factory HallModel.fromJson(Map<String, dynamic> json) {
    return HallModel(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      capacity: json['capacity'],
      // Handle decimal from MySQL safely
      pricePerDay: double.parse(json['pricePerDay'].toString()),
      description: json['description'] ?? "",
      imageUrl: json['imageUrl'] ?? "https://via.placeholder.com/300",
      ownerId: json['ownerId'],
    );
  }
}