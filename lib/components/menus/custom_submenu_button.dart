// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// Examples can assume:
// bool _throwShotAway = false;
// late BuildContext context;
// enum SingingCharacter { lafayette }
// late SingingCharacter? _character;
// late StateSetter setState;

// Enable if you want verbose logging about menu changes.
const bool _kDebugMenus = false;

// The default size of the arrow in _MenuItemLabel that indicates that a menu
// has a submenu.
const double _kDefaultSubmenuIconSize = 24;

// The default spacing between the leading icon, label, trailing icon, and
// shortcut label in a _MenuItemLabel.
const double _kLabelItemDefaultSpacing = 12;

// The minimum spacing between the leading icon, label, trailing icon, and
// shortcut label in a _MenuItemLabel.
const double _kLabelItemMinSpacing = 4;

// Navigation shortcuts that we need to make sure are active when menus are
// open.
const Map<ShortcutActivator, Intent> _kMenuTraversalShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
  SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
  SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
  SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(TraversalDirection.down),
  SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(TraversalDirection.up),
  SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(TraversalDirection.left),
  SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(TraversalDirection.right),
};

// The minimum vertical spacing on the outside of menus.
const double _kMenuVerticalMinPadding = 8;

// How close to the edge of the safe area the menu will be placed.
const double _kMenuViewPadding = 8;

// The minimum horizontal spacing on the outside of the top level menu.
const double _kTopLevelMenuHorizontalMinPadding = 4;

class _MenuAnchorScope extends InheritedWidget {
  const _MenuAnchorScope({required this.state, required super.child});

  final _CustomMenuAnchorState state;

  @override
  bool updateShouldNotify(_MenuAnchorScope oldWidget) {
    assert(oldWidget.state == state, 'The state of a MenuAnchor should not change.');
    return false;
  }
}

/// A widget used to mark the "anchor" for a set of submenus, defining the
/// rectangle used to position the menu, which can be done either with an
/// explicit location, or with an alignment.
///
/// When creating a menu with [MenuBar] or a [CustomSubmenuButton], a [CustomMenuAnchor] is
/// not needed, since they provide their own internally.
///
/// The [CustomMenuAnchor] is meant to be a slightly lower level interface than
/// [MenuBar], used in situations where a [MenuBar] isn't appropriate, or to
/// construct widgets or screen regions that have submenus.
///
/// {@tool dartpad}
/// This example shows how to use a [CustomMenuAnchor] to wrap a button and open a
/// cascading menu from the button.
///
/// ** See code in examples/api/lib/material/menu_anchor/menu_anchor.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example shows how to use a [CustomMenuAnchor] to create a cascading context
/// menu in a region of the view, positioned where the user clicks the mouse
/// with Ctrl pressed. The [anchorTapClosesMenu] attribute is set to true so
/// that clicks on the [CustomMenuAnchor] area will cause the menus to be closed.
///
/// ** See code in examples/api/lib/material/menu_anchor/menu_anchor.1.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example demonstrates a simplified cascading menu using the [CustomMenuAnchor]
/// widget.
///
/// ** See code in examples/api/lib/material/menu_anchor/menu_anchor.3.dart **
/// {@end-tool}
class CustomMenuAnchor extends StatefulWidget {
  /// Creates a const [CustomMenuAnchor].
  ///
  /// The [menuChildren] argument is required.
  const CustomMenuAnchor({
    super.key,
    this.controller,
    this.childFocusNode,
    this.style,
    this.alignmentOffset = Offset.zero,
    this.layerLink,
    this.clipBehavior = Clip.hardEdge,
    @Deprecated(
      'Use consumeOutsideTap instead. '
      'This feature was deprecated after v3.16.0-8.0.pre.',
    )
    this.anchorTapClosesMenu = false,
    this.consumeOutsideTap = false,
    this.onOpen,
    this.onClose,
    this.crossAxisUnconstrained = true,
    this.useRootOverlay = false,
    required this.menuChildren,
    this.builder,
    this.child,
  });

  /// An optional controller that allows opening and closing of the menu from
  /// other widgets.
  final MenuController? controller;

  /// The [childFocusNode] attribute is the optional [FocusNode] also associated
  /// to the [child] or [builder] widget that opens the menu.
  ///
  /// The focus node should be attached to the widget that should receive focus
  /// if keyboard focus traversal moves the focus off of the submenu with the
  /// arrow keys.
  ///
  /// If not supplied, then keyboard traversal from the menu back to the
  /// controlling button when the menu is open is disabled.
  final FocusNode? childFocusNode;

  /// The [MenuStyle] that defines the visual attributes of the menu bar.
  ///
  /// Colors and sizing of the menus is controllable via the [MenuStyle].
  ///
  /// Defaults to the ambient [MenuThemeData.style].
  final MenuStyle? style;

  /// {@template flutter.material.MenuAnchor.alignmentOffset}
  /// The offset of the menu relative to the alignment origin determined by
  /// [MenuStyle.alignment] on the [style] attribute and the ambient
  /// [Directionality].
  ///
  /// Use this for adjustments of the menu placement.
  ///
  /// Increasing [Offset.dy] values of [alignmentOffset] move the menu position
  /// down.
  ///
  /// If the [MenuStyle.alignment] from [style] is not an [AlignmentDirectional]
  /// (e.g. [Alignment]), then increasing [Offset.dx] values of
  /// [alignmentOffset] move the menu position to the right.
  ///
  /// If the [MenuStyle.alignment] from [style] is an [AlignmentDirectional],
  /// then in a [TextDirection.ltr] [Directionality], increasing [Offset.dx]
  /// values of [alignmentOffset] move the menu position to the right. In a
  /// [TextDirection.rtl] directionality, increasing [Offset.dx] values of
  /// [alignmentOffset] move the menu position to the left.
  ///
  /// Defaults to [Offset.zero].
  /// {@endtemplate}
  final Offset? alignmentOffset;

  /// An optional [LayerLink] to attach the menu to the widget that this
  /// [CustomMenuAnchor] surrounds.
  ///
  /// When provided, the menu will follow the widget that this [CustomMenuAnchor]
  /// surrounds if it moves because of view insets changes.
  final LayerLink? layerLink;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// Whether the menus will be closed if the anchor area is tapped.
  ///
  /// For menus opened by buttons that toggle the menu, if the button is tapped
  /// when the menu is open, the button should close the menu. But if
  /// [anchorTapClosesMenu] is true, then the menu will close, and
  /// (surprisingly) immediately re-open. This is because tapping on the button
  /// closes the menu before the `onPressed` or `onTap` handler is called
  /// because of it being considered to be "outside" the menu system, and then
  /// the button (seeing that the menu is closed) immediately reopens the menu.
  /// The result is that the user thinks that tapping on the button does
  /// nothing. So, for button-initiated menus, this value is typically false so
  /// that the menu anchor area is considered "inside" of the menu system and
  /// doesn't cause it to close unless [MenuController.close] is called.
  ///
  /// For menus that are positioned using [MenuController.open]'s `position`
  /// parameter, it is often desirable that clicking on the anchor always closes
  /// the menu since the anchor area isn't usually considered part of the menu
  /// system by the user. In this case [anchorTapClosesMenu] should be true.
  ///
  /// Defaults to false.
  @Deprecated(
    'Use consumeOutsideTap instead. '
    'This feature was deprecated after v3.16.0-8.0.pre.',
  )
  final bool anchorTapClosesMenu;

  /// Whether or not a tap event that closes the menu will be permitted to
  /// continue on to the gesture arena.
  ///
  /// If false, then tapping outside of a menu when the menu is open will both
  /// close the menu, and allow the tap to participate in the gesture arena. If
  /// true, then it will only close the menu, and the tap event will be
  /// consumed.
  ///
  /// Defaults to false.
  final bool consumeOutsideTap;

  /// A callback that is invoked when the menu is opened.
  final VoidCallback? onOpen;

  /// A callback that is invoked when the menu is closed.
  final VoidCallback? onClose;

  /// Determine if the menu panel can be wrapped by a [UnconstrainedBox] which allows
  /// the panel to render at its "natural" size.
  ///
  /// Defaults to true as it allows developers to render the menu panel at the
  /// size it should be. When it is set to false, it can be useful when the menu should
  /// be constrained in both main axis and cross axis, such as a [DropdownMenu].
  final bool crossAxisUnconstrained;

  /// {@macro flutter.widgets.RawMenuAnchor.useRootOverlay}
  ///
  /// Defaults to false.
  final bool useRootOverlay;

  /// A list of children containing the menu items that are the contents of the
  /// menu surrounded by this [CustomMenuAnchor].
  ///
  /// {@macro flutter.material.MenuBar.shortcuts_note}
  final List<Widget> menuChildren;

  /// The widget that this [CustomMenuAnchor] surrounds.
  ///
  /// Typically this is a button used to open the menu by calling
  /// [MenuController.open] on the `controller` passed to the builder.
  ///
  /// If not supplied, then the [CustomMenuAnchor] will be the size that its parent
  /// allocates for it.
  ///
  /// If provided, the builder will be called each time the menu is opened or
  /// closed.
  final MenuAnchorChildBuilder? builder;

  /// The optional child to be passed to the [builder].
  ///
  /// Supply this child if there is a portion of the widget tree built in
  /// [builder] that doesn't depend on the `controller` or `context` supplied to
  /// the [builder]. It will be more efficient, since Flutter doesn't then need
  /// to rebuild this child when those change.
  final Widget? child;

  @override
  State<CustomMenuAnchor> createState() => _CustomMenuAnchorState();

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return menuChildren.map<DiagnosticsNode>((Widget child) => child.toDiagnosticsNode()).toList();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty('anchorTapClosesMenu', value: anchorTapClosesMenu, ifTrue: 'AUTO-CLOSE'),
    );
    properties.add(DiagnosticsProperty<FocusNode?>('focusNode', childFocusNode));
    properties.add(DiagnosticsProperty<MenuStyle?>('style', style));
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior));
    properties.add(DiagnosticsProperty<Offset?>('alignmentOffset', alignmentOffset));
  }
}

