/// Interface for models that can be created from JSON
abstract class FromJson<T> {
  /// Creates an instance of T from a JSON map
  T fromJson(Map<String, dynamic> data);
}

