- [x] カクヨムに対応
- [ ] デスクトップ最適化 + ビルド
  - [ ] マウスの戻るボタン
  - [ ] キーボード操作 (リーダーでA|右矢印で次のページ、D|左矢印で前のページ)
  - [ ] 各種デスクトップのIDがcom.example.yomouではなくio.qzz.daken.yomouになっているかを確認
- [ ] フォント調節

マウスの戻るでネットのサンプル

```dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class BackMouseDetector extends StatelessWidget {
  const BackMouseDetector({super.key, required this.child, this.onBackPressed});
  final void Function()? onBackPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (innerContext) {
        return Listener(
          onPointerDown: (event) {
            if ((event.buttons & kBackMouseButton) != 0) {
              onBackPressed?.call();
            }
          },
          child: child,
        );
      },
    );
  }
}

builder: isDesktop()
    ? (context, child) => BackMouseDetector(
        child: child!,
        onBackPressed: () {
        if (_router.canPop()) {
            _router.pop();
        }
        },
    )
    : null,
```