class _CustomMenuAnchorState extends State<CustomMenuAnchor> {
  Axis get _orientation => Axis.vertical;
  MenuController get _menuController => widget.controller ?? _internalMenuController!;
  MenuController? _internalMenuController;
  final FocusScopeNode _menuScopeNode = FocusScopeNode();
  _CustomMenuAnchorState? get _parent => _CustomMenuAnchorState._maybeOf(context);

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalMenuController = MenuController();
    }
  }

  @override
  void didUpdateWidget(CustomMenuAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _internalMenuController = widget.controller != null ? MenuController() : null;
    }
  }

  @override
  void dispose() {
    assert(_debugMenuInfo('Disposing of $this'));
    _internalMenuController = null;
    _menuScopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = _MenuAnchorScope(
      state: this,
      child: RawMenuAnchor(
        useRootOverlay: widget.useRootOverlay,
        onOpen: widget.onOpen,
        onClose: widget.onClose,
        consumeOutsideTaps: widget.consumeOutsideTap,
        controller: _menuController,
        childFocusNode: widget.childFocusNode,
        overlayBuilder: _buildOverlay,
        builder: widget.builder,
        child: widget.child,
      ),
    );

    if (widget.layerLink == null) {
      return child;
    }

    return CompositedTransformTarget(link: widget.layerLink!, child: child);
  }

  Widget _buildOverlay(BuildContext context, RawMenuOverlayInfo position) {
    return _Submenu(
      layerLink: widget.layerLink,
      consumeOutsideTaps: widget.consumeOutsideTap,
      menuScopeNode: _menuScopeNode,
      menuStyle: widget.style,
      clipBehavior: widget.clipBehavior,
      menuChildren: widget.menuChildren,
      crossAxisUnconstrained: widget.crossAxisUnconstrained,
      menuPosition: position,
      anchor: this,
      alignmentOffset: widget.alignmentOffset ?? Offset.zero,
    );
  }

  _CustomMenuAnchorState get _root {
    _CustomMenuAnchorState anchor = this;
    while (anchor._parent != null) {
      anchor = anchor._parent!;
    }
    return anchor;
  }

  void _focusButton() {
    if (widget.childFocusNode == null) {
      return;
    }
    assert(_debugMenuInfo('Requesting focus for ${widget.childFocusNode}'));
    widget.childFocusNode!.requestFocus();
  }

  void _focusFirstMenuItem() {
    if (_menuScopeNode.context?.mounted != true) {
      return;
    }
    final FocusTraversalPolicy policy =
        FocusTraversalGroup.maybeOf(_menuScopeNode.context!) ?? ReadingOrderTraversalPolicy();
    final FocusNode? firstFocus = policy.findFirstFocus(_menuScopeNode, ignoreCurrentFocus: true);
    if (firstFocus != null) {
      firstFocus.requestFocus();
    }
  }

  void _focusLastMenuItem() {
    if (_menuScopeNode.context?.mounted != true) {
      return;
    }
    final FocusTraversalPolicy policy =
        FocusTraversalGroup.maybeOf(_menuScopeNode.context!) ?? ReadingOrderTraversalPolicy();
    final FocusNode lastFocus = policy.findLastFocus(_menuScopeNode, ignoreCurrentFocus: true);
    lastFocus.requestFocus();
  }

  static _CustomMenuAnchorState? _maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_MenuAnchorScope>()?.state;
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    return describeIdentity(this);
  }
}

/// A button for use in a [MenuBar], in a menu created with [MenuAnchor], or on
/// its own, that can be activated by click or keyboard navigation.
///
/// This widget represents a leaf entry in a menu hierarchy that is typically
/// part of a [MenuBar], but may be used independently, or as part of a menu
/// created with a [MenuAnchor].
///
/// {@macro flutter.material.MenuBar.shortcuts_note}
///
/// See also:
///
/// * [MenuBar], a class that creates a top level menu bar in a Material Design
///   style.
/// * [MenuAnchor], a widget that creates a region with a submenu and shows it
///   when requested.
/// * [SubmenuButton], a menu item similar to this one which manages a submenu.
/// * [PlatformMenuBar], which creates a menu bar that is rendered by the host
///   platform instead of by Flutter (on macOS, for example).
/// * [ShortcutRegistry], a registry of shortcuts that apply for the entire
///   application.
/// * [VoidCallbackIntent], to define intents that will call a [VoidCallback] and
///   work with the [Actions] and [Shortcuts] system.
/// * [CallbackShortcuts] to define shortcuts that call a callback without
///   involving [Actions].
class CustomMenuItemButton extends StatefulWidget {
  /// Creates a const [CustomMenuItemButton].
  ///
  /// The [child] attribute is required.
  const CustomMenuItemButton({
    super.key,
    this.onPressed,
    this.onHover,
    this.requestFocusOnHover = true,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.shortcut,
    this.semanticsLabel,
    this.style,
    this.statesController,
    this.clipBehavior = Clip.none,
    this.leadingIcon,
    this.trailingIcon,
    this.closeOnActivate = true,
    this.overflowAxis = Axis.horizontal,
    this.child,
  });

  /// Called when the button is tapped or otherwise activated.
  ///
  /// If this callback is null, then the button will be disabled.
  ///
  /// See also:
  ///
  ///  * [enabled], which is true if the button is enabled.
  final VoidCallback? onPressed;

  /// Called when a pointer enters or exits the button response area.
  ///
  /// The value passed to the callback is true if a pointer has entered button
  /// area and false if a pointer has exited.
  final ValueChanged<bool>? onHover;

  /// Determine if hovering can request focus.
  ///
  /// Defaults to true.
  final bool requestFocusOnHover;

  /// Handler called when the focus changes.
  ///
  /// Called with true if this widget's node gains focus, and false if it loses
  /// focus.
  final ValueChanged<bool>? onFocusChange;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// The optional shortcut that selects this [CustomMenuItemButton].
  ///
  /// {@macro flutter.material.MenuBar.shortcuts_note}
  final MenuSerializableShortcut? shortcut;

  /// An optional Semantics label, applied to the entire [CustomMenuItemButton].
  ///
  /// A screen reader will default to reading the derived text on the
  /// [CustomMenuItemButton] itself, which is not guaranteed to be readable.
  /// (For some shortcuts, such as comma, semicolon, and other
  /// punctuation, screen readers read silence).
  ///
  /// Setting this label overwrites the semantics properties of the entire
  /// Widget, including its children. Consider wrapping this widget in
  /// [Semantics] if you want to customize other properties besides just
  /// the label.
  ///
  /// Null by default.
  final String? semanticsLabel;

  /// Customizes this button's appearance.
  ///
  /// Non-null properties of this style override the corresponding properties in
  /// [themeStyleOf] and [defaultStyleOf]. [WidgetStateProperty]s that resolve
  /// to non-null values will similarly override the corresponding
  /// [WidgetStateProperty]s in [themeStyleOf] and [defaultStyleOf].
  ///
  /// Null by default.
  final ButtonStyle? style;

  /// {@macro flutter.material.inkwell.statesController}
  final MaterialStatesController? statesController;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// An optional icon to display before the [child] label.
  final Widget? leadingIcon;

  /// An optional icon to display after the [child] label.
  final Widget? trailingIcon;

  /// {@template flutter.material.menu_anchor.closeOnActivate}
  /// Determines if the menu will be closed when a [CustomMenuItemButton]
  /// is pressed.
  ///
  /// Defaults to true.
  /// {@endtemplate}
  final bool closeOnActivate;

  /// The direction in which the menu item expands.
  ///
  /// If the menu item button is a descendent of [MenuAnchor] or [MenuBar], then
  /// this property is ignored.
  ///
  /// If [overflowAxis] is [Axis.vertical], the menu will be expanded vertically.
  /// If [overflowAxis] is [Axis.horizontal], then the menu will be
  /// expanded horizontally.
  ///
  /// Defaults to [Axis.horizontal].
  final Axis overflowAxis;

  /// The widget displayed in the center of this button.
  ///
  /// Typically this is the button's label, using a [Text] widget.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  /// Whether the button is enabled or disabled.
  ///
  /// To enable a button, set its [onPressed] property to a non-null value.
  bool get enabled => onPressed != null;

  @override
  State<CustomMenuItemButton> createState() => _CustomMenuItemButtonState();

  /// Defines the button's default appearance.
  ///
  /// {@macro flutter.material.text_button.default_style_of}
  ///
  /// {@macro flutter.material.text_button.material3_defaults}
  ButtonStyle defaultStyleOf(BuildContext context) {
    return _MenuButtonDefaultsM3(context);
  }

  /// Returns the [MenuButtonThemeData.style] of the closest
  /// [MenuButtonTheme] ancestor.
  ButtonStyle? themeStyleOf(BuildContext context) {
    return MenuButtonTheme.of(context).style;
  }

  /// A static convenience method that constructs a [CustomMenuItemButton]'s
  /// [ButtonStyle] given simple values.
  ///
  /// The [foregroundColor] color is used to create a [WidgetStateProperty]
  /// [ButtonStyle.foregroundColor] value. Specify a value for [foregroundColor]
  /// to specify the color of the button's icons. Use [backgroundColor] for the
  /// button's background fill color. Use [disabledForegroundColor] and
  /// [disabledBackgroundColor] to specify the button's disabled icon and fill
  /// color.
  ///
  /// Similarly, the [enabledMouseCursor] and [disabledMouseCursor]
  /// parameters are used to construct [ButtonStyle.mouseCursor].
  ///
  /// The [iconColor], [disabledIconColor] are used to construct
  /// [ButtonStyle.iconColor] and [iconSize] is used to construct
  /// [ButtonStyle.iconSize].
  ///
  /// All of the other parameters are either used directly or used to create a
  /// [WidgetStateProperty] with a single value for all states.
  ///
  /// All parameters default to null, by default this method returns a
  /// [ButtonStyle] that doesn't override anything.
  ///
  /// For example, to override the default foreground color for a
  /// [CustomMenuItemButton], as well as its overlay color, with all of the standard
  /// opacity adjustments for the pressed, focused, and hovered states, one
  /// could write:
  ///
  /// ```dart
  /// MenuItemButton(
  ///   leadingIcon: const Icon(Icons.pets),
  ///   style: MenuItemButton.styleFrom(foregroundColor: Colors.green),
  ///   onPressed: () {
  ///     // ...
  ///   },
  ///   child: const Text('Button Label'),
  /// ),
  /// ```
  static ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    Color? iconColor,
    double? iconSize,
    Color? disabledIconColor,
    TextStyle? textStyle,
    Color? overlayColor,
    double? elevation,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    Size? fixedSize,
    Size? maximumSize,
    MouseCursor? enabledMouseCursor,
    MouseCursor? disabledMouseCursor,
    BorderSide? side,
    OutlinedBorder? shape,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
    Duration? animationDuration,
    bool? enableFeedback,
    AlignmentGeometry? alignment,
    InteractiveInkFeatureFactory? splashFactory,
  }) {
    return TextButton.styleFrom(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      disabledBackgroundColor: disabledBackgroundColor,
      disabledForegroundColor: disabledForegroundColor,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      iconColor: iconColor,
      iconSize: iconSize,
      disabledIconColor: disabledIconColor,
      textStyle: textStyle,
      overlayColor: overlayColor,
      elevation: elevation,
      padding: padding,
      minimumSize: minimumSize,
      fixedSize: fixedSize,
      maximumSize: maximumSize,
      enabledMouseCursor: enabledMouseCursor,
      disabledMouseCursor: disabledMouseCursor,
      side: side,
      shape: shape,
      visualDensity: visualDensity,
      tapTargetSize: tapTargetSize,
      animationDuration: animationDuration,
      enableFeedback: enableFeedback,
      alignment: alignment,
      splashFactory: splashFactory,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('enabled', value: onPressed != null, ifFalse: 'DISABLED'));
    properties.add(DiagnosticsProperty<ButtonStyle?>('style', style, defaultValue: null));
    properties.add(
      DiagnosticsProperty<MenuSerializableShortcut?>('shortcut', shortcut, defaultValue: null),
    );
    properties.add(DiagnosticsProperty<FocusNode?>('focusNode', focusNode, defaultValue: null));
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior, defaultValue: Clip.none));
    properties.add(
      DiagnosticsProperty<MaterialStatesController?>(
        'statesController',
        statesController,
        defaultValue: null,
      ),
    );
  }
}

