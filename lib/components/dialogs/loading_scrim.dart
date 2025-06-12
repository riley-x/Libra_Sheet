import 'package:flutter/material.dart';

/// Close with Navigator.of(context).pop();
void showLoadingScrim({required BuildContext context}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(backgroundColor: Colors.transparent, child: _FadeInLoadingWidget());
    },
  );
}

class _FadeInLoadingWidget extends StatefulWidget {
  @override
  _FadeInLoadingWidgetState createState() => _FadeInLoadingWidgetState();
}

class _FadeInLoadingWidgetState extends State<_FadeInLoadingWidget> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Start fade-in animation after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Loading...')],
        ),
      ),
    );
  }
}
