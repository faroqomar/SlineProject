import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';

import 'package:sline_app/features/profile/view/public_profile_screen.dart';

/// Opens the public profile route inside the Amber Dusk preview sheet.
///
/// The modal only hosts [PublicProfileScreen]; data loading and route actions
/// remain owned by that screen and its ViewModels.
void showProfilePreview(BuildContext context, String userId) {
  unawaited(
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AmberDuskTokens.colors.transparent,
      barrierColor: AmberDuskTokens.colors.scrim,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.p10,
              AppDimens.p0,
              AppDimens.p10,
              AppDimens.p10,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AmberDuskTokens.colors.background,
                borderRadius: BorderRadius.circular(
                  AmberDuskTokens.spacing.sheetRadius,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: PublicProfileScreen(userId: userId),
            ),
          );
        },
      ),
    ),
  );
}
