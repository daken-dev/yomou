import 'package:flutter/material.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';

class SimpleTextPage extends StatelessWidget {
  const SimpleTextPage({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(title: title, body: body);
  }
}
