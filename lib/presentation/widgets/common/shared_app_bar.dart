import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/cubits/theme_cubit.dart';
import 'shared_back_button.dart';

/// A shared app bar that provides consistent navigation and styling across all screens
class SharedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showThemeToggle;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool centerTitle;
  final Widget? leading;
  final double? titleSpacing;
  final TextStyle? titleTextStyle;

  const SharedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.showThemeToggle = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.centerTitle = false,
    this.leading,
    this.titleSpacing,
    this.titleTextStyle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      automaticallyImplyLeading: false,
      leading: leading ??
          (showBackButton
              ? SharedBackButton(
                  color: foregroundColor ??
                      (isDark ? Colors.white : const Color(0xFF1E293B)),
                  onPressed: onBackPressed,
                )
              : null),
      title: Text(
        title,
        style: titleTextStyle ??
            TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: foregroundColor ??
                  (isDark ? Colors.white : const Color(0xFF1E293B)),
            ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor:
          foregroundColor ?? (isDark ? Colors.white : const Color(0xFF1E293B)),
      elevation: elevation,
      titleSpacing: titleSpacing,
      flexibleSpace: backgroundColor == null
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF0F172A).withOpacity(0.95),
                          const Color(0xFF0F172A).withOpacity(0.8),
                        ]
                      : [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.8),
                        ],
                ),
              ),
            )
          : null,
      actions: [
        // Custom actions
        ...(actions ?? []),

        // Theme toggle button
        if (showThemeToggle)
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              final isDarkMode = themeMode == ThemeMode.dark;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF6B46C1).withOpacity(0.1),
                  border: Border.all(
                    color: const Color(0xFF6B46C1).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    isDarkMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: const Color(0xFF6B46C1),
                  ),
                  tooltip: isDarkMode ? 'الوضع المضيء' : 'الوضع المظلم',
                  onPressed: () {
                    context.read<ThemeCubit>().toggleTheme();
                  },
                ),
              );
            },
          ),

        const SizedBox(width: 8),
      ],
    );
  }
}

/// A simple app bar without theme toggle for specific use cases
class SimpleSharedAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SimpleSharedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return SharedAppBar(
      title: title,
      actions: actions,
      showBackButton: showBackButton,
      showThemeToggle: false,
      onBackPressed: onBackPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }
}
