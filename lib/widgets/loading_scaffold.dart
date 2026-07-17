import 'package:flutter/material.dart';

class LoadingScaffold extends StatelessWidget {
  final String? title;
  const LoadingScaffold({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null ? null : AppBar(title: Text(title!)),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
