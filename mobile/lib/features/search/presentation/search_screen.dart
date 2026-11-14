import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_placeholder_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderScreen(
      eyebrow: 'DISCOVER',
      title: 'Search the north.',
      description:
          'Filter verified places by LGU, category, budget, and access. '
          'Every result stays grounded in curated local records.',
      icon: CupertinoIcons.search,
      nextLabel:
          'Destination search, filters, and result maps arrive in the next '
          'discovery phase.',
    );
  }
}
