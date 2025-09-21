import 'dart:io';
import 'package:flutter/material.dart';

/// A resilient avatar widget that gracefully handles missing or corrupted image files
/// by falling back to a default asset avatar.
class ResilientAvatar extends StatelessWidget {
  final String? avatarPath;
  final double radius;
  final Color? backgroundColor;
  final Widget? child;

  const ResilientAvatar({
    super.key,
    this.avatarPath,
    this.radius = 20,
    this.backgroundColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: _buildResilientImageProvider(),
      child: child,
    );
  }

  /// Builds an image provider that falls back to default asset if file loading fails
  ImageProvider? _buildResilientImageProvider() {
    if (avatarPath == null || avatarPath!.isEmpty) {
      return const AssetImage('assets/avatars/image001.png');
    }

    try {
      final file = File(avatarPath!);
      if (!file.existsSync()) {
        return const AssetImage('assets/avatars/image001.png');
      }
      return FileImage(file);
    } catch (e) {
      // File system access error or other exception
      return const AssetImage('assets/avatars/image001.png');
    }
  }
}

/// A resilient image widget that gracefully handles missing or corrupted image files
/// by falling back to a default asset image.
class ResilientBackgroundImage extends StatelessWidget {
  final String? imagePath;
  final Widget child;
  final BoxFit fit;
  final bool isAvatar;

  const ResilientBackgroundImage({
    super.key,
    required this.imagePath,
    required this.child,
    this.fit = BoxFit.cover,
    this.isAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: _buildResilientImageProvider(),
          fit: fit,
        ),
      ),
      child: child,
    );
  }

  /// Builds an image provider that falls back to default asset if file loading fails
  ImageProvider _buildResilientImageProvider() {
    if (imagePath == null || imagePath!.isEmpty) {
      return AssetImage(isAvatar 
        ? 'assets/avatars/image001.png' 
        : 'assets/runner.png');
    }

    try {
      final file = File(imagePath!);
      if (!file.existsSync()) {
        return AssetImage(isAvatar 
          ? 'assets/avatars/image001.png' 
          : 'assets/runner.png');
      }
      return FileImage(file);
    } catch (e) {
      // File system access error or other exception
      return AssetImage(isAvatar 
        ? 'assets/avatars/image001.png' 
        : 'assets/runner.png');
    }
  }
}

/// Utility function to get a resilient image provider for any image path
ImageProvider getResilientImageProvider(String? imagePath, {bool isAvatar = false}) {
  if (imagePath == null || imagePath.isEmpty) {
    return AssetImage(isAvatar 
      ? 'assets/avatars/image001.png' 
      : 'assets/runner.png');
  }

  try {
    final file = File(imagePath);
    if (!file.existsSync()) {
      return AssetImage(isAvatar 
        ? 'assets/avatars/image001.png' 
        : 'assets/runner.png');
    }
    return FileImage(file);
  } catch (e) {
    // File system access error or other exception
    return AssetImage(isAvatar 
      ? 'assets/avatars/image001.png' 
      : 'assets/runner.png');
  }
}