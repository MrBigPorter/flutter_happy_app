import 'package:flutter/material.dart';
import 'package:flutter_app/ui/modal/draggable/draggable_scrollable_scaffold.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/utils/plugin/liveness_plugin.dart';

import '../../ui/animations/transparent_fade_route.dart';


class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {

  Future<void> start() async{
    await LivenessPlugin.start("test_session_id");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 100,),
            Button(
              onPressed:start,
              child: Text('test', style: TextStyle(
                fontSize: 20,
                color: Colors.black,
              ),),
            )
          ],
        )
      ),
    );
  }
}
