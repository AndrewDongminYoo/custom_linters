/// {@template route_methods_extension}
/// A way to add extensions to Strings to make it easy to identify the methods
/// involved in routing (go, push, goNamed, pushNamed, etc.).
/// This simplifies the methodName comparison logic in existing code and
/// makes it easy to extend as new route methods are added.
/// {@endtemplate}
extension RouteMethodExtension on String {
  /// {@macro route_methods_extension}
  bool get isRouteMethod {
    return isLocationRouteMethod || isNamedRouteMethod || isRouterHelperMethod;
  }

  /// Whether this method accepts a location string as its first argument.
  bool get isLocationRouteMethod {
    const routeMethods = {
      'go',
      'push',
      'pushReplacement',
      'replace',
    };
    return routeMethods.contains(this);
  }

  /// Whether this method accepts a route name as its first argument.
  bool get isNamedRouteMethod {
    const routeMethods = {
      'goNamed',
      'namedLocation',
      'pushNamed',
      'pushReplacementNamed',
      'replaceNamed',
    };
    return routeMethods.contains(this);
  }

  /// Whether this method is available on the GoRouterHelper extension.
  bool get isRouterHelperMethod {
    const routeMethods = {
      'canPop',
      'pop',
    };
    return routeMethods.contains(this);
  }
}
