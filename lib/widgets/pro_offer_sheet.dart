import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/theme/app_motion.dart';
import '../data/models/promo_offer.dart';
import '../data/services/pro_feature_service.dart';
import '../l10n/generated/app_localizations.dart';

/// What the upgrade sheet says about the offer, read from the store.
///
/// Every price here comes from Google Play through RevenueCat -- nothing is
/// typed in -- so the sheet can never promise a different deal from the one the
/// paywall charges.
class ProOfferSummary {
  const ProOfferSummary({
    required this.price,
    this.isAnnual = true,
    this.percentOff,
    this.campaignLabel,
    this.endsAt,
    this.trialDays,
    this.introPrice,
    this.perMonth,
    this.perDay,
    this.yearAtMonthlyRate,
    this.savings,
    this.shareOfMonthly,
  });

  /// The plan's full price, as the store formats it ("SAR 149.99").
  final String price;
  final bool isAnnual;

  /// Saving against paying monthly for a year, or a campaign's discount.
  final int? percentOff;
  final String? campaignLabel;
  final DateTime? endsAt;

  /// A free trial, when the store product carries one.
  final int? trialDays;

  /// A discounted first period ("SAR 85.99"), when there is one.
  final String? introPrice;

  /// What the first year works out to per month and per day.
  final String? perMonth;
  final String? perDay;

  /// Twelve monthly payments ("SAR 359.88"), and what the first year saves
  /// against them ("SAR 273.89").
  final String? yearAtMonthlyRate;
  final String? savings;

  /// The first year's cost as a share of a year paid monthly, 0 to 1: the
  /// length of the offer's bar against the monthly one.
  final double? shareOfMonthly;

  String get firstYearPrice => introPrice ?? price;

  /// Reads the current offering. Null when the store has not answered yet;
  /// the sheet then leaves the price out rather than guess one.
  static ProOfferSummary? fromOffering(
    Offering? offering, {
    PromoOffer? promo,
  }) {
    if (offering == null) return null;
    Package? byType(PackageType type) {
      for (final p in offering.availablePackages) {
        if (p.packageType == type) return p;
      }
      return null;
    }

    final annual = byType(PackageType.annual) ?? offering.annual;
    final monthly = byType(PackageType.monthly) ?? offering.monthly;
    final plan = annual ?? monthly;
    if (plan == null) return null;

    final product = plan.storeProduct;
    final intro = product.introductoryPrice;
    final isAnnual = identical(plan, annual);
    final trialDays = intro != null && intro.price <= 0 ? _daysOf(intro) : null;
    final discountedIntro =
        intro != null && intro.price > 0 && intro.price < product.price;
    final firstYear = discountedIntro ? intro.price : product.price;

    final yearAtMonthly =
        isAnnual && monthly != null && !identical(monthly, annual)
            ? monthly.storeProduct.price * 12
            : null;
    final saved =
        yearAtMonthly != null && yearAtMonthly > firstYear
            ? yearAtMonthly - firstYear
            : null;
    // Rounded, and ignored under 5%, exactly as PromoOffer does for the home
    // screen's pill and the paywall's badge, so no two quote different numbers.
    final derivedPercent =
        saved != null ? (saved / yearAtMonthly! * 100).round() : null;

    // Worked-out amounts are written the way the store writes its own price.
    String money(double amount) => formatLike(product.priceString, amount);

    return ProOfferSummary(
      price: product.priceString,
      isAnnual: isAnnual,
      percentOff:
          promo?.percentOff ??
          (derivedPercent != null && derivedPercent >= 5 ? derivedPercent : null),
      campaignLabel: promo?.label,
      endsAt: promo?.endsAt,
      trialDays: trialDays,
      introPrice: discountedIntro ? intro.priceString : null,
      perMonth: isAnnual ? money(firstYear / 12) : null,
      perDay: isAnnual ? money(firstYear / 365) : null,
      yearAtMonthlyRate: yearAtMonthly != null ? money(yearAtMonthly) : null,
      savings: saved != null ? money(saved) : null,
      shareOfMonthly: saved != null ? firstYear / yearAtMonthly! : null,
    );
  }