class _CustomMenuItemButtonState extends State<CustomMenuItemButton> {
  // If a focus node isn't given to the widget, then we have to manage our own.
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;
  _CustomMenuAnchorState? get _anchor => _CustomMenuAnchorState._maybeOf(context);
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _createInternalFocusNodeIfNeeded();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    _internalFocusNode = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(CustomMenuItemButton oldWidget) {
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(_handleFocusChange);
      if (widget.focusNode != null) {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
      _createInternalFocusNodeIfNeeded();
      _focusNode.addListener(_handleFocusChange);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    // Since we don't want to use the theme style or default style from the
    // TextButton, we merge the styles, merging them in the right order when
    // each type of style exists. Each "*StyleOf" function is only called once.
    ButtonStyle mergedStyle =
        widget.themeStyleOf(context)?.merge(widget.defaultStyleOf(context)) ??
        widget.defaultStyleOf(context);
    if (widget.style != null) {
      mergedStyle = widget.style!.merge(mergedStyle);
    }

    Widget child = TextButton(
      onPressed: widget.enabled ? _handleSelect : null,
      onFocusChange: widget.enabled ? widget.onFocusChange : null,
      focusNode: _focusNode,
      style: mergedStyle,
      autofocus: widget.enabled && widget.autofocus,
      statesController: widget.statesController,
      clipBehavior: widget.clipBehavior,
      isSemanticButton: null,
      child: _MenuItemLabel(
        leadingIcon: widget.leadingIcon,
        shortcut: widget.shortcut,
        semanticsLabel: widget.semanticsLabel,
        trailingIcon: widget.trailingIcon,
        hasSubmenu: false,
        overflowAxis: _anchor?._orientation ?? widget.overflowAxis,
        child: widget.child,
      ),
    );

    if (_platformSupportsAccelerators && widget.enabled) {
      child = MenuAcceleratorCallbackBinding(onInvoke: _handleSelect, child: child);
    }

    if (widget.onHover != null || widget.requestFocusOnHover) {
      child = MouseRegion(onHover: _handlePointerHover, onExit: _handlePointerExit, child: child);
    }

    return MergeSemantics(child: child);
  }

  void _handleFocusChange() {
    if (!_focusNode.hasPrimaryFocus) {
      // Close any child menus of this button's menu.
      MenuController.maybeOf(context)?.closeChildren();
    }
  }

  void _handlePointerExit(PointerExitEvent event) {
    if (_isHovered) {
      widget.onHover?.call(false);
      _isHovered = false;
    }
  }

  // TextButton.onHover and MouseRegion.onHover can't be used without triggering
  // focus on scroll.
  void _handlePointerHover(PointerHoverEvent event) {
    if (!_isHovered) {
      _isHovered = true;
      widget.onHover?.call(true);
      if (widget.requestFocusOnHover) {
        assert(_debugMenuInfo('Requesting focus for $_focusNode from hover'));
        _focusNode.requestFocus();

        // Without invalidating the focus policy, switching to directional focus
        // may not originate at this node.
        FocusTraversalGroup.of(context).invalidateScopeData(FocusScope.of(context));
      }
    }
  }

  void _handleSelect() {
    assert(_debugMenuInfo('Selected ${widget.child} menu'));
    if (widget.closeOnActivate) {
      _anchor?._root._menuController.close();
    }
    // Delay the call to onPressed until post-frame so that the focus is
    // restored to what it was before the menu was opened before the action is
    // executed.
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      FocusManager.instance.applyFocusChangesIfNeeded();
      widget.onPressed?.call();
    }, debugLabel: 'MenuAnchor.onPressed');
  }

  void _createInternalFocusNodeIfNeeded() {
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
      assert(() {
        _internalFocusNode?.debugLabel = '$CustomMenuItemButton(${widget.child})';
        return true;
      }());
    }
  }
}

/// A menu button that displays a cascading menu.
///
/// It can be used as part of a [MenuBar], or as a standalone widget.
///
/// This widget represents a menu item that has a submenu. Like the leaf
/// [CustomMenuItemButton], it shows a label with an optional leading or trailing
/// icon, but additionally shows an arrow icon showing that it has a submenu.
///
/// By default the submenu will appear to the side of the controlling button.
/// The alignment and offset of the submenu can be controlled by setting
/// [MenuStyle.alignment] on the [style] and the [alignmentOffset] argument,
/// respectively.
///
/// When activated (by being clicked, through keyboard navigation, or via
/// hovering with a mouse), it will open a submenu containing the
/// [menuChildren].
///
/// If [menuChildren] is empty, then this menu item will appear disabled.
///
/// See also:
///
/// * [CustomMenuItemButton], a widget that represents a leaf menu item that does not
///   host a submenu.
/// * [MenuBar], a widget that renders menu items in a row in a Material Design
///   style.
/// * [CustomMenuAnchor], a widget that creates a region with a submenu and shows it
///   when requested.
/// * [PlatformMenuBar], a widget that renders similar menu bar items from a
///   [PlatformMenuItem] using platform-native APIs instead of Flutter.
class CustomSubmenuButton extends StatefulWidget {
  /// Creates a const [CustomSubmenuButton].
  ///
  /// The [child] and [menuChildren] attributes are required.
  const CustomSubmenuButton({
    super.key,
    this.onSelect,
    this.onHover,
    this.onFocusChange,
    this.onOpen,
    this.onClose,
    this.controller,
    this.style,
    this.menuStyle,
    this.alignmentOffset,
    this.clipBehavior = Clip.hardEdge,
    this.focusNode,
    this.statesController,
    this.leadingIcon,
    this.trailingIcon,
    this.submenuIcon,
    this.useRootOverlay = false,
    required this.menuChildren,
    required this.child,
  });

  final VoidCallback? onSelect;

  /// Called when a pointer enters or exits the button response area.
  ///
  /// The value passed to the callback is true if a pointer has entered this
  /// part of the button and false if a pointer has exited.
  final ValueChanged<bool>? onHover;

  /// Handler called when the focus changes.
  ///
  /// Called with true if this widget's [focusNode] gains focus, and false if it
  /// loses focus.
  final ValueChanged<bool>? onFocusChange;

  /// A callback that is invoked when the menu is opened.
  final VoidCallback? onOpen;

  /// A callback that is invoked when the menu is closed.
  final VoidCallback? onClose;

  /// An optional [MenuController] for this submenu.
  final MenuController? controller;

  /// Customizes this button's appearance.
  ///
  /// Non-null properties of this style override the corresponding properties in
  /// [themeStyleOf] and [defaultStyleOf]. [WidgetStateProperty]s that resolve
  /// to non-null values will similarly override the corresponding
  /// [WidgetStateProperty]s in [themeStyleOf] and [defaultStyleOf].
  ///
  /// Null by default.
  final ButtonStyle? style;

  /// The [MenuStyle] of the menu specified by [menuChildren].
  ///
  /// Defaults to the value of [MenuThemeData.style] of the ambient [MenuTheme].
  final MenuStyle? menuStyle;

  /// The offset of the menu relative to the alignment origin determined by
  /// [MenuStyle.alignment] on the [style] attribute.
  ///
  /// Use this for fine adjustments of the menu placement.
  ///
  /// Defaults to an offset that takes into account the padding of the menu so
  /// that the top starting corner of the first menu item is aligned with the
  /// top of the [CustomMenuAnchor] region.
  final Offset? alignmentOffset;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.material.inkwell.statesController}
  final MaterialStatesController? statesController;

  /// An optional icon to display before the [child].
  final Widget? leadingIcon;

  /// If provided, the widget replaces the default [CustomSubmenuButton] arrow icon.
  ///
  /// Resolves in the following states:
  ///  * [WidgetState.disabled].
  ///  * [WidgetState.hovered].
  ///  * [WidgetState.focused].
  ///
  /// If this is null, then the value of [MenuThemeData.submenuIcon] is used.
  /// If that is also null, then defaults to a right arrow icon with the size
  /// of 24 pixels.
  final MaterialStateProperty<Widget?>? submenuIcon;

  /// An optional icon to display after the [child].
  final Widget? trailingIcon;

  /// {@macro flutter.widgets.RawMenuAnchor.useRootOverlay}
  ///
  /// Defaults to false.
  final bool useRootOverlay;

  /// The list of widgets that appear in the menu when it is opened.
  ///
  /// These can be any widget, but are typically either [CustomMenuItemButton] or
  /// [CustomSubmenuButton] widgets.
  ///
  /// If [menuChildren] is empty, then the button for this menu item will be
  /// disabled.
  final List<Widget> menuChildren;

  /// The widget displayed in the middle portion of this button.
  ///
  /// Typically this is the button's label, using a [Text] widget.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  @override
  State<CustomSubmenuButton> createState() => _CustomSubmenuButtonState();

  /// Defines the button's default appearance.
  ///
  /// {@macro flutter.material.text_button.default_style_of}
  ///
  /// {@macro flutter.material.text_button.material3_defaults}
  ButtonStyle defaultStyleOf(BuildContext context) {
    return _MenuButtonDefaultsM3(context);
  }

  /// Returns the [MenuButtonThemeData.style] of the closest [MenuButtonTheme]
  /// ancestor.
  ButtonStyle? themeStyleOf(BuildContext context) {
    return MenuButtonTheme.of(context).style;
  }

  /// A static convenience method that constructs a [CustomSubmenuButton]'s
  /// [ButtonStyle] given simple values.
  ///
  /// The [foregroundColor] color is used to create a [WidgetStateProperty]
  /// [ButtonStyle.foregroundColor] value. Specify a value for [foregroundColor]
  /// to specify the color of the button's icons. Use [backgroundColor] for the
  /// button's background fill color. Use [disabledForegroundColor] and
  /// [disabledBackgroundColor] to specify the button's disabled icon and fill
  /// color.
  ///
  /// Similarly, the [enabledMouseCursor] and [disabledMouseCursor]
  /// parameters are used to construct [ButtonStyle.mouseCursor].
  ///
  /// The [iconColor], [disabledIconColor] are used to construct
  /// [ButtonStyle.iconColor] and [iconSize] is used to construct
  /// [ButtonStyle.iconSize].
  ///
  /// All of the other parameters are either used directly or used to create a
  /// [WidgetStateProperty] with a single value for all states.
  ///
  /// All parameters default to null, by default this method returns a
  /// [ButtonStyle] that doesn't override anything.
  ///
  /// For example, to override the default foreground color for a
  /// [CustomSubmenuButton], as well as its overlay color, with all of the standard
  /// opacity adjustments for the pressed, focused, and hovered states, one
  /// could write:
  ///
  /// ```dart
  /// SubmenuButton(
  ///   leadingIcon: const Icon(Icons.pets),
  ///   style: SubmenuButton.styleFrom(foregroundColor: Colors.green),
  ///   menuChildren: const <Widget>[ /* ... */ ],
  ///   child: const Text('Button Label'),
  /// ),
  /// ```
  static ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    Color? iconColor,
    double? iconSize,
    Color? disabledIconColor,
    TextStyle? textStyle,
    Color? overlayColor,
    double? elevation,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    Size? fixedSize,
    Size? maximumSize,
    MouseCursor? enabledMouseCursor,
    MouseCursor? disabledMouseCursor,
    BorderSide? side,
    OutlinedBorder? shape,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
    Duration? animationDuration,
    bool? enableFeedback,
    AlignmentGeometry? alignment,
    InteractiveInkFeatureFactory? splashFactory,
  }) {
    return TextButton.styleFrom(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      disabledBackgroundColor: disabledBackgroundColor,
      disabledForegroundColor: disabledForegroundColor,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      iconColor: iconColor,
      disabledIconColor: disabledIconColor,
      iconSize: iconSize,
      textStyle: textStyle,
      overlayColor: overlayColor,
      elevation: elevation,
      padding: padding,
      minimumSize: minimumSize,
      fixedSize: fixedSize,
      maximumSize: maximumSize,
      enabledMouseCursor: enabledMouseCursor,
      disabledMouseCursor: disabledMouseCursor,
      side: side,
      shape: shape,
      visualDensity: visualDensity,
      tapTargetSize: tapTargetSize,
      animationDuration: animationDuration,
      enableFeedback: enableFeedback,
      alignment: alignment,
      splashFactory: splashFactory,
    );
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      ...menuChildren.map<DiagnosticsNode>((Widget child) {
        return child.toDiagnosticsNode();
      }),
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FocusNode?>('focusNode', focusNode));
    properties.add(DiagnosticsProperty<MenuStyle>('menuStyle', menuStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<Offset>('alignmentOffset', alignmentOffset));
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior));
  }
}

