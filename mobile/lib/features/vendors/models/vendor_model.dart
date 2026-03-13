class VendorModel {
  final int id;
  final int vendorId;
  final String name;
  final String category;
  final double price;
  final String description;
  final String imageUrl;
  final List<String> portfolio;

  VendorModel({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.imageUrl,
    this.portfolio = const [],
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    final rawPortfolio = json['menuOrPortfolio'];
    final portfolio = rawPortfolio is List
        ? rawPortfolio.map((e) => e.toString()).toList()
        : <String>[];
    return VendorModel(
      id: json['id'],
      vendorId: json['vendorId'],
      name: json['name'],
      category: json['category'],
      price: double.parse(json['price'].toString()),
      description: json['description'] ?? "",
      imageUrl: json['imageUrl'] ?? "https://via.placeholder.com/300",
      portfolio: portfolio,
    );
  }
}
