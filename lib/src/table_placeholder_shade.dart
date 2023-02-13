import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

abstract class TablePlaceholderShade implements Listenable {
  const TablePlaceholderShade();

  const factory TablePlaceholderShade.static({
    required ShaderCallback shaderCallback,
    BlendMode blendMode,
  }) = _StaticTablePlaceholderShade;

  ShaderCallback get shaderCallback;

  BlendMode get blendMode => BlendMode.modulate;
}

@immutable
class _StaticTablePlaceholderShade extends TablePlaceholderShade {
  const _StaticTablePlaceholderShade({
    required this.shaderCallback,
    this.blendMode = BlendMode.modulate,
  });

  @override
  final ShaderCallback shaderCallback;

  @override
  final BlendMode blendMode;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
