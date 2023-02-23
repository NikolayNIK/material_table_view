## 3.1.3

- Screenshots updated.

## 3.1.2

- README updated.

## 3.1.1

- `SliverTableView` hit detection bug fixed.
- README updated.

## 3.1.0

- `SliverTableView` introduced.

## 3.0.2

- Fix a bug leading to a memory leak and perpetual exceptions in debug mode
  when the table is disposed separately from the `placeholderShade` used by it.

## 3.0.1

- Documentation comments and static analysis fixes.

## 3.0.0

- Substantial performance improvements.
- Rows and cells are no longer rebuilt on horizontal scroll.
- Cell widgets no longer lose state when transitioning between
  scrolled and fixed state.
- Both regular and placeholder row widgets are now built in the same
  hierarchy meaning that both types of row widgets will share
  a state as long as their types and keys match.
  Thanks to that, `GlobalKey` and `RepaintBoundary` hacks are
  no longer required to implement transitions between them
- Limitations on the usage of certain widgets for wrapping rows
  are introduced because of intrusive optimizations. Refer to
  [the README section](https://github.com/NikolayNIK/material_table_view#row-wrapping-widgets-restriction)
  for more information.
- Deprecated `placeholderContainerBuilder` `TableView` constructor
  parameter is removed. Use `placeholderShade` described below to
  implement placeholder shading.
- `placeholderShade` parameter introduced in a `TableView.builder`
  constructor which can be used to implement placeholder shading.
- Deprecated default constructor of `TableView` is removed.
- `dividerRevealOffset` property of a `TableView.builder` constructor is now removed.

## 2.1.3

- Deprecations and warnings fixes.

## 2.1.2

- Placeholder system is now deprecated and scheduled to be removed in the next
  major release to allow for further optimization and feature development.
  It is advised to use the [approach](https://docs.flutter.dev/cookbook/effects/shimmer-loading#paint-one-big-shimmer)
  suggested in the official docs instead.

## 2.1.1

- Minor bug fixes and improvements.

## 2.1.0

- New `bodyContainerBuilder` property implemented.

## 2.0.0

- Existing nameless `TableView` constructor is now deprecated and no longer constant
  but otherwise works the same.
- New named `TableView.builder` constructor added in which
  decorators are removed in favor of row-building function returning a widget
  built with the help of a closure passed as an argument.
- Performance improvements.

## 1.0.2

- Fix name conflict of ListenableBuilder widget with upcoming SDK counterpart.
- Included demo project as an example.
- README changes.

## 1.0.1

- README and pubspec changes.

## 1.0.0

- Initial release.