  /// Writes [amount] the way the store wrote [sample]: the same symbol in the
  /// same place, the same separators, the same digits. intl would write SAR as
  /// "Riyal273.89", which beside Play's "SAR 85.99" reads like another shop.
  @visibleForTesting
  static String formatLike(String sample, double amount) {
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    final number = RegExp(
      r'[0-9٠-٩](?:[0-9٠-٩.,٫٬\s  ]*[0-9٠-٩])?',
    ).firstMatch(sample);
    if (number == null) return amount.toStringAsFixed(2);
    final text = number.group(0)!;

    // The last separator is the decimal one, unless exactly three digits
    // follow it: then it groups thousands ("¥1,200").
    final tail = RegExp(r'([.,٫])([0-9٠-٩]+)$').firstMatch(text);
    final hasDecimals = tail != null && tail.group(2)!.length != 3;
    final decimalSep = hasDecimals ? tail.group(1)! : '';
    final decimals = hasDecimals ? tail.group(2)!.length : 0;
    final whole = hasDecimals ? text.substring(0, tail.start) : text;
    final groupSep = RegExp(r'[^0-9٠-٩]').firstMatch(whole)?.group(0);

    final parts = amount.toStringAsFixed(decimals).split('.');
    final digits = parts[0];
    final grouped = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (groupSep != null && i > 0 && (digits.length - i) % 3 == 0) {
        grouped.write(groupSep);
      }
      grouped.write(digits[i]);
    }
    var result = decimals > 0 ? '$grouped$decimalSep${parts[1]}' : '$grouped';
    if (RegExp('[٠-٩]').hasMatch(text)) {
      result = result.replaceAllMapped(
        RegExp('[0-9]'),
        (m) => arabicDigits[int.parse(m[0]!)],
      );
    }
    return sample.replaceRange(number.start, number.end, result);
  }

  static int? _daysOf(IntroductoryPrice intro) {
    final units = intro.periodNumberOfUnits;
    if (units <= 0) return null;
    final unit = intro.periodUnit.name.toLowerCase();
    if (unit.startsWith('week')) return units * 7;
    if (unit.startsWith('month')) return units * 30;
    if (unit.startsWith('year')) return units * 365;
    return units;
  }

  String cta(AppLocalizations l10n) {
    if (trialDays != null) return l10n.premium_start_trial;
    if (percentOff != null) return l10n.pro_offer_claim('$percentOff');
    return l10n.pro_offer_get_pro;
  }

  /// The small line under the button: what is charged, and what it renews at.
  String ctaDetail(AppLocalizations l10n) {
    final renew =
        isAnnual ? l10n.pro_offer_per_year(price) : l10n.pro_offer_per_month(price);
    if (trialDays != null) {
      return '${l10n.pro_offer_days_free(trialDays!)} · ${l10n.paywall_then(renew)}';
    }
    if (introPrice != null) return l10n.pro_offer_cta_intro(introPrice!, price);
    return renew;
  }
}

/// The sheet is dark whatever the app theme: it is the one screen meant to
/// feel like a premium product, and gold reads best on deep green.
abstract final class _Palette {
  static const bgTop = Color(0xFF07382C);
  static const bgMid = Color(0xFF04231A);
  static const bgBottom = Color(0xFF02110C);
  static const emerald = Color(0xFF10B981);
  static const emeraldBright = Color(0xFF34D399);
  static const goldLight = Color(0xFFFFE3A3);
  static const gold = Color(0xFFE9B85C);
  static const goldDeep = Color(0xFFC88A32);
  static const amber = Color(0xFFF59E0B);
  static const ink = Color(0xFF1F1405);
  static const muted = Color(0xFFA3B8B0);
  static const glass = Color(0x0FFFFFFF);
  static const glassBorder = Color(0x1FFFFFFF);
  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold, goldDeep],
  );
}

/// The free plan's monthly scans when the caller does not pass the live
/// figure; matches ScanGateService's default.
const int _fallbackScanLimit = 15;

/// The upgrade sheet shown to free users: the live offer, what it saves, and
/// what Pro adds over the free plan.
class ProOfferSheet extends StatelessWidget {
  const ProOfferSheet({
    super.key,
    this.offer,
    this.scansUsed,
    this.scanLimit,
    required this.onUpgrade,
    required this.onDismiss,
    this.now,
  });

