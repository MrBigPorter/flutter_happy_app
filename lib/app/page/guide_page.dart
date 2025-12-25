import 'package:flutter/material.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/providers/liveness_provider.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class GuidePage extends ConsumerStatefulWidget {
  const GuidePage({super.key});

  @override
  ConsumerState<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends ConsumerState<GuidePage> {

  @override
  Widget build(BuildContext context) {

     final livenessState = ref.watch(livenessNotifierProvider);


    return BaseScaffold(
      body: Center(
        child: livenessState.when(
            data: (_)=> Button(
                onPressed: ()=>ref.read(livenessNotifierProvider.notifier).startDetection(context),
                child: Text("开始活体检测")
            ),
            error: (error, stackTrace) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("活体检测失败: $error"),
                SizedBox(height: 16),
                Button(
                    onPressed: ()=>ref.read(livenessNotifierProvider.notifier).startDetection(context),
                    child: Text("重试")
                ),
              ],
            ),
            loading: ()=> CircularProgressIndicator()
        )
      ),
    );
  }
}
