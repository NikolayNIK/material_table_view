import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Instances of classes extending (or implementing, or mixing-in) this class
/// manage placeholder layer shading.
///
/// Notifying listeners added to it will result in the eventual repainting of
/// the layers shaded by the shader it creates.
abstract class TablePlaceholderShade implements Listenable {
  /// This constructor creates a [TablePlaceholderShade] that isn't effected by
  /// existence of placeholders to shade and that doesn't cause repaints.
  const factory TablePlaceholderShade.static({
    required ShaderCallback shaderCallback,
    BlendMode blendMode,
  }) = _StaticTablePlaceholderShade;

  Shader createShader(Rect bounds, double verticalScrollOffset);

  BlendMode get blendMode => BlendMode.modulate;

  /// Called on every repaint of the layers affected by the shading.
  /// This call is meant be used to determine the need to start or stop
  /// scheduling of updates for the purposes of animating the shader.
  set active(bool active);
}

@immutable
class _StaticTablePlaceholderShade implements TablePlaceholderShade {
  const _StaticTablePlaceholderShade({
    required this.shaderCallback,
    this.blendMode = BlendMode.modulate,
  });

  final ShaderCallback shaderCallback;

  @override
  final BlendMode blendMode;

  @override
  Shader createShader(Rect bounds, double verticalScrollOffset) =>
      shaderCallback(bounds);

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  set active(bool active) {}
}
