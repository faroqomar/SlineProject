import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/features/wallet/utils/wallet_presentation_helper.dart';

class WalletHeroCard extends StatelessWidget {
  const WalletHeroCard({super.key, required this.summary});

  final WalletPresentationSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('wallet_hero_card'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.r24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkTeal,
            AppColors.teal,
            AppColors.lightTeal.withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkTeal.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.r24),
        child: Stack(
          children: [
            Positioned(
              top: -48,
              right: -24,
              child: _GlowOrb(
                size: 148,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              bottom: -62,
              left: -30,
              child: _GlowOrb(
                size: 168,
                color: AppColors.gold.withValues(alpha: 0.18),
              ),
            ),
            Positioned(
              top: 72,
              right: 28,
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white.withValues(alpha: 0.24),
                size: AppDimens.p40,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.p24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.p10,
                          vertical: AppDimens.p6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppDimens.r30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          'WALLET',
                          style: AppTypography.micro.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.p18),
                  Text(
                    'Total funds',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.76),
                    ),
                  ),
                  const SizedBox(height: AppDimens.p8),
                  Text(
                    PriceFormatter.formatPrice(summary.totalFunds),
                    style: AppTypography.h1.copyWith(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: AppDimens.p8),
                  Text(
                    summary.activityCaption,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: AppDimens.p20),
                  Text(
                    'Balance composition',
                    style: AppTypography.micro.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: AppDimens.p10),
                  _WalletBalanceCompositionBar(slices: summary.balanceSlices),
                  const SizedBox(height: AppDimens.p18),
                  Wrap(
                    spacing: AppDimens.p10,
                    runSpacing: AppDimens.p10,
                    children: summary.balanceSlices
                        .map((slice) => _BalanceChip(slice: slice))
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _WalletBalanceCompositionBar extends StatelessWidget {
  const _WalletBalanceCompositionBar({required this.slices});

  final List<WalletBalanceSlice> slices;

  @override
  Widget build(BuildContext context) {
    final totalRatio = slices.fold<double>(
      0,
      (runningTotal, slice) => runningTotal + slice.ratio,
    );

    return Container(
      height: AppDimens.p12,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.r30),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (totalRatio == 0) {
            return const SizedBox.expand();
          }

          var left = 0.0;
          final bars = <Widget>[];
          for (var index = 0; index < slices.length; index += 1) {
            final slice = slices[index];
            final width = index == slices.length - 1
                ? constraints.maxWidth - left
                : constraints.maxWidth * slice.ratio;
            bars.add(
              AnimatedPositioned(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                left: left,
                top: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  width: width.clamp(0.0, constraints.maxWidth),
                  decoration: BoxDecoration(
                    color: _sliceColor(slice.kind),
                    borderRadius: BorderRadius.horizontal(
                      left: index == 0
                          ? const Radius.circular(AppDimens.r30)
                          : Radius.zero,
                      right: index == slices.length - 1
                          ? const Radius.circular(AppDimens.r30)
                          : Radius.zero,
                    ),
                  ),
                ),
              ),
            );
            left += width;
          }

          return Stack(children: bars);
        },
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({required this.slice});

  final WalletBalanceSlice slice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p12,
        vertical: AppDimens.p10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppDimens.p8,
            height: AppDimens.p8,
            decoration: BoxDecoration(
              color: _sliceColor(slice.kind),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDimens.p8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slice.label,
                style: AppTypography.micro.copyWith(
                  color: Colors.white.withValues(alpha: 0.74),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                PriceFormatter.formatPrice(slice.amount),
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _sliceColor(WalletBalanceSliceKind kind) {
  switch (kind) {
    case WalletBalanceSliceKind.available:
      return Colors.white;
    case WalletBalanceSliceKind.pendingWithdrawal:
      return AppColors.lightRed;
    case WalletBalanceSliceKind.held:
      return AppColors.gold;
  }
}
