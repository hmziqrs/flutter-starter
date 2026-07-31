import 'package:flutter/widgets.dart';

typedef ProductionPageFactory<TState> =
    Widget Function(
      BuildContext context,
      TState state,
    );
