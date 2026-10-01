import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';

final appLayoutClassProvider = Provider<AppLayoutClass>(
  (ref) => throw StateError('AppLayoutClass must be provided by an AppLayoutScope.'),
);

typedef AppLayoutBuilder =
    Widget Function(
      BuildContext context,
      AppLayoutClass layoutClass,
    );

class AppLayoutScope extends StatefulWidget {
  const AppLayoutScope({required this.builder, super.key});

  final AppLayoutBuilder builder;

  @override
  State<AppLayoutScope> createState() => _AppLayoutScopeState();
}

class _AppLayoutScopeState extends State<AppLayoutScope> {
  AppLayoutBuilder? _cachedBuilder;
  AppLayoutClass? _cachedLayoutClass;
  late Widget _cachedChild;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoints = context.theme.breakpoints;
        final layoutClass = AppLayoutClass.fromWidth(
          constraints.maxWidth,
          compactMax: breakpoints.sm,
          expandedMin: breakpoints.lg,
        );
        final builder = widget.builder;
        if (builder != _cachedBuilder || layoutClass != _cachedLayoutClass) {
          _cachedBuilder = builder;
          _cachedLayoutClass = layoutClass;
          _cachedChild = ProviderScope(
            overrides: [appLayoutClassProvider.overrideWithValue(layoutClass)],
            child: Builder(
              builder: (context) => builder(context, layoutClass),
            ),
          );
        }
        return _cachedChild;
      },
    );
  }
}
