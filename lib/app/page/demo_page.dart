import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

class DemoPage extends StatelessWidget {
  final VoidCallback onToggleTheme;
  const DemoPage({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Demo")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅从翻译文件里读取文案
            Text(
              "common.hello".tr(),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),

            // ✅ 固定英文按钮，不翻译
            FilledButton(
              onPressed: onToggleTheme,
              child: const Text("Switch Theme"),
            ),
            const SizedBox(height: 12),

            // ✅ 切换 en / ph
            FilledButton(
              onPressed: () {
                final current = context.locale.languageCode;
                if (current == "en") {
                  context.setLocale(const Locale("tl"));
                } else {
                  context.setLocale(const Locale("en"));
                }
              },
              child: const Text("Switch Lang"),
            ),
            const SizedBox(height: 12),

            // ✅ 路由跳转到 Login
            FilledButton(
              onPressed: () {
                context.push('/login');
              },
              child: const Text("Go to Login"),
            ),
            const SizedBox(height: 12),

            // ✅ 路由跳转到 ProductDetail，并传参
            FilledButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/product/:id',
                  arguments: {'id': '123'},
                );
              },
              child: const Text("Go to Product Detail"),
            ),
          ],
        ),
      ),
    );
  }
}