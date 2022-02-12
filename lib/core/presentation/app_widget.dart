import 'package:flutter/material.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Repo Viewer',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Title'),
        ),
        body: const Center(
          child: Text("HI"),
        ),
      ),
    );
  }
}
