# material_table_view

This is an open source Flutter package containing
a widget that displays your data
in a both vertically and horizontally scrollable
material-style table with fixed-width freezable columns
dynamically adjusting based on a screen size
with support for billions of on-demand built rows
and for row placeholders for shimmer effects.
This package prioritizes usability and visual consistency
above all else.

![Material widget demo](./README-demo.gif)
This demo uses a [Shimmer](https://pub.dev/packages/shimmer)
package for shimmer effects that can be seen.

## Features

- Both horizontally and vertically scrolling meaning that both
  rows and columns can be scrolled in order to display large
  amount of data to the user.
- Fixed-width columns that can be frozen
  meaning that it will be docked either at the left or right
  whenever it would otherwise get scrolled off-screen.
  This helps the user not to lose a row-identifying information
  while scrolling horizontally. Columns will automatically
  be unfrozen in case of insufficient horizontal space based
  on a developer-defined freeze priorities meaning that
  table will adjust to any screen size be it mobile or desktop.
- Lazily built fixed-height rows allowing for billions of rows
  to be in one table.
- Support for a custom individual row widget wrapper allowing
  the developer to wrap each individual row in on InkWell
  while containing all cell widgets inside enabling for
  many material interactions within that row.
- Scroll behaviour defined by an application theme used
  including scroll physics, overscroll effects, etc.
  It means that the platform-default scrolling behaviour
  will be used by default if you haven't overridden it.
- Divider animations: when a column gets scrolled under
  another column that become frozen at the edge of a screen,
  a wiggly divider will animate in indicating to the user that
  the columns have been separated and there is more content to
  scroll to.
- Horizontally scrollable header and footer support.
- Placeholder row support with the ability for the developer
  to wrap all visible placeholder row widgets in a
  custom widget. For example, it can be wrapped in a shimmer
  widget in order to achieve a shimmer effect.

## Usage

    TableView(
      columns: [
        // TODO specify columns
        const TableColumn(
          width: 56.0,
          freezePriority: 100,
        ),
        for (var i = 1; i < 100; i++)
          TableColumn(width: 64), // TODO specify freezePriority to freeze a column
      ],
      rowCount: 1048576, // TODO specify row count
      rowBuilder: (row) {
        // TODO fetch row data
        return (context, column) => Text('$column'); // TODO build a cell widget
      },
      // TODO specify other parameters for other features
    ),

## Known issues

- After the first column gets frozen on the
  right side, all columns after it suddenly disappear
  when they should either stay or get animated away.
  This issue appears only when a large enough right
  scroll padding specified so users are not expected
  to come across it.
- Vertical scrollbar is affected by horizontal stretching
  when using a stretching overscroll effect for the
  horizontal scroll that is default on Android causing the
  scrollbar to stretch off the screen on overscroll.

## Getting help

If you encounter any problems or have any feature requests,
feel free to use [GitHub the issue tracker](https://github.com/NikolayNIK/material_table_view/issues)
to search for an existing issue or to open a new one.

## Contribution

If you have something to contribute to the package
feel free to send out a pull request on the GitHub.

## License

All the source code is open
and distributed under the MIT license.
