import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Banner de mensaje contextual para guiar al paciente.
///
/// Soporta diferentes estilos: [info], [tip], [warning], [success].
class MessageBanner extends StatelessWidget {
  const MessageBanner({
    super.key,
    required this.message,
    this.icon,
    this.style = MessageBannerStyle.info,
  });

  final String message;
  final IconData? icon;
  final MessageBannerStyle style;

  @override
  Widget build(BuildContext context) {
    final config = _styleConfig;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: config.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? config.defaultIcon, color: config.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _BannerConfig get _styleConfig {
    switch (style) {
      case MessageBannerStyle.info:
        return _BannerConfig(
          bg: AppColors.primary.withValues(alpha: 0.08),
          border: AppColors.primary.withValues(alpha: 0.2),
          accent: AppColors.primary,
          defaultIcon: Icons.info_outline_rounded,
        );
      case MessageBannerStyle.tip:
        return _BannerConfig(
          bg: const Color(0xFFF0F4FF),
          border: const Color(0xFFBFD4FF),
          accent: const Color(0xFF3B82F6),
          defaultIcon: Icons.lightbulb_outline_rounded,
        );
      case MessageBannerStyle.warning:
        return _BannerConfig(
          bg: AppColors.warning.withValues(alpha: 0.10),
          border: AppColors.warning.withValues(alpha: 0.35),
          accent: AppColors.warning,
          defaultIcon: Icons.warning_amber_rounded,
        );
      case MessageBannerStyle.success:
        return _BannerConfig(
          bg: AppColors.success.withValues(alpha: 0.08),
          border: AppColors.success.withValues(alpha: 0.25),
          accent: AppColors.success,
          defaultIcon: Icons.check_circle_outline_rounded,
        );
    }
  }
}

enum MessageBannerStyle { info, tip, warning, success }

class _BannerConfig {
  const _BannerConfig({
    required this.bg,
    required this.border,
    required this.accent,
    required this.defaultIcon,
  });
  final Color bg;
  final Color border;
  final Color accent;
  final IconData defaultIcon;
}

/// Lista vertical de banners de tips con espaciado consistente.
class MessageTipsList extends StatelessWidget {
  const MessageTipsList({super.key, required this.tips});

  final List<({String icon, String message})> tips;

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) return const SizedBox.shrink();

    return Column(
      children: tips.map((tip) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MessageBanner(
            message: tip.message,
            icon: _iconFor(tip.icon),
            style: _styleFor(tip.icon),
          ),
        );
      }).toList(),
    );
  }

  static IconData _iconFor(String key) {
    switch (key) {
      case 'route':
        return Icons.route_rounded;
      case 'medical':
        return Icons.medical_information_outlined;
      case 'sequence':
        return Icons.format_list_numbered_rounded;
      case 'sample':
        return Icons.science_outlined;
      case 'fasting':
        return Icons.no_food_outlined;
      case 'punctual':
        return Icons.alarm_rounded;
      case 'density':
        return Icons.swap_vert_rounded;
      default:
        return Icons.lightbulb_outline_rounded;
    }
  }

  static MessageBannerStyle _styleFor(String key) {
    switch (key) {
      case 'punctual':
        return MessageBannerStyle.warning;
      case 'medical':
        return MessageBannerStyle.warning;
      default:
        return MessageBannerStyle.tip;
    }
  }
}
