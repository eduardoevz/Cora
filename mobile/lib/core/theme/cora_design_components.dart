import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile/core/theme/cora_theme.dart';

/// Editorial surface container with subtle warm border and diffused shadow.
class CoraSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const CoraSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 22,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    final bg = backgroundColor ?? tokens.surface;
    final border = borderColor ?? tokens.borderSubtle;
    final borderWidth = tokens.isHighLegibility ? 2.0 : 1.0;

    final container = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: borderWidth),
        boxShadow: tokens.isHighLegibility
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A241A1E),
                  blurRadius: 18,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap == null) return container;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: container,
      ),
    );
  }
}

/// Semantic pill displaying a biological phase or clinical status with icon + label.
class CoraPhasePill extends StatelessWidget {
  final String phaseKey;
  final String label;
  final IconData? icon;

  const CoraPhasePill({
    super.key,
    required this.phaseKey,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    final pair = tokens.phaseColors(phaseKey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: pair.border,
          width: tokens.isHighLegibility ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: pair.foreground),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: pair.foreground,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clean section header with optional right-aligned link (e.g. "Calendario ->").
class CoraSectionLabel extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const CoraSectionLabel({
    super.key,
    required this.title,
    this.eyebrow,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (eyebrow != null)
              Text(
                eyebrow!.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (actionLabel != null && onActionTap != null)
          InkWell(
            onTap: onActionTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: textTheme.labelLarge?.copyWith(
                      color: tokens.accentPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: tokens.accentPrimary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Primary tactile CTA button calibrated to Cora v2 terracotta-rose accent.
class CoraPrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const CoraPrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    final minHeight = tokens.isHighLegibility ? 56.0 : 50.0;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: tokens.accentPrimary,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 19),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Prediction / biological insight callout inspired by Stitch's Home & Calendar cards.
class CoraInfoCallout extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badgeText;
  final String phaseKey;
  final IconData icon;
  final VoidCallback? onTap;

  const CoraInfoCallout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badgeText,
    this.phaseKey = 'neutral',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    final pair = phaseKey == 'neutral'
        ? CoraPhaseColorPair(
            foreground: tokens.textPrimary,
            background: tokens.surface,
            border: tokens.borderSubtle,
          )
        : tokens.phaseColors(phaseKey);

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pair.border,
          width: tokens.isHighLegibility ? 1.8 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: phaseKey == 'neutral'
                  ? tokens.accentSurface
                  : pair.foreground.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: phaseKey == 'neutral'
                  ? tokens.accentPrimary
                  : pair.foreground,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (badgeText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: phaseKey == 'neutral'
                              ? tokens.surfaceSecondary
                              : tokens.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: pair.border,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          badgeText!,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: phaseKey == 'neutral'
                                        ? tokens.accentPrimary
                                        : pair.foreground,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }
}

/// Compact side-by-side clinical metric card (e.g. Temp. Basal, Descanso).
class CoraMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const CoraMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);

    return CoraSurfaceCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: tokens.accentPrimary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Editorial page hero banner for feature hubs and secondary flows.
class CoraPageHeroBanner extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String? badgeLabel;
  final String phaseKey;
  final IconData? icon;
  final Widget? trailing;

  const CoraPageHeroBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.badgeLabel,
    this.phaseKey = 'neutral',
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    final pair = phaseKey == 'neutral'
        ? CoraPhaseColorPair(
            foreground: tokens.accentPrimary,
            background: tokens.accentSurface,
            border: tokens.borderSubtle,
          )
        : tokens.phaseColors(phaseKey);

    return CoraSurfaceCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: pair.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: pair.border),
                      ),
                      child: Icon(icon, size: 18, color: pair.foreground),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      eyebrow.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: tokens.textSecondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                    ),
                  ),
                ],
              ),
              if (badgeLabel != null)
                CoraPhasePill(
                  phaseKey: phaseKey == 'neutral' ? 'follicular' : phaseKey,
                  label: badgeLabel!,
                ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Composed empty state with tinted circular badge, warm guidance, and optional CTA.
class CoraEmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const CoraEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);

    return CoraSurfaceCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tokens.accentSurface,
              shape: BoxShape.circle,
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Icon(icon, size: 24, color: tokens.accentPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            CoraPrimaryActionButton(
              label: actionLabel!,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

/// Clinical alert banner calibrated for preventive FIGO/ACOG/STRAW+10 or urgent red flags.
class CoraAlertBanner extends StatelessWidget {
  final String title;
  final String description;
  final String? recommendation;
  final bool isUrgent;
  final IconData? icon;
  final Widget? trailingAction;

  const CoraAlertBanner({
    super.key,
    required this.title,
    required this.description,
    this.recommendation,
    this.isUrgent = false,
    this.icon,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    final fg = isUrgent ? tokens.alertUrgent : tokens.alertPreventive;
    final bg =
        isUrgent ? tokens.alertUrgentSurface : tokens.alertPreventiveSurface;
    final resolvedIcon = icon ??
        (isUrgent ? Icons.warning_amber_rounded : Icons.info_outline_rounded);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: fg.withValues(alpha: tokens.isHighLegibility ? 1.0 : 0.45),
          width: tokens.isHighLegibility ? 2.0 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(resolvedIcon, color: fg, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (recommendation != null && recommendation!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: Text(
                recommendation!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
          if (trailingAction != null) ...[
            const SizedBox(height: 12),
            trailingAction!,
          ],
        ],
      ),
    );
  }
}

/// Tactile slider container with tabular figure indicator for biomedical scales.
class CoraSegmentedSliderCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;
  final Key? sliderKey;

  const CoraSegmentedSliderCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
    this.sliderKey,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);

    return CoraSurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.accentSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tokens.borderSubtle),
                ),
                child: Text(
                  valueLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: tokens.accentPrimary,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                  ),
            ),
          ],
          Slider(
            key: sliderKey,
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            activeColor: tokens.accentPrimary,
            inactiveColor: tokens.surfaceSecondary,
            label: valueLabel,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Variant styles for Stitch-inspired status pills.
enum CoraStatusPillVariant {
  mint,
  softMint,
  blush,
  plum,
  urgent,
}

/// Editorial status pill matching Stitch's mint, blush, plum, and urgent badges.
class CoraMintStatusPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final CoraStatusPillVariant variant;

  const CoraMintStatusPill({
    super.key,
    required this.label,
    this.icon,
    this.variant = CoraStatusPillVariant.mint,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    final (Color bg, Color fg, Color border) = switch (variant) {
      CoraStatusPillVariant.mint => (
          tokens.verifiedMint,
          tokens.verified,
          tokens.verified
              .withValues(alpha: tokens.isHighLegibility ? 1.0 : 0.2),
        ),
      CoraStatusPillVariant.softMint => (
          tokens.verifiedSurface,
          tokens.verified,
          tokens.verified
              .withValues(alpha: tokens.isHighLegibility ? 1.0 : 0.25),
        ),
      CoraStatusPillVariant.blush => (
          tokens.accentSurface,
          tokens.primaryDeep,
          tokens.primaryDeep
              .withValues(alpha: tokens.isHighLegibility ? 1.0 : 0.22),
        ),
      CoraStatusPillVariant.plum => (
          tokens.lutealSurface,
          tokens.luteal,
          tokens.luteal.withValues(alpha: tokens.isHighLegibility ? 1.0 : 0.22),
        ),
      CoraStatusPillVariant.urgent => (
          tokens.alertUrgentSurface,
          tokens.alertUrgent,
          tokens.alertUrgent
              .withValues(alpha: tokens.isHighLegibility ? 1.0 : 0.3),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: border,
          width: tokens.isHighLegibility ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stitch editorial page header with uppercase eyebrow pill, title, and calm subtitle.
class CoraStitchPageHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final IconData? eyebrowIcon;
  final bool mintEyebrow;
  final Widget? trailing;

  const CoraStitchPageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.eyebrowIcon,
    this.mintEyebrow = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            CoraMintStatusPill(
              label: eyebrow,
              icon: eyebrowIcon,
              variant: mintEyebrow
                  ? CoraStatusPillVariant.softMint
                  : CoraStatusPillVariant.blush,
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
          ),
        ],
      ],
    );
  }
}

