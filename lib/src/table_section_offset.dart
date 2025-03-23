import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

abstract class TableSectionOffset implements ValueListenable<double> {
  const TableSectionOffset._();

  static const TableSectionOffset zero = _FixedTableSectionOffset._zero();

  const factory TableSectionOffset.fixed(double value) =
      _FixedTableSectionOffset._;

  factory TableSectionOffset.wrapViewportOffset(ViewportOffset offset) =
      _ViewportTableSectionOffset._;

  factory TableSectionOffset.wrapValueListenable(ValueListenable<double> offset) =
      _ValueListenableSectionOffset._;

  @override
  operator ==(Object other);

  @override
  int get hashCode;
}

@immutable
class _FixedTableSectionOffset extends TableSectionOffset {
  const _FixedTableSectionOffset._(this.value) : super._();

  const _FixedTableSectionOffset._zero()
      : value = .0,
        super._();

  @override
  final double value;

  @override
  int get hashCode => value.toInt();

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      (other as _FixedTableSectionOffset).value == value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

class _ViewportTableSectionOffset extends TableSectionOffset {
  _ViewportTableSectionOffset._(this._offset) : super._();

  final ViewportOffset _offset;

  @override
  double get value => _offset.hasPixels ? _offset.pixels : .0;

  @override
  int get hashCode => value.toInt();

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      identical((other as _ViewportTableSectionOffset)._offset, _offset);

  @override
  void addListener(VoidCallback listener) => _offset.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _offset.removeListener(listener);
}

class _ValueListenableSectionOffset extends TableSectionOffset {
  _ValueListenableSectionOffset._(this._offset) : super._();

  final ValueListenable<double> _offset;

  @override
  double get value => _offset.value;

  @override
  int get hashCode => value.toInt();

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      identical((other as _ValueListenableSectionOffset)._offset, _offset);

  @override
  void addListener(VoidCallback listener) => _offset.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _offset.removeListener(listener);
}
