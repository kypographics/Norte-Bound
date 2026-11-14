import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_placeholder_screen.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderScreen(
      eyebrow: 'PERSONALIZE',
      title: 'Tell us how you travel.',
      description:
          'Describe your ideal northern journey in your own words. '
          'Preferences become structured constraints for your confirmation.',
      icon: CupertinoIcons.sparkles,
      nextLabel:
          'Natural-language preference extraction and itinerary planning '
          'arrive in the next planning phases.',
    );
  }
}
