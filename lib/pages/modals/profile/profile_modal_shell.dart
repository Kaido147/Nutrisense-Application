import 'dart:ui';

import 'package:flutter/material.dart';

class ProfileModalShell extends StatelessWidget {
  const ProfileModalShell({
    super.key,
    required this.title,
    required this.child,
    required this.footer,
    this.heightFactor = 0.88,
  });

  final String title;
  final Widget child;
  final Widget footer;
  final double heightFactor;

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double modalHeight =
        MediaQuery.of(context).size.height * heightFactor;
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withValues(alpha: 0.25)),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SizedBox(
              height: modalHeight,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A3D73),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F3F7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFF5A6475),
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 1, color: const Color(0xFFF0F0F0)),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
                        child: child,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                      child: footer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