class _CustomSubmenuButtonState extends State<CustomSubmenuButton> {
  late final Map<Type, Action<Intent>> actions = <Type, Action<Intent>>{
    DirectionalFocusIntent: _SubmenuDirectionalFocusAction(submenu: this),
  };
  bool _waitingToFocusMenu = false;
  bool _isOpenOnFocusEnabled = true;
  MenuController? _internalMenuController;
  MenuController get _menuController => widget.controller ?? _internalMenuController!;
  _CustomMenuAnchorState? get _parent => _CustomMenuAnchorState._maybeOf(context);
  _CustomMenuAnchorState? get _anchorState => _anchorKey.currentState;
  FocusNode? _internalFocusNode;
  final GlobalKey<_CustomMenuAnchorState> _anchorKey = GlobalKey<_CustomMenuAnchorState>();
  FocusNode get _buttonFocusNode => widget.focusNode ?? _internalFocusNode!;
  bool get _enabled => widget.menuChildren.isNotEmpty;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
      assert(() {
        _internalFocusNode?.debugLabel = '$CustomSubmenuButton(${widget.child})';
        return true;
      }());
    }
    if (widget.controller == null) {
      _internalMenuController = MenuController();
    }
    _buttonFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _buttonFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    _internalFocusNode = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(CustomSubmenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _internalFocusNode?.removeListener(_handleFocusChange);
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      } else {
        oldWidget.focusNode!.removeListener(_handleFocusChange);
      }
      if (widget.focusNode == null) {
        _internalFocusNode ??= FocusNode();
        assert(() {
          _internalFocusNode?.debugLabel = '$CustomSubmenuButton(${widget.child})';
          return true;
        }());
      }
      _buttonFocusNode.addListener(_handleFocusChange);
    }
    if (widget.controller != oldWidget.controller) {
      _internalMenuController = (oldWidget.controller == null) ? null : MenuController();
    }
  }

  @override
  Widget build(BuildContext context) {
    Offset menuPaddingOffset = widget.alignmentOffset ?? Offset.zero;
    final EdgeInsets menuPadding = _computeMenuPadding(context);
    final Axis orientation = _parent?._orientation ?? Axis.vertical;
    // Move the submenu over by the size of the menu padding, so that
    // the first menu item aligns with the submenu button that opens it.
    menuPaddingOffset += switch ((orientation, Directionality.of(context))) {
      (Axis.horizontal, TextDirection.rtl) => Offset(menuPadding.right, 0),
      (Axis.horizontal, TextDirection.ltr) => Offset(-menuPadding.left, 0),
      (Axis.vertical, TextDirection.rtl) => Offset(0, -menuPadding.top),
      (Axis.vertical, TextDirection.ltr) => Offset(0, -menuPadding.top),
    };
    final Set<MaterialState> states = <MaterialState>{
      if (!_enabled) MaterialState.disabled,
      if (_isHovered) MaterialState.hovered,
      if (_buttonFocusNode.hasFocus) MaterialState.focused,
    };
    final Widget submenuIcon =
        widget.submenuIcon?.resolve(states) ??
        MenuTheme.of(context).submenuIcon?.resolve(states) ??
        const Icon(
          Icons.arrow_right, // Automatically switches with text direction.
          size: _kDefaultSubmenuIconSize,
        );

    return Actions(
      actions: actions,
      child: CustomMenuAnchor(
        key: _anchorKey,
        controller: _menuController,
        childFocusNode: _buttonFocusNode,
        alignmentOffset: menuPaddingOffset,
        clipBehavior: widget.clipBehavior,
        onClose: _onClose,
        onOpen: _onOpen,
        style: widget.menuStyle,
        useRootOverlay: widget.useRootOverlay,
        builder: (BuildContext context, MenuController controller, Widget? child) {
          // Since we don't want to use the theme style or default style from the
          // TextButton, we merge the styles, merging them in the right order when
          // each type of style exists. Each "*StyleOf" function is only called
          // once.
          ButtonStyle mergedStyle =
              widget.themeStyleOf(context)?.merge(widget.defaultStyleOf(context)) ??
              widget.defaultStyleOf(context);
          mergedStyle = widget.style?.merge(mergedStyle) ?? mergedStyle;

          void toggleShowMenu() {
            if (!mounted) {
              return;
            }
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          }

          void handlePointerExit(PointerExitEvent event) {
            if (_isHovered) {
              widget.onHover?.call(false);
              _isHovered = false;
            }
          }

          // MouseRegion.onEnter and TextButton.onHover are called
          // if a button is hovered after scrolling. This interferes with
          // focus traversal and scroll position. MouseRegion.onHover avoids
          // this issue.
          void handlePointerHover(PointerHoverEvent event) {
            if (!_isHovered) {
              _isHovered = true;
              widget.onHover?.call(true);
              final _CustomMenuAnchorState root = _CustomMenuAnchorState._maybeOf(context)!._root;
              // Don't open the root menu bar menus on hover unless something else
              // is already open. This means that the user has to first click to
              // open a menu on the menu bar before hovering allows them to traverse
              // it.
              if (root._orientation == Axis.horizontal && !root._menuController.isOpen) {
                return;
              }

              controller.open();
              _buttonFocusNode.requestFocus();
            }
          }

          void handleSelect() {
            _parent?._root._menuController.close();

            // Delay the call to onPressed until post-frame so that the focus is
            // restored to what it was before the menu was opened before the action is
            // executed.
            SchedulerBinding.instance.addPostFrameCallback((Duration _) {
              FocusManager.instance.applyFocusChangesIfNeeded();
              widget.onSelect?.call();
            }, debugLabel: 'MenuAnchor.onPressed');
          }

          child = MergeSemantics(
            child: Semantics(
              expanded: _enabled && controller.isOpen,
              child: TextButton(
                style: mergedStyle,
                focusNode: _buttonFocusNode,
                onFocusChange: _enabled ? widget.onFocusChange : null,
                onPressed: _enabled ? handleSelect : null,
                isSemanticButton: null,
                child: _MenuItemLabel(
                  leadingIcon: widget.leadingIcon,
                  trailingIcon: widget.trailingIcon,
                  hasSubmenu: true,
                  showDecoration: (_parent?._orientation ?? Axis.horizontal) == Axis.vertical,
                  submenuIcon: submenuIcon,
                  child: child,
                ),
              ),
            ),
          );

          if (!_enabled) {
            return child;
          }

          child = MouseRegion(onHover: handlePointerHover, onExit: handlePointerExit, child: child);

          if (_platformSupportsAccelerators) {
            return MenuAcceleratorCallbackBinding(
              onInvoke: toggleShowMenu,
              hasSubmenu: true,
              child: child,
            );
          }

          return child;
        },
        menuChildren: widget.menuChildren,
        child: widget.child,
      ),
    );
  }

  void _onClose() {
    // After closing the children of this submenu, this submenu button will
    // regain focus. Because submenu buttons open on focus, this submenu will
    // immediately reopen. To prevent this from happening, we prevent focus on
    // SubmenuButtons that do not already have focus using the _openOnFocus
    // flag. This flag is reset after one frame.
    if (!_buttonFocusNode.hasFocus) {
      _isOpenOnFocusEnabled = false;
      SchedulerBinding.instance.addPostFrameCallback((Duration timestamp) {
        FocusManager.instance.applyFocusChangesIfNeeded();
        _isOpenOnFocusEnabled = true;
      }, debugLabel: 'MenuAnchor.preventOpenOnFocus');
    }
    widget.onClose?.call();
  }

  void _onOpen() {
    if (!_waitingToFocusMenu) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _buttonFocusNode.requestFocus();
          _waitingToFocusMenu = false;
        }
      }, debugLabel: 'MenuAnchor.focus');
      _waitingToFocusMenu = true;
    }
    setState(() {
      /* Rebuild with updated controller.isOpen value */
    });
    widget.onOpen?.call();
  }

  EdgeInsets _computeMenuPadding(BuildContext context) {
    final MaterialStateProperty<EdgeInsetsGeometry?> insets =
        widget.menuStyle?.padding ??
        MenuTheme.of(context).style?.padding ??
        _MenuDefaultsM3(context).padding!;
    return insets
        .resolve(widget.statesController?.value ?? const <MaterialState>{})!
        .resolve(Directionality.of(context));
  }

  void _handleFocusChange() {
    if (_buttonFocusNode.hasPrimaryFocus) {
      if (!_menuController.isOpen && _isOpenOnFocusEnabled) {
        _menuController.open();
      }
    } else {
      if (!_anchorState!._menuScopeNode.hasFocus && _menuController.isOpen) {
        _menuController.close();
      }
    }
  }
}

class _SubmenuDirectionalFocusAction extends DirectionalFocusAction {
  _SubmenuDirectionalFocusAction({required this.submenu});

  final _CustomSubmenuButtonState submenu;
  _CustomMenuAnchorState? get _parent => submenu._parent;
  _CustomMenuAnchorState? get _anchorState => submenu._anchorState;
  MenuController get _controller => submenu._menuController;

  /// The orientation of the menu that contains this submenu button.
  Axis? get _orientation => _parent?._orientation;

  /// Whether the anchor that intercepted this DirectionalFocusAction is a submenu.
  bool get isSubmenu => submenu._buttonFocusNode.hasPrimaryFocus;
  FocusNode get _button => submenu._buttonFocusNode;

  @override
  void invoke(DirectionalFocusIntent intent) {
    assert(_debugMenuInfo('${intent.direction}: Invoking directional focus intent.'));
    final TextDirection directionality = Directionality.of(submenu.context);
    switch ((_orientation, directionality, intent.direction)) {
      case (Axis.horizontal, TextDirection.ltr, TraversalDirection.left):
      case (Axis.horizontal, TextDirection.rtl, TraversalDirection.right):
        assert(_debugMenuInfo('Moving to previous $MenuBar item'));
        // Focus this MenuBar SubmenuButton, then move focus to the previous focusable
        // MenuBar item.
        _button
          ..requestFocus()
          ..previousFocus();
        return;
      case (Axis.horizontal, TextDirection.ltr, TraversalDirection.right):
      case (Axis.horizontal, TextDirection.rtl, TraversalDirection.left):
        assert(_debugMenuInfo('Moving to next $MenuBar item'));
        // Focus this MenuBar SubmenuButton, then move focus to the next focusable
        // MenuBar item.
        _button
          ..requestFocus()
          ..nextFocus();
        return;
      case (Axis.horizontal, _, TraversalDirection.down):
        if (isSubmenu) {
          // If this is a top-level (horizontal) button in a menubar, focus the
          // first item in this button's submenu.
          _anchorState?._focusFirstMenuItem();
          return;
        }
      case (Axis.horizontal, _, TraversalDirection.up):
        if (isSubmenu) {
          // If this is a top-level (horizontal) button in a menubar, focus the
          // last item in this button's submenu. This makes navigating into
          // upward-oriented submenus more intuitive.
          _anchorState?._focusLastMenuItem();
          return;
        }
      case (Axis.vertical, TextDirection.ltr, TraversalDirection.left):
      case (Axis.vertical, TextDirection.rtl, TraversalDirection.right):
        if (_parent?._parent?._orientation == Axis.horizontal) {
          if (isSubmenu) {
            _parent!.widget.childFocusNode
              ?..requestFocus()
              ..previousFocus();
          } else {
            assert(_debugMenuInfo('Exiting submenu'));
            // MenuBar SubmenuButton => SubmenuButton => child
            // Focus the parent SubmenuButton anchor attached to this child.
            _anchorState?._focusButton();
          }
        } else {
          if (isSubmenu) {
            if (_parent?._parent == null) {
              // Moving in the closing direction while focused on a
              // SubmenuButton within a root MenuAnchor menu should not close
              // the menu.
              return;
            }
            _parent?._focusButton();
            _parent?._menuController.close();
          } else {
            // If focus is not on a submenu button, closing the anchor this item
            // presides in will close the menu and focus the anchor button.
            _controller.close();
          }
          assert(_debugMenuInfo('Exiting submenu'));
        }
        return;
      case (Axis.vertical, TextDirection.ltr, TraversalDirection.right) when isSubmenu:
      case (Axis.vertical, TextDirection.rtl, TraversalDirection.left) when isSubmenu:
        assert(_debugMenuInfo('Entering submenu'));
        if (_controller.isOpen) {
          _anchorState?._focusFirstMenuItem();
        } else {
          _controller.open();
          SchedulerBinding.instance.addPostFrameCallback((Duration timestamp) {
            if (_controller.isOpen) {
              _anchorState?._focusFirstMenuItem();
            }
          });
        }
        return;
      default:
        break;
    }

    Actions.maybeInvoke(submenu.context, intent);
  }
}

