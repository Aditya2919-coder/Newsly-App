import 'package:flutter/material.dart';

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.bookmarkCount = 0,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final int bookmarkCount;

  static const Color _activeColor = Color(0xFF3478F6);
  static const Color _lightBackground = Colors.white;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final background = isDarkMode
        ? theme.colorScheme.surface
        : _lightBackground;
    final inactiveColor = theme.colorScheme.onSurfaceVariant;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 64,
        child: Material(
          color: background,
          elevation: 10,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDarkMode
                      ? theme.colorScheme.outlineVariant.withValues(alpha: 0.45)
                      : const Color(0xFFE9EDF2),
                ),
              ),
            ),
            child: Row(
              children: [
                _NavigationItem(
                  selected: selectedIndex == 0,
                  label: 'Home',
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  activeColor: _activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () => onDestinationSelected(0),
                ),
                _NavigationItem(
                  selected: selectedIndex == 1,
                  label: 'Bookmarks',
                  icon: Icons.bookmark_border_rounded,
                  selectedIcon: Icons.bookmark_rounded,
                  activeColor: _activeColor,
                  inactiveColor: inactiveColor,
                  badgeCount: bookmarkCount,
                  onTap: () => onDestinationSelected(1),
                ),
                _NavigationItem(
                  selected: selectedIndex == 2,
                  label: 'Settings',
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings_rounded,
                  activeColor: _activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () => onDestinationSelected(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.selected,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
    this.badgeCount = 0,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Semantics(
          button: true,
          selected: selected,
          label: badgeCount > 0 ? '$label, $badgeCount saved' : label,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              constraints: BoxConstraints(
                minWidth: selected ? 92 : 48,
                minHeight: 40,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 15 : 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: selected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NavigationIcon(
                    icon: selected ? selectedIcon : icon,
                    color: selected ? Colors.white : inactiveColor,
                    badgeCount: badgeCount,
                    badgeBorderColor: selected ? activeColor : Colors.white,
                  ),
                  if (selected) ...[
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationIcon extends StatelessWidget {
  const _NavigationIcon({
    required this.icon,
    required this.color,
    required this.badgeCount,
    required this.badgeBorderColor,
  });

  final IconData icon;
  final Color color;
  final int badgeCount;
  final Color badgeBorderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 26,
      height: 26,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: Icon(icon, color: color, size: 21)),
          if (badgeCount > 0)
            Positioned(
              top: -3,
              right: -5,
              child: Container(
                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: badgeBorderColor, width: 1.5),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
