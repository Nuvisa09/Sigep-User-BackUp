import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieSuccessDialog extends StatelessWidget {
  final VoidCallback? onFinished;

  const LottieSuccessDialog({super.key, this.onFinished});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Ayo kita tos dulu!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Lottie.asset(
              'assets/lottie/high_five.json',
              repeat: false,
              onLoaded: (composition) {
                Future.delayed(composition.duration, () {
                  if (onFinished != null) {
                    onFinished!();
                  } else {
                    Navigator.of(context).pop();
                  }
                });
              },
            ),
            const SizedBox(height: 20),
            const Text(
              "Transaksi Berhasil!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
