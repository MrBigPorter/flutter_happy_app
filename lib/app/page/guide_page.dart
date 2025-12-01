import 'package:flutter/material.dart';
import 'package:flutter_app/ui/modal/draggable/draggable_scrollable_scaffold.dart';
import 'package:flutter_app/ui/button/button.dart';

import '../../ui/animations/transparent_fade_route.dart';


class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Container(
              height: 300,
              color: Colors.orange,
              child: Center(
                child: Text(
                  "引导页",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Hero(
              tag: 'button_hero_tag',
              child: Button(
                child: const Text("进入应用"),
                onPressed: () {
                  Navigator.push(
                    context,
                    TransparentFadeRoute(
                      child:DraggableScrollableScaffold(
                        heroTag: 'button_hero_tag',
                        headerBuilder: (
                            BuildContext context,
                            double dragProgress,
                            ScrollController controller,
                            ) {
                          return Container(
                            height: 80,
                            color: Colors.white.withOpacity(0.9),
                            child: Center(
                              child: Text(
                                "欢迎页头部",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                        bottomBar: Container(
                          height: 60,
                          color: Colors.black87,
                          child: Center(
                            child: Text(
                              "底部操作栏",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        bodyBuilder:
                            (
                            BuildContext context,
                            ScrollController controller,
                            ScrollPhysics physics,
                            ) {
                          return SingleChildScrollView(
                            controller: controller,
                            physics: physics,
                            child: Column(
                              children: [
                                Container(
                                  height: 800,
                                  color: Colors.red,
                                  child: Center(
                                    child: Text(
                                      "欢迎使用本应用",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 300,
                                  color: Colors.blueGrey,
                                  child: Center(
                                    child: Text(
                                      "欢迎使用本应用",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismiss: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        )
      ),
    );
  }
}
