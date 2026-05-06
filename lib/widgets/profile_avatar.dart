import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/providers/profile_image_provider.dart';

class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    super.key,
    required this.uid,
    required this.size,
    required this.borderColor,
    this.borderWidth = 2,
    this.backgroundColor = Colors.transparent,
    this.fallbackIconColor = const Color(0xFF7C5AA6),
    this.editable = false,
    this.editButtonColor = const Color(0xFFD8B56D),
    this.editIconColor = const Color(0xFF243A6E),
  });

  final String uid;
  final double size;
  final Color borderColor;
  final double borderWidth;
  final Color backgroundColor;
  final Color fallbackIconColor;
  final bool editable;
  final Color editButtonColor;
  final Color editIconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(profileImageControllerProvider(uid));
    final imageBytes = controller.imageBytes;
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: CircleAvatar(
        backgroundColor: backgroundColor,
        backgroundImage: imageBytes == null ? null : MemoryImage(imageBytes),
        child: imageBytes == null
            ? Icon(Icons.person, size: size * 0.4, color: fallbackIconColor)
            : null,
      ),
    );

    final content = editable
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              avatar,
              Positioned(
                right: size * 0.02,
                bottom: size * 0.05,
                child: Container(
                  width: size * 0.28,
                  height: size * 0.28,
                  decoration: BoxDecoration(
                    color: editButtonColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: controller.isPicking
                      ? Padding(
                          padding: EdgeInsets.all(size * 0.07),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: editIconColor,
                          ),
                        )
                      : Icon(
                          Icons.camera_alt_outlined,
                          color: editIconColor,
                          size: size * 0.14,
                        ),
                ),
              ),
            ],
          )
        : avatar;

    return GestureDetector(
      onTap: editable
          ? () => ref.read(profileImageControllerProvider(uid)).pickAndSave()
          : null,
      child: content,
    );
  }
}
