import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MemoraScaffold(
      appBar: const MemoraHeader.root(title: 'Memora', streakDays: 7),
      bottomNavigationBar: MemoraBottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (int index) {
          setState(() {
            _navIndex = index;
          });
        },
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const MemoraCard(
                variant: MemoraCardVariant.primary,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    MoraPlacement(state: MoraState.encourage, size: 72, speechBubbleText: 'Welcome to Memora!'),
                    SizedBox(height: MemoraSpacing.space16),
                    Text('Development baseline ready', textAlign: TextAlign.center, style: MemoraTypography.cardTitle),
                    SizedBox(height: MemoraSpacing.space8),
                    Text(
                      'Flutter design system and responsive app shell baseline established.',
                      textAlign: TextAlign.center,
                      style: MemoraTypography.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MemoraSpacing.space24),
              MemoraButton(
                label: 'View Component Catalog',
                icon: const Icon(Icons.widgets_outlined),
                onPressed: () {
                  context.push('/catalog');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