/// A helper class used to generate shortcut labels for a
/// [MenuSerializableShortcut] (a subset of the subclasses of
/// [ShortcutActivator]).
///
/// This helper class is typically used by the [CustomMenuItemButton] and
/// [CustomSubmenuButton] classes to display a label for their assigned shortcuts.
///
/// Call [getShortcutLabel] with the [MenuSerializableShortcut] to get a label
/// for it.
///
/// For instance, calling [getShortcutLabel] with `SingleActivator(trigger:
/// LogicalKeyboardKey.keyA, control: true)` would return "⌃ A" on macOS, "Ctrl
/// A" in an US English locale, and "Strg A" in a German locale.
class _LocalizedShortcutLabeler {
  _LocalizedShortcutLabeler._();

  static _LocalizedShortcutLabeler? _instance;

  static final Map<LogicalKeyboardKey, String> _shortcutGraphicEquivalents =
      <LogicalKeyboardKey, String>{
        LogicalKeyboardKey.arrowLeft: '←',
        LogicalKeyboardKey.arrowRight: '→',
        LogicalKeyboardKey.arrowUp: '↑',
        LogicalKeyboardKey.arrowDown: '↓',
        LogicalKeyboardKey.enter: '↵',
      };

  static final Set<LogicalKeyboardKey> _modifiers = <LogicalKeyboardKey>{
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.meta,
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.metaRight,
    LogicalKeyboardKey.shiftRight,
  };

  /// Return the instance for this singleton.
  static _LocalizedShortcutLabeler get instance {
    return _instance ??= _LocalizedShortcutLabeler._();
  }

  // Caches the created shortcut key maps so that creating one of these isn't
  // expensive after the first time for each unique localizations object.
  final Map<MaterialLocalizations, Map<LogicalKeyboardKey, String>> _cachedShortcutKeys =
      <MaterialLocalizations, Map<LogicalKeyboardKey, String>>{};

  /// Returns the label to be shown to the user in the UI when a
  /// [MenuSerializableShortcut] is used as a keyboard shortcut.
  ///
  /// When [defaultTargetPlatform] is [TargetPlatform.macOS] or
  /// [TargetPlatform.iOS], this will return graphical key representations when
  /// it can. For instance, the default [LogicalKeyboardKey.shift] will return
  /// '⇧', and the arrow keys will return arrows. The key
  /// [LogicalKeyboardKey.meta] will show as '⌘', [LogicalKeyboardKey.control]
  /// will show as '˄', and [LogicalKeyboardKey.alt] will show as '⌥'.
  ///
  /// The keys are joined by spaces on macOS and iOS, and by "+" on other
  /// platforms.
  String getShortcutLabel(MenuSerializableShortcut shortcut, MaterialLocalizations localizations) {
    final ShortcutSerialization serialized = shortcut.serializeForMenu();
    final String keySeparator;
    if (_usesSymbolicModifiers) {
      // Use "⌃ ⇧ A" style on macOS and iOS.
      keySeparator = ' ';
    } else {
      // Use "Ctrl+Shift+A" style.
      keySeparator = '+';
    }
    if (serialized.trigger != null) {
      final LogicalKeyboardKey trigger = serialized.trigger!;
      final List<String> modifiers = <String>[
        if (_usesSymbolicModifiers) ...<String>[
          // macOS/iOS platform convention uses this ordering, with ⌘ always last.
          if (serialized.control!) _getModifierLabel(LogicalKeyboardKey.control, localizations),
          if (serialized.alt!) _getModifierLabel(LogicalKeyboardKey.alt, localizations),
          if (serialized.shift!) _getModifierLabel(LogicalKeyboardKey.shift, localizations),
          if (serialized.meta!) _getModifierLabel(LogicalKeyboardKey.meta, localizations),
        ] else ...<String>[
          // This order matches the LogicalKeySet version.
          if (serialized.alt!) _getModifierLabel(LogicalKeyboardKey.alt, localizations),
          if (serialized.control!) _getModifierLabel(LogicalKeyboardKey.control, localizations),
          if (serialized.meta!) _getModifierLabel(LogicalKeyboardKey.meta, localizations),
          if (serialized.shift!) _getModifierLabel(LogicalKeyboardKey.shift, localizations),
        ],
      ];
      String? shortcutTrigger;
      final int logicalKeyId = trigger.keyId;
      if (_shortcutGraphicEquivalents.containsKey(trigger)) {
        shortcutTrigger = _shortcutGraphicEquivalents[trigger];
      } else {
        // Otherwise, look it up, and if we don't have a translation for it,
        // then fall back to the key label.
        shortcutTrigger = _getLocalizedName(trigger, localizations);
        if (shortcutTrigger == null && logicalKeyId & LogicalKeyboardKey.planeMask == 0x0) {
          // If the trigger is a Unicode-character-producing key, then use the
          // character.
          shortcutTrigger = String.fromCharCode(
            logicalKeyId & LogicalKeyboardKey.valueMask,
          ).toUpperCase();
        }
        // Fall back to the key label if all else fails.
        shortcutTrigger ??= trigger.keyLabel;
      }
      return <String>[
        ...modifiers,
        if (shortcutTrigger != null && shortcutTrigger.isNotEmpty) shortcutTrigger,
      ].join(keySeparator);
    } else if (serialized.character != null) {
      final List<String> modifiers = <String>[
        // Character based shortcuts cannot check shifted keys.
        if (_usesSymbolicModifiers) ...<String>[
          // macOS/iOS platform convention uses this ordering, with ⌘ always last.
          if (serialized.control!) _getModifierLabel(LogicalKeyboardKey.control, localizations),
          if (serialized.alt!) _getModifierLabel(LogicalKeyboardKey.alt, localizations),
          if (serialized.meta!) _getModifierLabel(LogicalKeyboardKey.meta, localizations),
        ] else ...<String>[
          // This order matches the LogicalKeySet version.
          if (serialized.alt!) _getModifierLabel(LogicalKeyboardKey.alt, localizations),
          if (serialized.control!) _getModifierLabel(LogicalKeyboardKey.control, localizations),
          if (serialized.meta!) _getModifierLabel(LogicalKeyboardKey.meta, localizations),
        ],
      ];
      return <String>[...modifiers, serialized.character!].join(keySeparator);
    }
    throw UnimplementedError(
      'Shortcut labels for ShortcutActivators that do not implement '
      'MenuSerializableShortcut (e.g. ShortcutActivators other than SingleActivator or '
      'CharacterActivator) are not supported.',
    );
  }

  // Tries to look up the key in an internal table, and if it can't find it,
  // then fall back to the key's keyLabel.
  String? _getLocalizedName(LogicalKeyboardKey key, MaterialLocalizations localizations) {
    // Since this is an expensive table to build, we cache it based on the
    // localization object. There's currently no way to clear the cache, but
    // it's unlikely that more than one or two will be cached for each run, and
    // they're not huge.
    _cachedShortcutKeys[localizations] ??= <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.altGraph: localizations.keyboardKeyAltGraph,
      LogicalKeyboardKey.backspace: localizations.keyboardKeyBackspace,
      LogicalKeyboardKey.capsLock: localizations.keyboardKeyCapsLock,
      LogicalKeyboardKey.channelDown: localizations.keyboardKeyChannelDown,
      LogicalKeyboardKey.channelUp: localizations.keyboardKeyChannelUp,
      LogicalKeyboardKey.delete: localizations.keyboardKeyDelete,
      LogicalKeyboardKey.eject: localizations.keyboardKeyEject,
      LogicalKeyboardKey.end: localizations.keyboardKeyEnd,
      LogicalKeyboardKey.escape: localizations.keyboardKeyEscape,
      LogicalKeyboardKey.fn: localizations.keyboardKeyFn,
      LogicalKeyboardKey.home: localizations.keyboardKeyHome,
      LogicalKeyboardKey.insert: localizations.keyboardKeyInsert,
      LogicalKeyboardKey.numLock: localizations.keyboardKeyNumLock,
      LogicalKeyboardKey.numpad1: localizations.keyboardKeyNumpad1,
      LogicalKeyboardKey.numpad2: localizations.keyboardKeyNumpad2,
      LogicalKeyboardKey.numpad3: localizations.keyboardKeyNumpad3,
      LogicalKeyboardKey.numpad4: localizations.keyboardKeyNumpad4,
      LogicalKeyboardKey.numpad5: localizations.keyboardKeyNumpad5,
      LogicalKeyboardKey.numpad6: localizations.keyboardKeyNumpad6,
      LogicalKeyboardKey.numpad7: localizations.keyboardKeyNumpad7,
      LogicalKeyboardKey.numpad8: localizations.keyboardKeyNumpad8,
      LogicalKeyboardKey.numpad9: localizations.keyboardKeyNumpad9,
      LogicalKeyboardKey.numpad0: localizations.keyboardKeyNumpad0,
      LogicalKeyboardKey.numpadAdd: localizations.keyboardKeyNumpadAdd,
      LogicalKeyboardKey.numpadComma: localizations.keyboardKeyNumpadComma,
      LogicalKeyboardKey.numpadDecimal: localizations.keyboardKeyNumpadDecimal,
      LogicalKeyboardKey.numpadDivide: localizations.keyboardKeyNumpadDivide,
      LogicalKeyboardKey.numpadEnter: localizations.keyboardKeyNumpadEnter,
      LogicalKeyboardKey.numpadEqual: localizations.keyboardKeyNumpadEqual,
      LogicalKeyboardKey.numpadMultiply: localizations.keyboardKeyNumpadMultiply,
      LogicalKeyboardKey.numpadParenLeft: localizations.keyboardKeyNumpadParenLeft,
      LogicalKeyboardKey.numpadParenRight: localizations.keyboardKeyNumpadParenRight,
      LogicalKeyboardKey.numpadSubtract: localizations.keyboardKeyNumpadSubtract,
      LogicalKeyboardKey.pageDown: localizations.keyboardKeyPageDown,
      LogicalKeyboardKey.pageUp: localizations.keyboardKeyPageUp,
      LogicalKeyboardKey.power: localizations.keyboardKeyPower,
      LogicalKeyboardKey.powerOff: localizations.keyboardKeyPowerOff,
      LogicalKeyboardKey.printScreen: localizations.keyboardKeyPrintScreen,
      LogicalKeyboardKey.scrollLock: localizations.keyboardKeyScrollLock,
      LogicalKeyboardKey.select: localizations.keyboardKeySelect,
      LogicalKeyboardKey.space: localizations.keyboardKeySpace,
    };
    return _cachedShortcutKeys[localizations]![key];
  }

  String _getModifierLabel(LogicalKeyboardKey modifier, MaterialLocalizations localizations) {
    assert(_modifiers.contains(modifier), '${modifier.keyLabel} is not a modifier key');
    if (modifier == LogicalKeyboardKey.meta ||
        modifier == LogicalKeyboardKey.metaLeft ||
        modifier == LogicalKeyboardKey.metaRight) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          return localizations.keyboardKeyMeta;
        case TargetPlatform.windows:
          return localizations.keyboardKeyMetaWindows;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return '⌘';
      }
    }
    if (modifier == LogicalKeyboardKey.alt ||
        modifier == LogicalKeyboardKey.altLeft ||
        modifier == LogicalKeyboardKey.altRight) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          return localizations.keyboardKeyAlt;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return '⌥';
      }
    }
    if (modifier == LogicalKeyboardKey.control ||
        modifier == LogicalKeyboardKey.controlLeft ||
        modifier == LogicalKeyboardKey.controlRight) {
      // '⎈' (a boat helm wheel, not an asterisk) is apparently the standard
      // icon for "control", but only seems to appear on the French Canadian
      // keyboard. A '✲' (an open center asterisk) appears on some Microsoft
      // keyboards. For all but macOS (which has standardized on "⌃", it seems),
      // we just return the local translation of "Ctrl".
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          return localizations.keyboardKeyControl;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return '⌃';
      }
    }
    if (modifier == LogicalKeyboardKey.shift ||
        modifier == LogicalKeyboardKey.shiftLeft ||
        modifier == LogicalKeyboardKey.shiftRight) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          return localizations.keyboardKeyShift;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return '⇧';
      }
    }
    throw ArgumentError('Keyboard key ${modifier.keyLabel} is not a modifier.');
  }
}

