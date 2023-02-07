import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

@immutable
class TableViewPlaceholderShaderConfig {
  const TableViewPlaceholderShaderConfig({
    required this.shaderCallback,
    this.blendMode = BlendMode.modulate,
  });

  final ShaderCallback shaderCallback;

  final BlendMode blendMode;
}
