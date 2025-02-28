import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

abstract class TableSectionOffset implements ValueListenable<double> {
  const TableSectionOffset._();

  static const TableSectionOffset zero = _FixedTableSectionOffset._zero();

  const factory TableSectionOffset.fixed(double value) =
      _FixedTableSectionOffset._;

  factory TableSectionOffset.wrap(ViewportOffset offset) =
      _ViewportTableSectionOffset._;

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

class ShiftedTableSectionOffset extends TableSectionOffset with ChangeNotifier {
  ShiftedTableSectionOffset(
    this._offset, [
    double initialShift = .0,
  ])  : shift = ValueNotifier(initialShift),
        super._() {
    _offset.addListener(notifyListeners);
    shift.addListener(notifyListeners);
  }

  final ValueNotifier<double> shift;

  ViewportOffset _offset;

  ViewportOffset get offset => _offset;

  set offset(ViewportOffset offset) {
    if (identical(_offset, offset)) return;

    _offset.removeListener(notifyListeners);
    _offset = offset;
    _offset.addListener(notifyListeners);
    notifyListeners();
  }

  @override
  double get value => (_offset.hasPixels ? _offset.pixels : .0) + shift.value;

  @override
  int get hashCode => 0;

  @override
  bool operator ==(Object other) => identical(other, this);

  @override
  void dispose() {
    _offset.removeListener(notifyListeners);
    shift.removeListener(notifyListeners);

    super.dispose();
  }
}