/// MenuBar-specific private specialization of [CustomMenuAnchor] so that it can act
/// differently in regards to orientation, how open works, and what gets built.
class _MenuBarAnchor extends CustomMenuAnchor {
  const _MenuBarAnchor({
    required super.menuChildren,
    super.controller,
    super.clipBehavior,
    super.style,
  });

  @override
  State<CustomMenuAnchor> createState() => _MenuBarAnchorState();
}

class _MenuBarAnchorState extends _CustomMenuAnchorState {
  late final Map<Type, Action<Intent>> actions = <Type, Action<Intent>>{
    DismissIntent: DismissMenuAction(controller: _menuController),
  };

  @override
  Axis get _orientation => Axis.horizontal;

  @override
  Widget build(BuildContext context) {
    final Actions child = Actions(
      actions: actions,
      child: Shortcuts(
        shortcuts: _kMenuTraversalShortcuts,
        child: _MenuPanel(
          menuStyle: widget.style,
          clipBehavior: widget.clipBehavior,
          orientation: _orientation,
          children: widget.menuChildren,
        ),
      ),
    );
    return _MenuAnchorScope(
      state: this,
      child: RawMenuAnchorGroup(
        controller: _menuController,
        child: Builder(
          builder: (BuildContext context) {
            final bool isOpen = MenuController.maybeIsOpenOf(context) ?? false;
            return FocusScope(
              node: _menuScopeNode,
              skipTraversal: !isOpen,
              canRequestFocus: isOpen,
              descendantsAreFocusable: true,
              child: ExcludeFocus(excluding: !isOpen, child: child),
            );
          },
        ),
      ),
    );
  }
}

/// A label widget that is used as the label for a [CustomMenuItemButton] or
/// [CustomSubmenuButton].
///
/// It not only shows the [CustomSubmenuButton.child] or [CustomMenuItemButton.child], but if
/// there is a shortcut associated with the [CustomMenuItemButton], it will display a
/// mnemonic for the shortcut. For [CustomSubmenuButton]s, it will display a visual
/// indicator that there is a submenu.
class _MenuItemLabel extends StatelessWidget {
  /// Creates a const [_MenuItemLabel].
  ///
  /// The [child] and [hasSubmenu] arguments are required.
  const _MenuItemLabel({
    required this.hasSubmenu,
    this.showDecoration = true,
    this.leadingIcon,
    this.trailingIcon,
    this.shortcut,
    this.semanticsLabel,
    this.overflowAxis = Axis.vertical,
    this.submenuIcon,
    this.child,
  });

  /// Whether or not this menu has a submenu.
  ///
  /// Determines whether the submenu arrow is shown or not.
  final bool hasSubmenu;

  /// Whether or not this item should show decorations like shortcut labels or
  /// submenu arrows. Items in a [MenuBar] don't show these decorations when
  /// they are laid out horizontally.
  final bool showDecoration;

  /// The optional icon that comes before the [child].
  final Widget? leadingIcon;

  /// The optional icon that comes after the [child].
  final Widget? trailingIcon;

  /// The shortcut for this label, so that it can generate a string describing
  /// the shortcut.
  final MenuSerializableShortcut? shortcut;

  /// An optional Semantics label, which replaces the generated string when
  /// read by a screen reader.
  final String? semanticsLabel;

  /// The direction in which the menu item expands.
  final Axis overflowAxis;

  /// The submenu icon that is displayed when [showDecoration] and [hasSubmenu] are true.
  final Widget? submenuIcon;

  /// An optional child widget that is displayed in the label.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final VisualDensity density = Theme.of(context).visualDensity;
    final double horizontalPadding = math.max(
      _kLabelItemMinSpacing,
      _kLabelItemDefaultSpacing + density.horizontal * 2,
    );
    Widget leadings;
    if (overflowAxis == Axis.vertical) {
      leadings = Expanded(
        child: ClipRect(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (leadingIcon != null) leadingIcon!,
              if (child != null)
                Expanded(
                  child: ClipRect(
                    child: Padding(
                      padding: leadingIcon != null
                          ? EdgeInsetsDirectional.only(start: horizontalPadding)
                          : EdgeInsets.zero,
                      child: child,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      leadings = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (leadingIcon != null) leadingIcon!,
          if (child != null)
            Padding(
              padding: leadingIcon != null
                  ? EdgeInsetsDirectional.only(start: horizontalPadding)
                  : EdgeInsets.zero,
              child: child,
            ),
        ],
      );
    }

    Widget menuItemLabel = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        leadings,
        if (trailingIcon != null)
          Padding(
            padding: EdgeInsetsDirectional.only(start: horizontalPadding),
            child: trailingIcon,
          ),
        if (showDecoration && shortcut != null)
          Padding(
            padding: EdgeInsetsDirectional.only(start: horizontalPadding),
            child: Text(
              _LocalizedShortcutLabeler.instance.getShortcutLabel(
                shortcut!,
                MaterialLocalizations.of(context),
              ),
            ),
          ),
        if (showDecoration && hasSubmenu)
          Padding(
            padding: EdgeInsetsDirectional.only(start: horizontalPadding),
            child: submenuIcon,
          ),
      ],
    );
    if (semanticsLabel != null) {
      menuItemLabel = Semantics(
        label: semanticsLabel,
        excludeSemantics: true,
        child: menuItemLabel,
      );
    }
    return menuItemLabel;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<MenuSerializableShortcut>('shortcut', shortcut, defaultValue: null),
    );
    properties.add(DiagnosticsProperty<bool>('hasSubmenu', hasSubmenu));
    properties.add(DiagnosticsProperty<bool>('showDecoration', showDecoration));
  }
}

// Positions the menu in the view while trying to keep as much as possible
// visible in the view.
class _MenuLayout extends SingleChildLayoutDelegate {
  const _MenuLayout({
    required this.anchorRect,
    required this.textDirection,
    required this.alignment,
    required this.alignmentOffset,
    required this.menuPosition,
    required this.menuPadding,
    required this.avoidBounds,
    required this.orientation,
    required this.parentOrientation,
  });

  // Rectangle of underlying button, relative to the overlay's dimensions.
  final Rect anchorRect;

  // Whether to prefer going to the left or to the right.
  final TextDirection textDirection;

  // The alignment to use when finding the ideal location for the menu.
  final AlignmentGeometry alignment;

  // The offset from the alignment position to find the ideal location for the
  // menu.
  final Offset alignmentOffset;

  // The position passed to the open method, if any.
  final Offset? menuPosition;

  // The padding on the inside of the menu, so it can be accounted for when
  // positioning.
  final EdgeInsetsGeometry menuPadding;

  // List of rectangles that we should avoid overlapping. Unusable screen area.
  final Set<Rect> avoidBounds;

  // The orientation of this menu.
  final Axis orientation;

  // The orientation of this menu's parent.
  final Axis parentOrientation;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // The menu can be at most the size of the overlay minus _kMenuViewPadding
    // pixels in each direction.
    return BoxConstraints.loose(
      constraints.biggest,
    ).deflate(const EdgeInsets.all(_kMenuViewPadding));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // size: The size of the overlay.
    // childSize: The size of the menu, when fully open, as determined by
    // getConstraintsForChild.
    final Rect overlayRect = Offset.zero & size;
    double x;
    double y;
    if (menuPosition == null) {
      Offset desiredPosition = alignment.resolve(textDirection).withinRect(anchorRect);
      final Offset directionalOffset;
      if (alignment is AlignmentDirectional) {
        directionalOffset = switch (textDirection) {
          TextDirection.rtl => Offset(-alignmentOffset.dx, alignmentOffset.dy),
          TextDirection.ltr => alignmentOffset,
        };
      } else {
        directionalOffset = alignmentOffset;
      }
      desiredPosition += directionalOffset;
      x = desiredPosition.dx;
      y = desiredPosition.dy;
      switch (textDirection) {
        case TextDirection.rtl:
          x -= childSize.width;
        case TextDirection.ltr:
          break;
      }
    } else {
      final Offset adjustedPosition = menuPosition! + anchorRect.topLeft;
      x = adjustedPosition.dx;
      y = adjustedPosition.dy;
    }

