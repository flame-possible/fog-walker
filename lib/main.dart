import 'package:flutter/material.dart';

void main() => runApp(const FogWalkerApp());

class FogWalkerApp extends StatelessWidget {
  const FogWalkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Fog Walker'))),
    );
  }
}
