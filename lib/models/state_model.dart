/// App model for `public.states` (Nigeria states lookup).
class StateModel {
  const StateModel({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory StateModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    return StateModel(
      id: id is String ? id : id.toString(),
      name: name as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
