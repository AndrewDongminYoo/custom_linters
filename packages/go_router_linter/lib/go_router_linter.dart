/// Analyzer diagnostics for route definitions and navigation calls that use `go_router`.
///
/// The package registers five opt-in `INFO` diagnostics through Dart's official analyzer plugin host:
///
/// - `missing_go_route_name_property`
/// - `use_context_directly_for_go_router`
/// - `avoid_hardcoded_routes`
/// - `avoid_navigator_named_routes_with_go_router`
/// - `missing_go_router_error_handler`
///
/// Add the package to the top-level `analysis_options.yaml` for the consuming package or pub workspace:
///
/// ```yaml
/// plugins:
///   go_router_linter:
///     version: ^0.5.0
///     diagnostics:
///       missing_go_route_name_property: true
///       use_context_directly_for_go_router: true
///       avoid_hardcoded_routes: true
///       avoid_navigator_named_routes_with_go_router: true
///       missing_go_router_error_handler: true
/// ```
library;

export 'src/extensions/route_methods_extension.dart';
export 'src/rules/avoid_hardcoded_routes.dart';
export 'src/rules/avoid_navigator_named_routes_with_go_router.dart';
export 'src/rules/missing_go_route_name_property.dart';
export 'src/rules/missing_go_router_error_handler.dart';
export 'src/rules/use_context_directly_for_go_router.dart';
