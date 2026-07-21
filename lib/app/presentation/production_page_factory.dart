import 'package:flutter/widgets.dart';

/// Builds a real production page from immutable, typed presentation state.
///
/// The development gallery adapts public feature pages to this signature. Production features
/// never depend on gallery types or gallery-only environment controls.
typedef ProductionPageFactory<TState> =
    Widget Function(
      BuildContext context,
      TState state,
    );