  final ProOfferSummary? offer;
  final int? scansUsed;
  final int? scanLimit;
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;

  /// For tests; the offer's end date is judged against the real clock otherwise.
  final DateTime? now;

  /// Shows the sheet. [onUpgrade] runs after it closes, so the paywall opens on
  /// top of the app rather than under the sheet.
  static Future<void> show(
    BuildContext context, {
    ProOfferSummary? offer,
    int? scansUsed,
    int? scanLimit,
    required VoidCallback onUpgrade,
    VoidCallback? onDismiss,
  }) async {
    final upgraded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder:
          (sheetContext) => ProOfferSheet(
            offer: offer,
            scansUsed: scansUsed,
            scanLimit: scanLimit,
            onUpgrade: () => Navigator.pop(sheetContext, true),
            onDismiss: () => Navigator.pop(sheetContext, false),
          ),
    );
    if (upgraded == true) {
      onUpgrade();
    } else {
      onDismiss?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = AppMotion.reduceMotion(context);
    final offer = this.offer;
    final height = MediaQuery.sizeOf(context).height;

    Widget enter(Widget child, int delayMs) {
      if (reduceMotion) return child;
      return child
          .animate(delay: delayMs.ms)
          .fadeIn(duration: 450.ms, curve: AppMotion.entranceCurve)
          .slideY(
            begin: 0.08,
            end: 0,
            duration: 450.ms,
            curve: AppMotion.entranceCurve,
          );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height * 0.94),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.45, 1],
              colors: [_Palette.bgTop, _Palette.bgMid, _Palette.bgBottom],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(child: _Backdrop(reduceMotion: reduceMotion)),
              ),
              SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(onClose: onDismiss),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Header(
                              offer: offer,
                              endsOn: _endsOn(context, offer, l10n),
                              reduceMotion: reduceMotion,
                            ),
                            const SizedBox(height: 22),
                            if (offer != null && offer.shareOfMonthly != null)
                              enter(
                                _SavingsCard(offer: offer, reduceMotion: reduceMotion),
                                250,
                              )
                            else if (offer != null)
                              enter(_PlainPriceCard(offer: offer), 250),
                            if (offer != null) const SizedBox(height: 12),
                            if (scansUsed != null && scanLimit != null) ...[
                              enter(
                                _UsageMeter(
                                  used: scansUsed!,
                                  limit: scanLimit!,
                                  reduceMotion: reduceMotion,
                                ),
                                350,
                              ),
                              const SizedBox(height: 12),
                            ],
                            enter(
                              _Comparison(scanLimit: scanLimit ?? _fallbackScanLimit),
                              450,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _Footer(
                      title: offer?.cta(l10n) ?? l10n.pro_offer_get_pro,
                      detail: offer?.ctaDetail(l10n),
                      onUpgrade: onUpgrade,
                      onDismiss: onDismiss,
                      reduceMotion: reduceMotion,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _endsOn(
    BuildContext context,
    ProOfferSummary? offer,
    AppLocalizations l10n,
  ) {
    final end = offer?.endsAt;
    if (end == null || !end.isAfter(now ?? DateTime.now())) return null;
    final locale = Localizations.localeOf(context).toString();
    return l10n.pro_offer_ends_on(DateFormat.MMMd(locale).format(end));
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.reduceMotion});

  final bool reduceMotion;

  static const _sparkles = <(double, double, double, int)>[
    (0.10, 46, 3, 0),
    (0.86, 64, 2.5, 500),
    (0.74, 150, 2, 1100),
    (0.18, 196, 2, 800),
    (0.93, 236, 3, 300),
    (0.05, 118, 2, 1400),
    (0.62, 30, 2, 1800),
  ];

  @override
  Widget build(BuildContext context) {
    Widget orb(Color color, double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
    Widget drift(Widget child, Offset to, Duration period) {
      if (reduceMotion) return child;
      return child
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .move(begin: Offset.zero, end: to, duration: period, curve: Curves.easeInOut);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: -150,
              left: -120,
              child: drift(
                orb(_Palette.emerald.withValues(alpha: 0.42), 380),
                const Offset(40, 30),
                7.seconds,
              ),
            ),
            Positioned(
              top: -90,
              right: -140,
              child: drift(
                orb(_Palette.gold.withValues(alpha: 0.28), 340),
                const Offset(-30, 40),
                9.seconds,
              ),
            ),
            for (final (x, top, size, delay) in _sparkles)
              Positioned(
                left: x * constraints.maxWidth,
                top: top,
                child: _Sparkle(size: size, delayMs: delay, reduceMotion: reduceMotion),
              ),
          ],
        );
      },
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({
    required this.size,
    required this.delayMs,
    required this.reduceMotion,
  });

  final double size;
  final int delayMs;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _Palette.goldLight,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: _Palette.goldLight.withValues(alpha: 0.8), blurRadius: 6),
        ],
      ),
    );
    if (reduceMotion) return Opacity(opacity: 0.6, child: dot);
    return dot
        .animate(delay: delayMs.ms, onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.15, end: 1, duration: 1600.ms, curve: Curves.easeInOut);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(0, -0.45),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          PositionedDirectional(
            end: 12,
            top: 10,
            child: Semantics(
              button: true,
              label: MaterialLocalizations.of(context).closeButtonTooltip,
              child: InkResponse(
                onTap: onClose,
                radius: 22,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.x, size: 16, color: _Palette.muted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.offer,
    required this.endsOn,
    required this.reduceMotion,
  });

  final ProOfferSummary? offer;
  final String? endsOn;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offer = this.offer;
    final percent = offer?.percentOff;

    Widget enter(Widget child, int delayMs) {
      if (reduceMotion) return child;
      return child
          .animate(delay: delayMs.ms)
          .fadeIn(duration: 450.ms, curve: AppMotion.entranceCurve)
          .slideY(begin: 0.15, end: 0, duration: 450.ms, curve: AppMotion.entranceCurve);
    }

    return Column(
      children: [
        _Medallion(reduceMotion: reduceMotion),
        const SizedBox(height: 6),
        enter(
          Text(
            l10n.pro_offer_brand,
            style: const TextStyle(
              color: _Palette.gold,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 3.2,
            ),
          ),
          80,
        ),
        const SizedBox(height: 12),
        if (offer?.campaignLabel != null) ...[
          enter(_Chip(label: offer!.campaignLabel!, icon: LucideIcons.sparkles), 120),
          const SizedBox(height: 12),
        ],
        if (percent != null)
          enter(
            _BigDiscount(
              percent: percent,
              caption:
                  offer!.introPrice != null
                      ? l10n.pro_offer_off_first_year
                      : l10n.pro_offer_off_yearly,
              reduceMotion: reduceMotion,
            ),
            140,
          )
        else ...[
          enter(
            Text(
              l10n.pro_offer_title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            140,
          ),
          const SizedBox(height: 8),
          enter(
            Text(
              l10n.pro_offer_subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _Palette.muted, fontSize: 15.5),
            ),
            200,
          ),
        ],
        if (endsOn != null) ...[
          const SizedBox(height: 14),
          enter(_Chip(label: endsOn!, icon: LucideIcons.clock), 220),
        ],
      ],
    );
  }
}

