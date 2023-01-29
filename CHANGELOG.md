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