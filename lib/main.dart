import 'package:flutter/material.dart';
import 'package:scroll/presentation/api_pagination2.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ApiPaginationPage2(),
    );
  }
}