class _Medallion extends StatelessWidget {
  const _Medallion({required this.reduceMotion});

  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    Widget halo = Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _Palette.gold.withValues(alpha: 0.45), width: 1.5),
      ),
    );
    Widget core = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _Palette.goldGradient,
        boxShadow: [
          BoxShadow(
            color: _Palette.gold.withValues(alpha: 0.55),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(LucideIcons.crown, size: 30, color: _Palette.ink),
    );
    if (!reduceMotion) {
      // A ring of light that keeps widening away from the crown.
      halo = halo
          .animate(onPlay: (c) => c.repeat())
          .scale(
            begin: const Offset(0.75, 0.75),
            end: const Offset(1.3, 1.3),
            duration: 2400.ms,
            curve: Curves.easeOut,
          )
          .fadeOut(duration: 2400.ms, curve: Curves.easeIn);
      core = core
          .animate()
          .scale(
            begin: const Offset(0.4, 0.4),
            end: const Offset(1, 1),
            duration: 650.ms,
            curve: Curves.easeOutBack,
          )
          .then(delay: 200.ms)
          .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.7));
    }
    return SizedBox(
      width: 120,
      height: 110,
      child: Stack(alignment: Alignment.center, children: [halo, core]),
    );
  }
}

class _BigDiscount extends StatelessWidget {
  const _BigDiscount({
    required this.percent,
    required this.caption,
    required this.reduceMotion,
  });

