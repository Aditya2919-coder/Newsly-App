import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/theme/theme_provider.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) =>
          _buildSettings(context, themeProvider),
    );
  }

  Widget _buildSettings(BuildContext context, ThemeProvider themeProvider) {
    final theme = Theme.of(context);
    final isDarkMode = themeProvider.isDarkMode;
    final surfaceColor = isDarkMode ? const Color(0xFF1E232D) : Colors.white;
    final mutedText = isDarkMode
        ? const Color(0xFF9AA5B1)
        : const Color(0xFF6B7280);
    final cardBorder = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE5E7EB);

    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Settings',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? Colors.white
                            : const Color(0xFF111827),
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF2B303B)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        color: isDarkMode
                            ? Colors.white
                            : const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your preferences',
                  style: theme.textTheme.bodyMedium?.copyWith(color: mutedText),
                ),
                const SizedBox(height: 24),
                _SettingsSection(
                  title: 'APPEARANCE',
                  titleColor: mutedText,
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1B1F27)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.dark_mode_rounded,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                        ),
                        title: Text(
                          'Dark Mode',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                        ),
                        trailing: Switch(
                          value: isDarkMode,
                          onChanged: (enabled) =>
                              _setDarkMode(context, themeProvider, enabled),
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xFF3478F6),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SettingsSection(
                  title: 'ACCOUNT',
                  titleColor: mutedText,
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1B1F27)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                        ),
                        title: Text(
                          'Logout',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: isDarkMode
                              ? Colors.white70
                              : const Color(0xFF6B7280),
                        ),
                        onTap: () => _confirmLogout(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _setDarkMode(
    BuildContext context,
    ThemeProvider themeProvider,
    bool enabled,
  ) async {
    try {
      await themeProvider.setDarkMode(enabled);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not update theme: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (shouldLogout != true || !context.mounted) return;

    try {
      await SecureStorageService().clearAuthSession();
      if (!context.mounted) return;
      context.go(AppRoutes.login);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not log out: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.child,
    required this.titleColor,
  });

  final String title;
  final Widget child;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 10),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
