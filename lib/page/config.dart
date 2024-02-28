import 'package:flutter/material.dart';

import 'package:score_board/core.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({Key? key}) : super(key: key);

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  double _scale = ScaleController.scaleFactor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("설정"),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text("화면 확대"),
            subtitle: const Text("과도하게 확대하면 레이아웃이 깨질 수 있습니다."),
            trailing: DropdownButton<double>(
              value: _scale,
              items: const [
                DropdownMenuItem(value: 1.00, child: Text("100%")),
                DropdownMenuItem(value: 1.25, child: Text("125%")),
                DropdownMenuItem(value: 1.50, child: Text("150%")),
                DropdownMenuItem(value: 1.75, child: Text("175%")),
                DropdownMenuItem(value: 2.00, child: Text("200%")),
                DropdownMenuItem(value: 2.25, child: Text("225%")),
                DropdownMenuItem(value: 2.50, child: Text("250%")),
                DropdownMenuItem(value: 2.75, child: Text("275%")),
                DropdownMenuItem(value: 3.00, child: Text("300%")),
                /*
                DropdownMenuItem(value: 3.25, child: Text("325%")),
                DropdownMenuItem(value: 3.50, child: Text("350%")),
                DropdownMenuItem(value: 3.75, child: Text("375%")),
                DropdownMenuItem(value: 4.00, child: Text("400%")),
                DropdownMenuItem(value: 4.25, child: Text("425%")),
                DropdownMenuItem(value: 4.50, child: Text("450%")),
                DropdownMenuItem(value: 4.75, child: Text("475%")),
                DropdownMenuItem(value: 5.00, child: Text("500%")),
                */
              ],
              onChanged: (val) {
                setState(() {
                  _scale = val!;
                  ScaleController.changeFactor(_scale);
                });
              },
            ),
          )
        ],
      ),
    );
  }
}

class FakeDevicePixelRatio extends StatelessWidget {
  final double fakeDevicePixelRatio;
  final Widget child;

  const FakeDevicePixelRatio({required this.fakeDevicePixelRatio, required this.child});

  @override
  Widget build(BuildContext context) {
    final ratio = fakeDevicePixelRatio ;
    //* WidgetsBinding.instance.window.devicePixelRatio;

    return FractionallySizedBox(
        widthFactor: 1/ratio,
        heightFactor: 1/ratio,
        child: Transform.scale(
            scale: ratio,
            child: child
        )
    );
  }
}

class ScaleController{
  static double scaleFactor = Database.getSettings().scaleFactor;
  static Function setStateOfScalingManager = (){};

  static void changeFactor(double factor) {
    scaleFactor = factor;
    setStateOfScalingManager();

    Database.setScaleFactor(factor);
  }
}

class ScalingManager extends StatefulWidget {
  final Widget child;
  const ScalingManager({required this.child});

  @override
  State<ScalingManager> createState() => _ScalingManagerState();
}

class _ScalingManagerState extends State<ScalingManager> {
  late final Widget _child;

  @override
  void initState() {
    super.initState();
    _child = widget.child;
    ScaleController.setStateOfScalingManager = (){setState((){});};
  }

  @override
  Widget build(BuildContext context) {
    return FakeDevicePixelRatio(fakeDevicePixelRatio: ScaleController.scaleFactor, child: _child);
  }
}