  final int percent;
  final String caption;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget number(double value) => ShaderMask(
      shaderCallback: (bounds) => _Palette.goldGradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        l10n.pro_offer_big_percent('${value.round()}'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 78,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: -2,
        ),
      ),
    );

    // The saving counts up from zero as the sheet opens.
    final counter =
        reduceMotion
            ? number(percent.toDouble())
            : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percent.toDouble()),
              duration: 1300.ms,
              curve: Curves.easeOutCubic,
              builder: (_, value, _) => number(value),
            );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            counter,
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                l10n.pro_offer_off,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _Palette.muted,
            fontSize: 15.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _Palette.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _Palette.gold.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _Palette.goldLight),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: _Palette.goldLight,
                  fontSize: 13,
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

class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _Palette.glass,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Palette.glassBorder),
      ),
      child: child,
    );
  }
}

/// A year paid monthly against the offer, as two bars: the gap is the saving.
class _SavingsCard extends StatelessWidget {
  const _SavingsCard({required this.offer, required this.reduceMotion});

  final ProOfferSummary offer;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BarRow(
            label: l10n.pro_offer_paying_monthly,
            value: Text(
              offer.yearAtMonthlyRate!,
              style: const TextStyle(
                color: _Palette.muted,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.lineThrough,
                decorationColor: _Palette.muted,
                decorationThickness: 2,
              ),
            ),
            share: 1,
            fill: BoxDecoration(color: Colors.white.withValues(alpha: 0.22)),
            animate: false,
          ),
          const SizedBox(height: 14),
          _BarRow(
            label: l10n.pro_offer_with_offer,
            value: Text(
              offer.firstYearPrice,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            share: offer.shareOfMonthly!,
            fill: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_Palette.emeraldBright, _Palette.gold],
              ),
            ),
            animate: !reduceMotion,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (offer.savings != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: _Palette.goldGradient,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.tag, size: 14, color: _Palette.ink),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n.pro_offer_you_save(offer.savings!),
                          style: const TextStyle(
                            color: _Palette.ink,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (offer.perDay != null)
                Text(
                  l10n.pro_offer_per_day(offer.perDay!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.share,
    required this.fill,
    required this.animate,
  });

  final String label;
  final Widget value;
  final double share;
  final Decoration fill;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    Widget bar(double width) => FractionallySizedBox(
      widthFactor: width.clamp(0.02, 1.0),
      alignment: AlignmentDirectional.centerStart,
      child: DecoratedBox(decoration: fill),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _Palette.muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            value,
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 10,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(color: Colors.white.withValues(alpha: 0.07)),
                ),
                Positioned.fill(
                  child:
                      animate
                          ? TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: share),
                            duration: 1200.ms,
                            curve: Curves.easeOutCubic,
                            builder: (_, value, _) => bar(value),
                          )
                          : bar(share),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlainPriceCard extends StatelessWidget {
  const _PlainPriceCard({required this.offer});

  final ProOfferSummary offer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final note =
        offer.introPrice != null
            ? l10n.pro_offer_first_year
            : offer.isAnnual
            ? l10n.pro_offer_year
            : l10n.pro_offer_month;
    return _Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(
                offer.firstYearPrice,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  note,
                  style: const TextStyle(
                    color: _Palette.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (offer.perMonth != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.pro_offer_approx_month(offer.perMonth!),
              style: const TextStyle(color: _Palette.muted, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _UsageMeter extends StatelessWidget {
  const _UsageMeter({
    required this.used,
    required this.limit,
    required this.reduceMotion,
  });

  final int used;
  final int limit;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final share = limit <= 0 ? 1.0 : (used / limit).clamp(0.0, 1.0);
    final color = share >= 0.8 ? _Palette.amber : _Palette.emeraldBright;

    Widget bar(double width) => FractionallySizedBox(
      widthFactor: width.clamp(0.02, 1.0),
      alignment: AlignmentDirectional.centerStart,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );

    return _Glass(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.scanLine, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.pro_offer_scans_used(used, limit),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    height: 6,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ColoredBox(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        Positioned.fill(
                          child:
                              reduceMotion
                                  ? bar(share)
                                  : TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: share),
                                    duration: 1000.ms,
                                    curve: Curves.easeOutCubic,
                                    builder: (_, value, _) => bar(value),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Free against Pro, row by row, using the app's real limits.
class _Comparison extends StatelessWidget {
  const _Comparison({required this.scanLimit});

  final int scanLimit;

  static const double _freeColumn = 70;
  static const double _proColumn = 88;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget freeText(String text) => Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: _Palette.muted,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
    Widget proText(String text) => Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: _Palette.goldLight,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
    final locked = Icon(
      LucideIcons.lock,
      size: 16,
      color: _Palette.muted.withValues(alpha: 0.7),
    );
    final included = Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: _Palette.emerald,
        shape: BoxShape.circle,
      ),
      child: const Icon(LucideIcons.check, size: 14, color: Colors.white),
    );

    final rows = <(IconData, String, Widget, Widget)>[
      (
        LucideIcons.scanLine,
        l10n.pro_offer_row_scans,
        freeText(l10n.pro_offer_scans_month(scanLimit)),
        proText(l10n.pro_offer_unlimited),
      ),
      (
        LucideIcons.sparkles,
        l10n.pro_offer_row_coach,
        freeText(l10n.pro_offer_limited),
        proText(l10n.pro_offer_unlimited),
      ),
      (LucideIcons.calendarDays, l10n.pro_offer_row_planner, locked, included),
      (LucideIcons.barChart3, l10n.pro_offer_row_reports, locked, included),
      (
        LucideIcons.history,
        l10n.pro_offer_row_history,
        freeText(l10n.pro_offer_days(ProFeatureService.freeHistoryDays)),
        proText(l10n.pro_offer_full),
      ),
    ];

    return _Glass(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // The Pro column, lit in gold behind its cells.
          PositionedDirectional(
            end: 8,
            top: 8,
            bottom: 8,
            width: _proColumn,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _Palette.gold.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _Palette.gold.withValues(alpha: 0.45)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 8, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.pro_offer_compare_title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: _freeColumn,
                      child: Center(
                        child: Text(
                          l10n.pro_offer_free,
                          style: const TextStyle(
                            color: _Palette.muted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: _proColumn,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: _Palette.goldGradient,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            l10n.pro_offer_pro,
                            style: const TextStyle(
                              color: _Palette.ink,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                for (final (icon, label, free, pro) in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      children: [
                        Icon(icon, size: 17, color: _Palette.emeraldBright),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: _freeColumn, child: Center(child: free)),
                        SizedBox(width: _proColumn, child: Center(child: pro)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.title,
    required this.detail,
    required this.onUpgrade,
    required this.onDismiss,
    required this.reduceMotion,
  });

  final String title;
  final String? detail;
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      decoration: const BoxDecoration(
        color: _Palette.bgBottom,
        border: Border(top: BorderSide(color: _Palette.glassBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CtaButton(
            title: title,
            detail: detail,
            onTap: onUpgrade,
            reduceMotion: reduceMotion,
          ),
          const SizedBox(height: 2),
          TextButton(
            onPressed: onDismiss,
            child: Text(
              l10n.pro_offer_not_now,
              style: const TextStyle(
                color: _Palette.muted,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
          ),
          Text(
            l10n.paywall_cancel_anytime,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _Palette.muted.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.title,
    required this.detail,
    required this.onTap,
    required this.reduceMotion,
  });

  final String title;
  final String? detail;
  final VoidCallback onTap;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    Widget button = DecoratedBox(
      decoration: BoxDecoration(
        gradient: _Palette.goldGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _Palette.gold.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _Palette.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? LucideIcons.arrowLeft
                            : LucideIcons.arrowRight,
                        size: 20,
                        color: _Palette.ink,
                      ),
                    ],
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _Palette.ink.withValues(alpha: 0.75),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
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
    if (!reduceMotion) {
      // A sweep of light across the button every few seconds.
      button = button
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            delay: 1800.ms,
            duration: 1300.ms,
            color: Colors.white.withValues(alpha: 0.55),
          );
    }
    return button;
  }
}