    final Iterable<Rect> subScreens = DisplayFeatureSubScreen.subScreensInBounds(
      overlayRect,
      avoidBounds,
    );
    final Rect allowedRect = _closestScreen(subScreens, anchorRect.center);
    bool offLeftSide(double x) => x < allowedRect.left;
    bool offRightSide(double x) => x + childSize.width > allowedRect.right;
    bool offTop(double y) => y < allowedRect.top;
    bool offBottom(double y) => y + childSize.height > allowedRect.bottom;
    // Avoid going outside an area defined as the rectangle offset from the
    // edge of the screen by the button padding. If the menu is off of the screen,
    // move the menu to the other side of the button first, and then if it
    // doesn't fit there, then just move it over as much as needed to make it
    // fit.
    if (childSize.width >= allowedRect.width) {
      // It just doesn't fit, so put as much on the screen as possible.
      x = allowedRect.left;
    } else {
      if (offLeftSide(x)) {
        // If the parent is a different orientation than the current one, then
        // just push it over instead of trying the other side.
        if (parentOrientation != orientation) {
          x = allowedRect.left;
        } else {
          final double newX = anchorRect.right + alignmentOffset.dx;
          if (!offRightSide(newX)) {
            x = newX;
          } else {
            x = allowedRect.left;
          }
        }
      } else if (offRightSide(x)) {
        if (parentOrientation != orientation) {
          x = allowedRect.right - childSize.width;
        } else {
          final double newX = anchorRect.left - childSize.width - alignmentOffset.dx;
          if (!offLeftSide(newX)) {
            x = newX;
          } else {
            x = allowedRect.right - childSize.width;
          }
        }
      }
    }
    if (childSize.height >= allowedRect.height) {
      // Too tall to fit, fit as much on as possible.
      y = allowedRect.top;
    } else {
      if (offTop(y)) {
        final double newY = anchorRect.bottom;
        if (!offBottom(newY)) {
          y = newY;
        } else {
          y = allowedRect.top;
        }
      } else if (offBottom(y)) {
        final double newY = anchorRect.top - childSize.height;
        if (!offTop(newY)) {
          // Only move the menu up if its parent is horizontal (MenuAnchor/MenuBar).
          if (parentOrientation == Axis.horizontal) {
            y = newY - alignmentOffset.dy;
          } else {
            y = newY;
          }
        } else {
          y = allowedRect.bottom - childSize.height;
        }
      }
    }
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_MenuLayout oldDelegate) {
    return anchorRect != oldDelegate.anchorRect ||
        textDirection != oldDelegate.textDirection ||
        alignment != oldDelegate.alignment ||
        alignmentOffset != oldDelegate.alignmentOffset ||
        menuPosition != oldDelegate.menuPosition ||
        menuPadding != oldDelegate.menuPadding ||
        orientation != oldDelegate.orientation ||
        parentOrientation != oldDelegate.parentOrientation ||
        !setEquals(avoidBounds, oldDelegate.avoidBounds);
  }

  Rect _closestScreen(Iterable<Rect> screens, Offset point) {
    Rect closest = screens.first;
    for (final Rect screen in screens) {
      if ((screen.center - point).distance < (closest.center - point).distance) {
        closest = screen;
      }
    }
    return closest;
  }
}

/// A widget that manages a list of menu buttons in a menu.
///
/// It sizes itself to the widest/tallest item it contains, and then sizes all
/// the other entries to match.
class _MenuPanel extends StatefulWidget {
  const _MenuPanel({
    required this.menuStyle,
    this.clipBehavior = Clip.none,
    required this.orientation,
    this.crossAxisUnconstrained = true,
    required this.children,
  });

  /// The menu style that has all the attributes for this menu panel.
  final MenuStyle? menuStyle;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// Determine if a [UnconstrainedBox] can be applied to the menu panel to allow it to render
  /// at its "natural" size.
  ///
  /// Defaults to true. When it is set to false, it can be useful when the menu should
  /// be constrained in both main-axis and cross-axis, such as a [DropdownMenu].
  final bool crossAxisUnconstrained;

  /// The layout orientation of this panel.
  final Axis orientation;

  /// The list of widgets to use as children of this menu panel.
  ///
  /// These are the top level [CustomSubmenuButton]s.
  final List<Widget> children;

  @override
  State<_MenuPanel> createState() => _MenuPanelState();
}

class _MenuPanelState extends State<_MenuPanel> {
  ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (MenuStyle? themeStyle, MenuStyle defaultStyle) = switch (widget.orientation) {
      Axis.horizontal => (MenuBarTheme.of(context).style, _MenuBarDefaultsM3(context)),
      Axis.vertical => (MenuTheme.of(context).style, _MenuDefaultsM3(context)),
    };
    final MenuStyle? widgetStyle = widget.menuStyle;

    T? effectiveValue<T>(T? Function(MenuStyle? style) getProperty) {
      return getProperty(widgetStyle) ?? getProperty(themeStyle) ?? getProperty(defaultStyle);
    }

    T? resolve<T>(MaterialStateProperty<T>? Function(MenuStyle? style) getProperty) {
      return effectiveValue((MenuStyle? style) {
        return getProperty(style)?.resolve(<MaterialState>{});
      });
    }

    final Color? backgroundColor = resolve<Color?>((MenuStyle? style) => style?.backgroundColor);
    final Color? shadowColor = resolve<Color?>((MenuStyle? style) => style?.shadowColor);
    final Color? surfaceTintColor = resolve<Color?>((MenuStyle? style) => style?.surfaceTintColor);
    final double elevation = resolve<double?>((MenuStyle? style) => style?.elevation) ?? 0;
    final Size? minimumSize = resolve<Size?>((MenuStyle? style) => style?.minimumSize);
    final Size? fixedSize = resolve<Size?>((MenuStyle? style) => style?.fixedSize);
    final Size? maximumSize = resolve<Size?>((MenuStyle? style) => style?.maximumSize);
    final BorderSide? side = resolve<BorderSide?>((MenuStyle? style) => style?.side);
    final OutlinedBorder shape = resolve<OutlinedBorder?>(
      (MenuStyle? style) => style?.shape,
    )!.copyWith(side: side);
    final VisualDensity visualDensity =
        effectiveValue((MenuStyle? style) => style?.visualDensity) ?? VisualDensity.standard;
    final EdgeInsetsGeometry padding =
        resolve<EdgeInsetsGeometry?>((MenuStyle? style) => style?.padding) ?? EdgeInsets.zero;
    final Offset densityAdjustment = visualDensity.baseSizeAdjustment;
    // Per the Material Design team: don't allow the VisualDensity
    // adjustment to reduce the width of the left/right padding. If we
    // did, VisualDensity.compact, the default for desktop/web, would
    // reduce the horizontal padding to zero.
    final double dy = densityAdjustment.dy;
    final double dx = math.max(0, densityAdjustment.dx);
    final EdgeInsetsGeometry resolvedPadding = padding
        .add(EdgeInsets.symmetric(horizontal: dx, vertical: dy))
        .clamp(EdgeInsets.zero, EdgeInsetsGeometry.infinity);

    BoxConstraints effectiveConstraints = visualDensity.effectiveConstraints(
      BoxConstraints(
        minWidth: minimumSize?.width ?? 0,
        minHeight: minimumSize?.height ?? 0,
        maxWidth: maximumSize?.width ?? double.infinity,
        maxHeight: maximumSize?.height ?? double.infinity,
      ),
    );
    if (fixedSize != null) {
      final Size size = effectiveConstraints.constrain(fixedSize);
      if (size.width.isFinite) {
        effectiveConstraints = effectiveConstraints.copyWith(
          minWidth: size.width,
          maxWidth: size.width,
        );
      }
      if (size.height.isFinite) {
        effectiveConstraints = effectiveConstraints.copyWith(
          minHeight: size.height,
          maxHeight: size.height,
        );
      }
    }

    // If the menu panel is horizontal, then the children should be wrapped in
    // an IntrinsicWidth widget to ensure that the children are as wide as the
    // widest child.
    List<Widget> children = widget.children;
    if (widget.orientation == Axis.horizontal) {
      children = children.map<Widget>((Widget child) {
        return IntrinsicWidth(child: child);
      }).toList();
    }

    Widget menuPanel = _intrinsicCrossSize(
      child: Material(
        elevation: elevation,
        shape: shape,
        color: backgroundColor,
        shadowColor: shadowColor,
        surfaceTintColor: surfaceTintColor,
        type: backgroundColor == null ? MaterialType.transparency : MaterialType.canvas,
        clipBehavior: widget.clipBehavior,
        child: Padding(
          padding: resolvedPadding,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
              overscroll: false,
              physics: const ClampingScrollPhysics(),
            ),
            child: PrimaryScrollController(
              controller: scrollController,
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: scrollController,
                  scrollDirection: widget.orientation,
                  child: Flex(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: Directionality.of(context),
                    direction: widget.orientation,
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.crossAxisUnconstrained) {
      menuPanel = UnconstrainedBox(
        constrainedAxis: widget.orientation,
        clipBehavior: Clip.hardEdge,
        alignment: AlignmentDirectional.centerStart,
        child: menuPanel,
      );
    }

    return ConstrainedBox(constraints: effectiveConstraints, child: menuPanel);
  }

  Widget _intrinsicCrossSize({required Widget child}) {
    return switch (widget.orientation) {
      Axis.horizontal => IntrinsicHeight(child: child),
      Axis.vertical => IntrinsicWidth(child: child),
    };
  }
}

// A widget that defines the menu drawn in the overlay.
class _Submenu extends StatelessWidget {
  const _Submenu({
    required this.anchor,
    required this.layerLink,
    required this.menuStyle,
    required this.menuPosition,
    required this.alignmentOffset,
    required this.consumeOutsideTaps,
    required this.clipBehavior,
    this.crossAxisUnconstrained = true,
    required this.menuChildren,
    required this.menuScopeNode,
  });

  final FocusScopeNode menuScopeNode;
  final RawMenuOverlayInfo menuPosition;
  final _CustomMenuAnchorState anchor;
  final LayerLink? layerLink;
  final MenuStyle? menuStyle;
  final bool consumeOutsideTaps;
  final Offset alignmentOffset;
  final Clip clipBehavior;
  final bool crossAxisUnconstrained;
  final List<Widget> menuChildren;

  @override
  Widget build(BuildContext context) {
    // Use the text direction of the context where the button is.
    final TextDirection textDirection = Directionality.of(context);
    final (MenuStyle? themeStyle, MenuStyle defaultStyle) = switch (anchor._parent?._orientation) {
      Axis.horizontal || null => (MenuBarTheme.of(context).style, _MenuBarDefaultsM3(context)),
      Axis.vertical => (MenuTheme.of(context).style, _MenuDefaultsM3(context)),
    };
    T? effectiveValue<T>(T? Function(MenuStyle? style) getProperty) {
      return getProperty(menuStyle) ?? getProperty(themeStyle) ?? getProperty(defaultStyle);
    }

    T? resolve<T>(MaterialStateProperty<T>? Function(MenuStyle? style) getProperty) {
      return effectiveValue((MenuStyle? style) {
        return getProperty(style)?.resolve(<MaterialState>{});
      });
    }

    final MaterialStateMouseCursor mouseCursor = _MouseCursor(
      (Set<MaterialState> states) =>
          effectiveValue((MenuStyle? style) => style?.mouseCursor?.resolve(states)),
    );

    final VisualDensity visualDensity =
        effectiveValue((MenuStyle? style) => style?.visualDensity) ??
        Theme.of(context).visualDensity;
    final AlignmentGeometry alignment = effectiveValue((MenuStyle? style) => style?.alignment)!;
    final EdgeInsetsGeometry padding =
        resolve<EdgeInsetsGeometry?>((MenuStyle? style) => style?.padding) ?? EdgeInsets.zero;
    final Offset densityAdjustment = visualDensity.baseSizeAdjustment;
    // Per the Material Design team: don't allow the VisualDensity
    // adjustment to reduce the width of the left/right padding. If we
    // did, VisualDensity.compact, the default for desktop/web, would
    // reduce the horizontal padding to zero.
    final double dy = densityAdjustment.dy;
    final double dx = math.max(0, densityAdjustment.dx);
    final EdgeInsetsGeometry resolvedPadding = padding
        .add(EdgeInsets.fromLTRB(dx, dy, dx, dy))
        .clamp(EdgeInsets.zero, EdgeInsetsGeometry.infinity);

    final Rect anchorRect = layerLink == null
        ? Rect.fromLTRB(
            menuPosition.anchorRect.left + dx,
            menuPosition.anchorRect.top - dy,
            menuPosition.anchorRect.right,
            menuPosition.anchorRect.bottom,
          )
        : Rect.zero;

    final Widget menuPanel = TapRegion(
      groupId: menuPosition.tapRegionGroupId,
      consumeOutsideTaps: anchor._root._menuController.isOpen && anchor.widget.consumeOutsideTap,
      onTapOutside: (PointerDownEvent event) {
        anchor._menuController.close();
      },
      child: MouseRegion(
        cursor: mouseCursor,
        hitTestBehavior: HitTestBehavior.deferToChild,
        child: FocusScope(
          node: anchor._menuScopeNode,
          skipTraversal: true,
          child: Actions(
            actions: <Type, Action<Intent>>{
              DismissIntent: DismissMenuAction(controller: anchor._menuController),
            },
            child: Shortcuts(
              shortcuts: _kMenuTraversalShortcuts,
              child: _MenuPanel(
                menuStyle: menuStyle,
                clipBehavior: clipBehavior,
                orientation: anchor._orientation,
                crossAxisUnconstrained: crossAxisUnconstrained,
                children: menuChildren,
              ),
            ),
          ),
        ),
      ),
    );

    final Widget layout = Theme(
      data: Theme.of(context).copyWith(visualDensity: visualDensity),
      child: ConstrainedBox(
        constraints: BoxConstraints.loose(menuPosition.overlaySize),
        child: Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQuery = MediaQuery.of(context);
            return CustomSingleChildLayout(
              delegate: _MenuLayout(
                anchorRect: anchorRect,
                textDirection: textDirection,
                avoidBounds: DisplayFeatureSubScreen.avoidBounds(mediaQuery).toSet(),
                menuPadding: resolvedPadding,
                alignment: alignment,
                alignmentOffset: alignmentOffset,
                menuPosition: menuPosition.position,
                orientation: anchor._orientation,
                parentOrientation: anchor._parent?._orientation ?? Axis.horizontal,
              ),
              child: menuPanel,
            );
          },
        ),
      ),
    );

    if (layerLink == null) {
      return layout;
    }

    return CompositedTransformFollower(
      link: layerLink!,
      targetAnchor: Alignment.bottomLeft,
      child: layout,
    );
  }
}

