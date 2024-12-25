/// {@template route_methods_extension}
/// A way to add extensions to Strings to make it easy to identify the methods
/// involved in routing (go, push, goNamed, pushNamed, etc.).
/// This simplifies the methodName comparison logic in existing code and
/// makes it easy to extend as new route methods are added.
/// {@endtemplate}
extension RouteMethodExtension on String {
  /// {@macro route_methods_extension}
  bool get isRouteMethod {
    const routeMethods = {
      'go',
      'goNamed',
      'push',
      'pushNamed',
      'pushReplacement',
      'pushReplacementNamed',
      'replace',
      'replaceNamed',
    };
    return routeMethods.contains(this);
  }
}
