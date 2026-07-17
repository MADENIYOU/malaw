import 'package:flutter/material.dart';

/// Fine bande décorative (motif africain répété) affichée sous l'AppBar,
/// reprise de la planche de design pour garder le même style visuel sur
/// tous les écrans principaux de l'app.
class DecorativeHeaderBand extends StatelessWidget {
  const DecorativeHeaderBand({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/illustrations/header_pattern.jpg'),
          repeat: ImageRepeat.repeatX,
          alignment: Alignment.topLeft,
        ),
      ),
    );
  }
}
