import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/states/state_view_card.dart';

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    required this.title,
    required this.body,
    this.icon = FLucideIcons.inbox,
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
      keyPrefix: 'empty-state-view',
      icon: icon,
      title: title,
      body: body,
      action: action,
    );
  }
}
