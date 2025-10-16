import 'package:flutter/material.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(title: Text('Me')),
      body: Demo()
    );
  }
}

class CounterController extends ValueNotifier<int>{
  CounterController():super(0);

  void increment() => value++;
}

class Demo extends StatelessWidget {
  const Demo({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CounterController();
    return Container(
      padding: EdgeInsets.all(20),
      child:  ValueListenableBuilder<int>(
          valueListenable: controller,
          builder: (_,count,__){
            return Column(
              children: [
                Text('count: $count'),
                ElevatedButton(
                  onPressed: controller.increment,
                  child: Text('increment')
                )
              ],
            );
          }
      ),
    );
  }
}
