extension MaybeIterable<T> on Iterable<T> {
  T? get maybeFirst => isEmpty ? null : first;

  T? get maybeLast => isEmpty ? null : last;
}