/// Soft blush inset box (#FFF0F4) used inside pure white Stitch cards.
class CoraBlushInsetBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;

  const CoraBlushInsetBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? tokens.blushInset,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ??
              tokens.borderSubtle.withValues(
                alpha: tokens.isHighLegibility ? 1.0 : 0.7,
              ),
          width: tokens.isHighLegibility ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}

/// Circular progress ring with tabular centered percentage/value.
class CoraCircularProgressRing extends StatelessWidget {
  final double progress;
  final String centerLabel;
  final String? centerSublabel;
  final double size;
  final double strokeWidth;
  final Color? progressColor;

  const CoraCircularProgressRing({
    super.key,
    required this.progress,
    required this.centerLabel,
    this.centerSublabel,
    this.size = 84,
    this.strokeWidth = 7,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    final activeColor = progressColor ?? tokens.primaryDeep;
    final trackColor = tokens.accentSurface;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CircularRingPainter(
          progress: progress.clamp(0.0, 1.0),
          activeColor: activeColor,
          trackColor: trackColor,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(strokeWidth + 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (centerSublabel != null)
                    Text(
                      centerSublabel!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: tokens.textSecondary,
                            fontSize: 10,
                          ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularRingPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;
  final double strokeWidth;

  const _CircularRingPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}

/// Pure white trust shield card with green left accent bar (e.g. AES-256 / E2EE).
class CoraTrustShieldCard extends StatelessWidget {
  final String title;
  final String body;
  final String? footerTag;
  final IconData icon;

  const CoraTrustShieldCard({
    super.key,
    required this.title,
    required this.body,
    this.footerTag,
    this.icon = Icons.shield_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: tokens.borderSubtle,
          width: tokens.isHighLegibility ? 2.0 : 1.0,
        ),
        boxShadow: tokens.isHighLegibility
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A241A1E),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: tokens.verified,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: tokens.verifiedSurface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 20, color: tokens.verified),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: tokens.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            body,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: tokens.textSecondary,
                                      height: 1.45,
                                    ),
                          ),
                          if (footerTag != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              footerTag!,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: tokens.verified,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selectable editorial card replacing plain RadioListTile/CheckboxListTile.
class CoraSelectableOptionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? badgeLabel;
  final CoraStatusPillVariant badgeVariant;
  final bool selected;
  final VoidCallback onTap;
  final bool isRadio;
  final IconData? leadingIcon;

  const CoraSelectableOptionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.badgeLabel,
    this.badgeVariant = CoraStatusPillVariant.blush,
    required this.selected,
    required this.onTap,
    this.isRadio = true,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    final bg = selected ? tokens.accentSurface : tokens.blushInset;
    final border = selected ? tokens.primaryDeep : tokens.borderSubtle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: border,
              width: selected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  size: 20,
                  color: selected ? tokens.primaryDeep : tokens.textSecondary,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: tokens.textPrimary,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                        ),
                        if (badgeLabel != null)
                          CoraMintStatusPill(
                            label: badgeLabel!,
                            variant: badgeVariant,
                          ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: isRadio ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: isRadio ? null : BorderRadius.circular(6),
                  color: selected ? tokens.primaryDeep : tokens.surface,
                  border: Border.all(
                    color: selected
                        ? tokens.primaryDeep
                        : tokens.textSecondary.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(
                        isRadio ? Icons.circle : Icons.check,
                        size: isRadio ? 10 : 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stitch-styled segmented pill TabBar inside an accentSurface track.
class CoraPillTabBar extends StatelessWidget {
  final TabController controller;
  final List<Tab> tabs;

  const CoraPillTabBar({
    super.key,
    required this.controller,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.accentSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: tokens.isHighLegibility
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x0F241A1E),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        labelColor: tokens.primaryDeep,
        unselectedLabelColor: tokens.textSecondary,
        labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
        tabs: tabs,
      ),
    );
  }
}

/// 100% offline CustomPaint biomedical line trend chart (BBT, IOM weight, SOP, PDF preview).
class CoraBiometricTrendChart extends StatelessWidget {
  final List<double> values;
  final List<double>? secondaryValues;
  final double? referenceLine;
  final Color lineColor;
  final Color? secondaryLineColor;
  final double height;
  final String? startLabel;
  final String? midLabel;
  final String? endLabel;

  const CoraBiometricTrendChart({
    super.key,
    required this.values,
    this.secondaryValues,
    this.referenceLine,
    required this.lineColor,
    this.secondaryLineColor,
    this.height = 104,
    this.startLabel,
    this.midLabel,
    this.endLabel,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _BiometricTrendPainter(
              values: values,
              secondaryValues: secondaryValues,
              referenceLine: referenceLine,
              lineColor: lineColor,
              secondaryLineColor: secondaryLineColor ?? tokens.luteal,
              guideColor: tokens.borderSubtle,
            ),
          ),
        ),
        if (startLabel != null || midLabel != null || endLabel != null) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                startLabel ?? '',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: tokens.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (midLabel != null)
                Text(
                  midLabel!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: tokens.verified,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              Text(
                endLabel ?? '',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: tokens.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BiometricTrendPainter extends CustomPainter {
  final List<double> values;
  final List<double>? secondaryValues;
  final double? referenceLine;
  final Color lineColor;
  final Color secondaryLineColor;
  final Color guideColor;

  const _BiometricTrendPainter({
    required this.values,
    this.secondaryValues,
    this.referenceLine,
    required this.lineColor,
    required this.secondaryLineColor,
    required this.guideColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final all = <double>[
      ...values,
      if (secondaryValues != null) ...secondaryValues!,
      if (referenceLine != null) referenceLine!,
    ];
    final minVal = all.reduce(math.min);
    final maxVal = all.reduce(math.max);
    final span = (maxVal - minVal).abs() < 0.001 ? 1.0 : (maxVal - minVal);

    final guidePaint = Paint()
      ..color = guideColor.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (final frac in [0.15, 0.5, 0.85]) {
      final y = size.height * frac;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }

    double mapY(double v) {
      final norm = (v - minVal) / span;
      return size.height * 0.85 - norm * (size.height * 0.70);
    }

    if (referenceLine != null) {
      final refY = mapY(referenceLine!);
      final refPaint = Paint()
        ..color = guideColor
        ..strokeWidth = 1.2;
      for (double x = 0; x < size.width; x += 8) {
        canvas.drawLine(
          Offset(x, refY),
          Offset(math.min(x + 4, size.width), refY),
          refPaint,
        );
      }
    }

    void drawSeries(List<double> series, Color color, {bool showDots = false}) {
      if (series.length < 2) return;
      final path = Path();
      final points = <Offset>[];
      for (var i = 0; i < series.length; i++) {
        final x = (i / (series.length - 1)) * size.width;
        final y = mapY(series[i]);
        points.add(Offset(x, y));
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          final prev = points[i - 1];
          final cx = (prev.dx + x) / 2;
          path.cubicTo(cx, prev.dy, cx, y, x, y);
        }
      }
      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, strokePaint);
      if (showDots) {
        final dotPaint = Paint()..color = color;
        for (final pt in points) {
          canvas.drawCircle(pt, 3.0, dotPaint);
        }
      }
    }

    if (secondaryValues != null) {
      drawSeries(secondaryValues!, secondaryLineColor);
    }
    drawSeries(values, lineColor, showDots: true);
  }

  @override
  bool shouldRepaint(covariant _BiometricTrendPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.referenceLine != referenceLine;
  }
}
