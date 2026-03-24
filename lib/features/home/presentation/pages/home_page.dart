import 'package:flutter/widgets.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(title: '保存済み作品', body: SizedBox.shrink());
  }
}
