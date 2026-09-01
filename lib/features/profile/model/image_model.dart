class ImageModel {
  final int id;
  final String name;
  final String type;
  final String imageData;

  const ImageModel({
    required this.id,
    required this.name,
    required this.type,
    required this.imageData,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) => ImageModel(
        id: json['id'] as int,
        name: json['name'] as String,
        type: json['type'] as String,
        imageData: json['imageData'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'imageData': imageData,
      };
}
