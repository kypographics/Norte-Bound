import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_placeholder_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderScreen(
      eyebrow: 'CURATE',
      title: 'Curator studio.',
      description:
          'Manage destination records, verification status, and verified '
          'metadata across all 22 LGUs of Ilocos Norte.',
      icon: CupertinoIcons.briefcase,
      nextLabel:
          'Curator dashboards and destination management tools arrive in the '
          'next administration phase.',
    );
  }
}
