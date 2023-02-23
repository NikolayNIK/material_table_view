# material_table_view
[![pub package](https://img.shields.io/pub/v/material_table_view.svg)](https://pub.dev/packages/material_table_view)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/NikolayNIK/material_table_view/blob/master/LICENSE)

This is an open source Flutter package containing
a widget that displays your data
in a both vertically and horizontally scrollable
material-style table with fixed-width freezable columns
dynamically adjusting based on a screen size
with support for billions of on-demand built rows.
This package prioritizes usability and visual consistency
above all else.

<table>
  <tr>
    <td><img src="https://raw.githubusercontent.com/NikolayNIK/material_table_view/f85d7a826a45ead61b927f48626fda39f88cd86b/screenshots/demo-regular-box-windows-light.gif" height="70%"/></td>
    <td><img src="https://raw.githubusercontent.com/NikolayNIK/material_table_view/f85d7a826a45ead61b927f48626fda39f88cd86b/screenshots/demo-slivers-android-dark.gif" height="28%"/></td>
  </tr>
  <tr>
    <td colspan="2">
      This demo uses the shimmer included in the package.
      The source code for this demo is included in the package example
      and is available <a href="https://github.com/NikolayNIK/material_table_view_demo)">here</a>.
    </td>
  </tr>
</table>

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
- Support for placeholder rows.
- Support for custom optionally animated shading of the placeholder
  rows allowing the shader to depend on a vertical scrolling offset
  and to start or stop animating whenever any or none of
  the placeholders are visible.
- Included shimmer shader that allows for animated linear gradient
  to be applied to placeholder rows.
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
- [SliverTableView] - sliver variant of a table view which can be used
  in a [CustomScrollView] alongside other slivers (including other instances
  of the [SliverTableView]) to be scrolled vertically by a single view.
  It features sticky header and footer, and the same capabilities as a regular one.

## Usage

    TableView.builder(
      columns: [
        // TODO specify columns
        const TableColumn(
          width: 56.0,
          freezePriority: 100,
        ),
        for (var i = 1; i < 100; i++)
          const TableColumn(width: 64), // TODO specify freezePriority to freeze a column
      ],
      rowCount: 1048576, // TODO specify row count
      rowHeight: 56.0, // TODO specify row height
      rowBuilder: (context, row, contentBuilder) {
        // TODO fetch row data
        return InkWell(
          onTap: () => print('Row $row clicked'),
          child: contentBuilder(
            context,
            (context, column) => Text('$column'), // TODO build a cell widget
          ),
        );
      },
      // TODO specify other parameters for other features
    ),

## Limitations

### Row wrapping widgets restriction

Not every widget can be used to wrap row widget built in
a rowBuilder and placeholderBuilder functions.
Any widget that may need to utilize compositing will either cause
an exception or will not work as expected.
This includes widgets like `RepaintBoundary`, `Opacity`, `ShaderMask`,
clipping widgets and more. For some of these, special alternatives
are provided by the package that will work for that purpose
(and that purpose only):

- `TableRowOpacity` - an alternative for `Opacity` widget;
- `TableRowFadeTransition` - an alternative for `FadeTransition` widget;
- `tableRowDefaultAnimatedSwitcherTransitionBuilder` function - an alternative
  for the `AnimatedSwitcher.defaultTransitionBuilder` function
  which can be used as a `transitionBuilder` for the `AnimatedSwitcher` in that context
  as a default one will not work.

If any alternative you need are not available,
feel free to use [the issue tracker](https://github.com/NikolayNIK/material_table_view/issues).

Drawing on top of the row might not work as expected.

These limitations do **not** apply to cell widgets built by a `cellBuilder` closure.

These limitations are caused by the custom compositing involved in
a table widget painting used for optimization purposes.

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
- No support for RTL layout.

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
