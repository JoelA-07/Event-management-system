class VendorModel {
  final int id;
  final int vendorId;
  final String name;
  final String category;
  final double price;
  final String description;
  final String imageUrl;

  VendorModel({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.imageUrl,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'],
      vendorId: json['vendorId'],
      name: json['name'],
      category: json['category'],
      price: double.parse(json['price'].toString()),
      description: json['description'] ?? "",
      imageUrl: json['imageUrl'] ?? "https://via.placeholder.com/300",
    );
  }
}