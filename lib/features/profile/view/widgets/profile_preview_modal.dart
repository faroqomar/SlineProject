import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';

import 'package:sline_app/features/profile/view/public_profile_screen.dart';

void showProfilePreview(BuildContext context, String userId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimens.r24),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: PublicProfileScreen(userId: userId),
        );
      },
    ),
  );
}
