import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/order_components/draggable_scrollable_scaffold.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/utils/helper.dart';

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
        child: Hero(
            tag: 'button_hero_tag',
            child: Button(
              child: const Text("进入应用"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DraggableScrollableScaffold(
                      heroTag: 'button_hero_tag',
                      floatingHeader: Container(
                        height: 200,
                        color: Colors.green,
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
      ),
    );
  }
}
