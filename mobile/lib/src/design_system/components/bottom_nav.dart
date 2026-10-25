import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

enum MemoraDestination { home, learning, progress, profile }

class MemoraBottomNavigationBar extends StatelessWidget {
  const MemoraBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<_NavDestinationItem> _destinations = <_NavDestinationItem>[
    _NavDestinationItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _NavDestinationItem(
      label: 'Learning',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
    ),
    _NavDestinationItem(
      label: 'Progress',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
    ),
    _NavDestinationItem(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MemoraSpacing.space16,
          vertical: MemoraSpacing.space8,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: MemoraColors.surfaceOcean,
            borderRadius: BorderRadius.circular(MemoraRadii.primaryCardValue),
            border: Border.all(color: MemoraColors.borderDefault),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0F0B1A2C),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraSpacing.space8,
            vertical: MemoraSpacing.space8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List<Widget>.generate(_destinations.length, (int index) {
              final _NavDestinationItem item = _destinations[index];
              final bool isSelected = index == currentIndex;

              return Expanded(
                child: _buildNavItem(
                  context: context,
                  item: item,
                  index: index,
                  isSelected: isSelected,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required _NavDestinationItem item,
    required int index,
    required bool isSelected,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${item.label} tab, ${index + 1} of 4',
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: MemoraRadii.control,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: MemoraSpacing.minTouchTarget,
            minWidth: MemoraSpacing.minTouchTarget,
          ),
          decoration: isSelected
              ? BoxDecoration(
                  color: MemoraColors.controlSelected,
                  borderRadius: MemoraRadii.control,
                )
              : null,
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraSpacing.space8,
            vertical: MemoraSpacing.space8,
          ),
          child: ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  color: MemoraColors.brandPrimary,
                  size: 24,
                ),
                const SizedBox(height: MemoraSpacing.space4),
                Text(
                  item.label,
                  style: MemoraTypography.navigation.copyWith(
                    color: MemoraColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDestinationItem {
  const _NavDestinationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