/// Wraps the [WidgetStateMouseCursor] so that it can default to
/// [MouseCursor.uncontrolled] if none is set.
class _MouseCursor extends MaterialStateMouseCursor {
  const _MouseCursor(this.resolveCallback);

  final MaterialPropertyResolver<MouseCursor?> resolveCallback;

  @override
  MouseCursor resolve(Set<MaterialState> states) =>
      resolveCallback(states) ?? MouseCursor.uncontrolled;

  @override
  String get debugDescription => 'Menu_MouseCursor';
}

/// A debug print function, which should only be called within an assert, like
/// so:
///
///   assert(_debugMenuInfo('Debug Message'));
///
/// so that the call is entirely removed in release builds.
///
/// Enable debug printing by setting [_kDebugMenus] to true at the top of the
/// file.
bool _debugMenuInfo(String message, [Iterable<String>? details]) {
  assert(() {
    if (_kDebugMenus) {
      debugPrint('MENU: $message');
      if (details != null && details.isNotEmpty) {
        for (final String detail in details) {
          debugPrint('    $detail');
        }
      }
    }
    return true;
  }());
  // Return true so that it can be easily used inside of an assert.
  return true;
}

/// Whether [defaultTargetPlatform] is an Apple platform (Mac or iOS).
bool get _isCupertino {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return true;
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return false;
  }
}

/// Whether [defaultTargetPlatform] is one that uses symbolic shortcuts.
///
/// Mac and iOS use special symbols for modifier keys instead of their names,
/// render them in a particular order defined by Apple's human interface
/// guidelines, and format them so that the modifier keys always align.
bool get _usesSymbolicModifiers {
  return _isCupertino;
}

bool get _platformSupportsAccelerators {
  // On iOS and macOS, pressing the Option key (a.k.a. the Alt key) causes a
  // different set of characters to be generated, and the native menus don't
  // support accelerators anyhow, so we just disable accelerators on these
  // platforms.
  return !_isCupertino;
}

// BEGIN GENERATED TOKEN PROPERTIES - Menu

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

// dart format off
class _MenuBarDefaultsM3 extends MenuStyle {
  _MenuBarDefaultsM3(this.context)
    : super(
      elevation: const MaterialStatePropertyAll<double?>(3.0),
      shape: const MaterialStatePropertyAll<OutlinedBorder>(_defaultMenuBorder),
      alignment: AlignmentDirectional.bottomStart,
    );

  static const RoundedRectangleBorder _defaultMenuBorder =
    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0)));

  final BuildContext context;

  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  MaterialStateProperty<Color?> get backgroundColor {
    return MaterialStatePropertyAll<Color?>(_colors.surfaceContainer);
  }

  @override
  MaterialStateProperty<Color?>? get shadowColor {
    return MaterialStatePropertyAll<Color?>(_colors.shadow);
  }

  @override
  MaterialStateProperty<Color?>? get surfaceTintColor {
    return const MaterialStatePropertyAll<Color?>(Colors.transparent);
  }

  @override
  MaterialStateProperty<EdgeInsetsGeometry?>? get padding {
    return const MaterialStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsetsDirectional.symmetric(
        horizontal: _kTopLevelMenuHorizontalMinPadding
      ),
    );
  }

  @override
  VisualDensity get visualDensity => Theme.of(context).visualDensity;
}

class _MenuButtonDefaultsM3 extends ButtonStyle {
  _MenuButtonDefaultsM3(this.context)
    : super(
      animationDuration: kThemeChangeDuration,
      enableFeedback: true,
      alignment: AlignmentDirectional.centerStart,
    );

  final BuildContext context;

  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  MaterialStateProperty<Color?>? get backgroundColor {
    return ButtonStyleButton.allOrNull<Color>(Colors.transparent);
  }

  // No default shadow color

  // No default surface tint color

  @override
  MaterialStateProperty<double>? get elevation {
    return ButtonStyleButton.allOrNull<double>(0.0);
  }

  @override
  MaterialStateProperty<Color?>? get foregroundColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return _colors.onSurface.withOpacity(0.38);
      }
      if (states.contains(MaterialState.pressed)) {
        return _colors.onSurface;
      }
      if (states.contains(MaterialState.hovered)) {
        return _colors.onSurface;
      }
      if (states.contains(MaterialState.focused)) {
        return _colors.onSurface;
      }
      return _colors.onSurface;
    });
  }

  @override
  MaterialStateProperty<Color?>? get iconColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return _colors.onSurface.withOpacity(0.38);
      }
      if (states.contains(MaterialState.pressed)) {
        return _colors.onSurfaceVariant;
      }
      if (states.contains(MaterialState.hovered)) {
        return _colors.onSurfaceVariant;
      }
      if (states.contains(MaterialState.focused)) {
        return _colors.onSurfaceVariant;
      }
      return _colors.onSurfaceVariant;
    });
  }

  // No default fixedSize

  @override
  MaterialStateProperty<double>? get iconSize {
    return const MaterialStatePropertyAll<double>(24.0);
  }

  @override
  MaterialStateProperty<Size>? get maximumSize {
    return ButtonStyleButton.allOrNull<Size>(Size.infinite);
  }

  @override
  MaterialStateProperty<Size>? get minimumSize {
    return ButtonStyleButton.allOrNull<Size>(const Size(64.0, 48.0));
  }

  @override
  MaterialStateProperty<MouseCursor?>? get mouseCursor {
    return MaterialStateProperty.resolveWith(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return SystemMouseCursors.basic;
        }
        return SystemMouseCursors.click;
      },
    );
  }

  @override
  MaterialStateProperty<Color?>? get overlayColor {
    return MaterialStateProperty.resolveWith(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.pressed)) {
          return _colors.onSurface.withOpacity(0.1);
        }
        if (states.contains(MaterialState.hovered)) {
          return _colors.onSurface.withOpacity(0.08);
        }
        if (states.contains(MaterialState.focused)) {
          return _colors.onSurface.withOpacity(0.1);
        }
        return Colors.transparent;
      },
    );
  }

  @override
  MaterialStateProperty<EdgeInsetsGeometry>? get padding {
    return ButtonStyleButton.allOrNull<EdgeInsetsGeometry>(_scaledPadding(context));
  }

  // No default side

  @override
  MaterialStateProperty<OutlinedBorder>? get shape {
    return ButtonStyleButton.allOrNull<OutlinedBorder>(const RoundedRectangleBorder());
  }

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;

  @override
  MaterialTapTargetSize? get tapTargetSize => Theme.of(context).materialTapTargetSize;

  @override
  MaterialStateProperty<TextStyle?> get textStyle {
    // TODO(tahatesser): This is taken from https://m3.material.io/components/menus/specs
    // Update this when the token is available.
    return MaterialStatePropertyAll<TextStyle?>(_textTheme.labelLarge);
  }

  @override
  VisualDensity? get visualDensity => Theme.of(context).visualDensity;

  // The horizontal padding number comes from the spec.
  EdgeInsetsGeometry _scaledPadding(BuildContext context) {
    VisualDensity visualDensity = Theme.of(context).visualDensity;
    // When horizontal VisualDensity is greater than zero, set it to zero
    // because the [ButtonStyleButton] has already handle the padding based on the density.
    // However, the [ButtonStyleButton] doesn't allow the [VisualDensity] adjustment
    // to reduce the width of the left/right padding, so we need to handle it here if
    // the density is less than zero, such as on desktop platforms.
    if (visualDensity.horizontal > 0) {
      visualDensity = VisualDensity(vertical: visualDensity.vertical);
    }
    // Since the threshold paddings used below are empirical values determined
    // at a font size of 14.0, 14.0 is used as the base value for scaling the
    // padding.
    final double fontSize = Theme.of(context).textTheme.labelLarge?.fontSize ?? 14.0;
    final double fontSizeRatio = MediaQuery.textScalerOf(context).scale(fontSize) / 14.0;
    return ButtonStyleButton.scaledPadding(
      EdgeInsets.symmetric(horizontal: math.max(
        _kMenuViewPadding,
        _kLabelItemDefaultSpacing + visualDensity.baseSizeAdjustment.dx,
      )),
      EdgeInsets.symmetric(horizontal: math.max(
        _kMenuViewPadding,
        8 + visualDensity.baseSizeAdjustment.dx,
      )),
      const EdgeInsets.symmetric(horizontal: _kMenuViewPadding),
      fontSizeRatio,
    );
  }
}

class _MenuDefaultsM3 extends MenuStyle {
  _MenuDefaultsM3(this.context)
    : super(
      elevation: const MaterialStatePropertyAll<double?>(3.0),
      shape: const MaterialStatePropertyAll<OutlinedBorder>(_defaultMenuBorder),
      alignment: AlignmentDirectional.topEnd,
    );

  static const RoundedRectangleBorder _defaultMenuBorder =
    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0)));

  final BuildContext context;

  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  MaterialStateProperty<Color?> get backgroundColor {
    return MaterialStatePropertyAll<Color?>(_colors.surfaceContainer);
  }

  @override
  MaterialStateProperty<Color?>? get surfaceTintColor {
    return const MaterialStatePropertyAll<Color?>(Colors.transparent);
  }

  @override
  MaterialStateProperty<Color?>? get shadowColor {
    return MaterialStatePropertyAll<Color?>(_colors.shadow);
  }

  @override
  MaterialStateProperty<EdgeInsetsGeometry?>? get padding {
    return const MaterialStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsetsDirectional.symmetric(vertical: _kMenuVerticalMinPadding),
    );
  }

  @override
  VisualDensity get visualDensity => Theme.of(context).visualDensity;
}
// dart format on

// END GENERATED TOKEN PROPERTIES - Menu
