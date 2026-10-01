import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/states/state_view_card.dart';

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    required this.title,
    required this.body,
    this.icon = FLucideIcons.circleAlert,
    this.action,
    super.key,
  });

  final String title;

  final String body;

  final IconData icon;

  final StateViewAction? action;

  @override
  Widget build(BuildContext context) {
    return StateViewCard(
      keyPrefix: 'error-state-view',
      icon: icon,
      title: title,
      body: body,
      action: action,
    );
  }
}
