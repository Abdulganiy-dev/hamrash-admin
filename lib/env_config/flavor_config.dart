import 'env.dart';


enum Flavor { dev, prod }

class FlavorConfig {
  FlavorConfig({
    required this.flavor,
    required this.values,
  }) : name = flavor == Flavor.dev ? 'Dev' : 'Prod' {
    instance = this;
  }

  static FlavorConfig? instance;

  final Flavor flavor;
  final String name;
  final Env values;

  static bool isDev() => instance?.flavor == Flavor.dev;
  static bool isProd() => instance?.flavor == Flavor.prod;

  Env envConfig() => values;
}

