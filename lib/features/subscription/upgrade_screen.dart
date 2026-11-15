import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart' as inset;
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

enum UpgradeBillingPeriod { monthly, yearly }

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key, this.hasUsedTrial = false});

  final bool hasUsedTrial;

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  UpgradeBillingPeriod _billingPeriod = UpgradeBillingPeriod.monthly;

  static const double _monthlyPrice = 4.99;
  static const double _yearlyPrice = 39.99;

  static const _lightBackgroundAsset =
      'assets/backgrounds/background_light_white.svg';
  static const _darkBackgroundAsset =
      'assets/backgrounds/background_upgrade_dark.svg';
  static const _illustrationAsset = 'assets/upgrade_illustration.png';

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _background => AppColors.lightBackground;

  Color get _headingColor => _isDark ? AppColors.white : AppColors.lightText;

  Color get _supportingColor =>
      _isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

  String get _price {
    final price = _billingPeriod == UpgradeBillingPeriod.monthly
        ? _monthlyPrice
        : _yearlyPrice;

    return '\$${price.toStringAsFixed(2)}';
  }

  String get _period =>
      _billingPeriod == UpgradeBillingPeriod.monthly ? 'month' : 'year';

  int get _yearlySavingsPercentage {
    final regularAnnualPrice = _monthlyPrice * 12;
    final savings = regularAnnualPrice - _yearlyPrice;

    return ((savings / regularAnnualPrice) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              _isDark ? _darkBackgroundAsset : _lightBackgroundAsset,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 4),
                        _buildIllustration(),
                        const SizedBox(height: 18),
                        _buildHeadings(),
                        const SizedBox(height: 22),
                        _buildBenefits(),
                        const SizedBox(height: 28),
                        _buildBillingSelector(),
                      ],
                    ),
                  ),
                ),
                _buildBottomOffer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: _close,
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.black,
                size: 25,
              ),
              tooltip: 'Close',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        width: double.infinity,
        child: Image.asset(
          _illustrationAsset,
          width: double.infinity,
          fit: BoxFit.fitWidth,
          cacheWidth: 1200,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }

  Widget _buildHeadings() {
    return Column(
      children: [
        Text(
          'Unlock Pro',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _headingColor,
            fontSize: 36,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'What you’ll get with Pro',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _headingColor,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefits() {
    const benefits = [
      'Projects & Organization',
      'Advanced Statistics',
      'AI Time Insights',
      'Goals & Targets',
      'Historical Reports',
      'Ad-Free Experience',
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 250),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: benefits.map((benefit) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 19,
                    color: _supportingColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      benefit,
                      style: TextStyle(
                        color: _supportingColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBillingSelector() {
    return Center(
      child: SizedBox(
        width: 230,
        height: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.3, sigmaY: 8.3),
            child: Container(
              decoration: inset.BoxDecoration(
                color: Colors.white.withValues(alpha: 0.43),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFC7C7C7), width: 2),
                boxShadow: [
                  inset.BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 30,
                    offset: Offset.zero,
                    inset: true,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final optionWidth = constraints.maxWidth / 2;

                  final selectedIndex =
                      _billingPeriod == UpgradeBillingPeriod.monthly ? 0 : 1;

                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOutCubic,
                        left: selectedIndex * optionWidth,
                        top: 0,
                        bottom: 0,
                        width: optionWidth,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.lightText,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _billingOption(
                            label: 'Monthly',
                            period: UpgradeBillingPeriod.monthly,
                          ),
                          _billingOption(
                            label: 'Yearly',
                            period: UpgradeBillingPeriod.yearly,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _billingOption({
    required String label,
    required UpgradeBillingPeriod period,
  }) {
    final selected = _billingPeriod == period;
    final isYearly = period == UpgradeBillingPeriod.yearly;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => _billingPeriod = period);
        },
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                style: TextStyle(
                  color: selected ? AppColors.white : AppColors.lightText,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(label),
              ),
              if (isYearly) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.20)
                        : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_yearlySavingsPercentage% off',
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomOffer() {
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 62),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: const Color(0xFF212124),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _startTrial,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.hasUsedTrial
                                ? '$_price / $_period'
                                : '14-Day Trial',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!widget.hasUsedTrial) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Then $_price / $_period',
                              style: const TextStyle(
                                color: Color(0xFFE0E0E0),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Cancel anytime',
            style: TextStyle(color: _supportingColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _startTrial() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Subscription setup will be connected in a later step.'),
      ),
    );
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}
