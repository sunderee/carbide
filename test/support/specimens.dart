// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

/// One representative specimen per component family, shared by the
/// repo-wide sweeps (text scaling #228, RTL crash guard #227, leak
/// tracking #234).
///
/// Export classifications live in `tool/public_surface.json`, checked by
/// `tool/public_surface.py`. Composite families cover their building blocks;
/// the open-state actions below also exercise popup geometry. The host provides
/// an Overlay, MediaQuery, focus traversal and the requested logical viewport.
library;

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'overlay_entries.dart';

/// The registry: family name → specimen builder.
final Map<String, WidgetBuilder> carbideSpecimens = <String, WidgetBuilder>{
  'fluid text': (_) => const SizedBox(
    width: 320,
    child: CarbonFluidText(
      'A responsive quotation in IBM Plex Serif.',
      style: CarbonFluidTypeStyles.quotation01,
    ),
  ),
  'button': (_) =>
      CarbonButton(label: 'Save', icon: CarbonIcons.add, onPressed: () {}),
  'chat button': (_) => CarbonChatButton(
    label: 'Ask a question',
    icon: CarbonIcons.send,
    onPressed: () {},
  ),
  'icon button': (_) => CarbonIconButton(
    icon: CarbonIcons.settings,
    label: 'Settings',
    onPressed: () {},
  ),
  'copy button': (_) => const CarbonCopyButton(value: 'flutter pub add'),
  'link': (_) => CarbonLink(label: 'Learn more', onPressed: () {}),
  'text input': (_) => const SizedBox(
    width: 280,
    child: CarbonTextInput(
      labelText: 'Email',
      placeholder: 'you@example.com',
      helperText: 'Helper',
    ),
  ),
  'text area': (_) => const SizedBox(
    width: 320,
    child: CarbonTextArea(
      labelText: 'Notes',
      placeholder: 'Add context…',
      enableCounter: true,
      maxCount: 200,
    ),
  ),
  'number input': (_) => SizedBox(
    width: 240,
    child: CarbonNumberInput(
      labelText: 'Quantity',
      value: 3,
      min: 0,
      max: 10,
      onChanged: (num? _) {},
    ),
  ),
  'select': (_) => SizedBox(
    width: 280,
    child: CarbonSelect<int>(
      labelText: 'Density',
      value: 1,
      onChanged: (int? _) {},
      items: const <CarbonSelectItem<int>>[
        CarbonSelectItem<int>(value: 0, label: 'Compact'),
        CarbonSelectItem<int>(value: 1, label: 'Normal'),
      ],
    ),
  ),
  'dropdown': (_) => SizedBox(
    width: 280,
    child: CarbonDropdown<int>(
      titleText: 'Theme',
      selectedItem: 0,
      onChanged: (int _) {},
      items: const <CarbonDropdownItem<int>>[
        CarbonDropdownItem<int>(value: 0, label: 'White'),
        CarbonDropdownItem<int>(value: 1, label: 'Gray 100'),
      ],
    ),
  ),
  'combo box': (_) => SizedBox(
    width: 280,
    child: CarbonComboBox<int>(
      titleText: 'City',
      placeholder: 'Choose a city',
      items: const <CarbonComboBoxItem<int>>[
        CarbonComboBoxItem<int>(value: 0, label: 'Berlin'),
        CarbonComboBoxItem<int>(value: 1, label: 'Tallinn'),
      ],
      onChanged: (int? _) {},
    ),
  ),
  'multi select': (_) => SizedBox(
    width: 320,
    child: CarbonMultiSelect<int>(
      titleText: 'Cities',
      label: 'Choose cities',
      selectedValues: const <int>{0, 1},
      items: const <CarbonMultiSelectItem<int>>[
        CarbonMultiSelectItem<int>(value: 0, label: 'Berlin'),
        CarbonMultiSelectItem<int>(value: 1, label: 'Tallinn'),
      ],
      onChanged: (Set<int> _) {},
    ),
  ),
  'filterable multi select': (_) => SizedBox(
    width: 320,
    child: CarbonMultiSelect<int>(
      titleText: 'Cities',
      label: 'Find a city',
      filterable: true,
      items: const <CarbonMultiSelectItem<int>>[
        CarbonMultiSelectItem<int>(value: 0, label: 'Berlin'),
        CarbonMultiSelectItem<int>(value: 1, label: 'Tallinn'),
      ],
      onChanged: (Set<int> _) {},
    ),
  ),
  'time picker': (_) => SizedBox(
    width: 320,
    child: CarbonTimePicker(
      labelText: 'Time',
      initialValue: '12:00',
      children: <Widget>[
        CarbonTimePickerSelect<String>(
          labelText: 'AM/PM',
          width: 120,
          value: 'AM',
          onChanged: (String? _) {},
          items: const <CarbonSelectItem<String>>[
            CarbonSelectItem<String>(value: 'AM', label: 'AM'),
            CarbonSelectItem<String>(value: 'PM', label: 'PM'),
          ],
        ),
      ],
    ),
  ),
  'list box': (_) => const SizedBox(
    width: 280,
    child: CarbonListBox(child: Text('Selected option')),
  ),
  'list box selection count': (_) =>
      CarbonListBoxSelectionCount(count: 12, onClear: () {}),
  'menu': (_) => SizedBox(
    width: 280,
    child: CarbonMenu(
      autofocus: false,
      children: <Widget>[
        const CarbonMenuItem(
          label: 'Open document',
          submenu: <Widget>[CarbonMenuItem(label: 'Open recent document')],
        ),
        CarbonMenuItem(label: 'Close document', onPressed: () {}),
      ],
    ),
  ),
  'search': (_) =>
      const SizedBox(width: 280, child: CarbonSearch(placeholder: 'Find')),
  'checkbox': (_) => const CarbonCheckbox(label: 'Subscribe', value: true),
  'radio group': (_) => CarbonRadioButtonGroup<int>(
    legend: 'Plan',
    value: 1,
    onChanged: (int _) {},
    options: const <(int, String)>[(1, 'Free'), (2, 'Pro')],
  ),
  'toggle': (_) =>
      const CarbonToggle(labelText: 'Notifications', toggled: true),
  'slider': (_) => SizedBox(
    width: 320,
    child: CarbonSlider(
      labelText: 'Amount',
      value: 60,
      min: 0,
      max: 100,
      onChanged: (num _) {},
    ),
  ),
  'tag': (_) => const CarbonTag(label: 'Beta', type: CarbonTagType.blue),
  'dismissible tag': (_) =>
      CarbonDismissibleTag(label: 'Filter', onClose: () {}),
  'accordion': (_) => const SizedBox(
    width: 320,
    child: CarbonAccordion(
      children: <Widget>[
        CarbonAccordionItem(
          title: 'Section',
          initiallyOpen: true,
          child: Text('Body'),
        ),
      ],
    ),
  ),
  'breadcrumb': (_) => CarbonBreadcrumb(
    items: <CarbonBreadcrumbItem>[
      CarbonBreadcrumbItem(label: 'Home', onPressed: () {}),
      const CarbonBreadcrumbItem(label: 'Reports', isCurrentPage: true),
    ],
  ),
  'tabs (contained)': (_) => SizedBox(
    width: 400,
    child: CarbonTabs(
      variant: CarbonTabVariant.contained,
      tabs: const <CarbonTab>[
        CarbonTab(label: 'One'),
        CarbonTab(label: 'Two'),
      ],
      panels: const <Widget>[Text('1'), Text('2')],
    ),
  ),
  'content switcher': (_) => CarbonContentSwitcher(
    selectedIndex: 1,
    onChanged: (int _) {},
    switches: const <CarbonSwitch>[
      CarbonSwitch(text: 'Day'),
      CarbonSwitch(text: 'Week'),
    ],
  ),
  'content switcher (icon-only)': (_) => CarbonContentSwitcher(
    selectedIndex: 1,
    onChanged: (int _) {},
    switches: const <CarbonSwitch>[
      CarbonSwitch(icon: CarbonIcons.list, semanticLabel: 'List view'),
      CarbonSwitch(icon: CarbonIcons.grid, semanticLabel: 'Grid view'),
      CarbonSwitch(
        icon: CarbonIcons.archive,
        semanticLabel: 'Archived view',
        disabled: true,
      ),
    ],
  ),
  'notification': (_) => SizedBox(
    width: 360,
    child: CarbonInlineNotification(
      kind: CarbonNotificationKind.success,
      title: 'Saved',
      subtitle: 'All changes stored.',
      onClose: () {},
    ),
  ),
  'progress bar': (_) => const SizedBox(
    width: 280,
    child: CarbonProgressBar(label: 'Uploading', value: 64),
  ),
  'progress indicator': (_) => const SizedBox(
    width: 480,
    child: CarbonProgressIndicator(
      currentIndex: 1,
      steps: <CarbonProgressStep>[
        CarbonProgressStep(label: 'Account'),
        CarbonProgressStep(label: 'Profile'),
        CarbonProgressStep(label: 'Confirm'),
      ],
    ),
  ),
  // Wide enough for 2.0x labels: pagination grows horizontally under
  // text scaling and the host provides the room (or a horizontal scroll,
  // as the gallery does) — see docs/text-scaling.md.
  'pagination': (_) => SizedBox(
    width: 1200,
    child: CarbonPagination(
      page: 2,
      pageSize: 10,
      totalItems: 248,
      onPageChanged: (int _) {},
      onPageSizeChanged: (int _) {},
    ),
  ),
  'pagination nav': (_) =>
      CarbonPaginationNav(totalItems: 8, page: 2, onChange: (int _) {}),
  'tree view': (_) => const SizedBox(
    width: 260,
    child: CarbonTreeView(
      label: 'Files',
      selectedId: 'a',
      initiallyExpandedIds: <Object>{'src'},
      nodes: <CarbonTreeNode>[
        CarbonTreeNode(
          id: 'src',
          label: 'src',
          children: <CarbonTreeNode>[
            CarbonTreeNode(id: 'a', label: 'main.dart'),
          ],
        ),
      ],
    ),
  ),
  'data table': (_) => const SizedBox(
    // Includes selected-row batch chrome. Chrome's Ahem placeholder is wider
    // than Plex, so the broad sweep supplies the full composition's width;
    // narrow real-font tables are covered by the component/browser contracts.
    width: 760,
    child: CarbonDataTable(
      selection: CarbonTableSelection.multi,
      selectedRows: <int>{0},
      columns: <CarbonTableColumn>[
        CarbonTableColumn(title: 'Name'),
        CarbonTableColumn(title: 'Role'),
      ],
      rows: <CarbonTableRow>[
        CarbonTableRow(cells: <Widget>[Text('Ada'), Text('Admin')]),
        CarbonTableRow(cells: <Widget>[Text('Grace'), Text('Editor')]),
      ],
    ),
  ),
  'structured list': (_) => const SizedBox(
    width: 400,
    child: CarbonStructuredList(
      headers: <String>['Name', 'Type'],
      selectedIndex: 0,
      rows: <CarbonStructuredListRow>[
        CarbonStructuredListRow(cells: <Widget>[Text('Load'), Text('Routine')]),
      ],
    ),
  ),
  'contained list': (_) => SizedBox(
    width: 320,
    child: CarbonContainedList(
      label: const Text('Files'),
      children: <Widget>[
        CarbonContainedListItem(onPressed: () {}, child: const Text('One')),
      ],
    ),
  ),
  'code snippet': (_) => const SizedBox(
    width: 360,
    child: CarbonCodeSnippet(code: 'flutter pub add carbide'),
  ),
  'tile': (_) =>
      const SizedBox(width: 220, child: CarbonTile(child: Text('Base tile'))),
  'side nav': (_) => SizedBox(
    width: 256,
    height: 300,
    child: CarbonSideNav(
      expanded: true,
      items: <Widget>[
        CarbonSideNavLink(
          label: 'Overview',
          icon: CarbonIcons.dashboard,
          current: true,
          onPressed: () {},
        ),
        CarbonSideNavLink(
          label: 'Reports',
          icon: CarbonIcons.document,
          onPressed: () {},
        ),
      ],
    ),
  ),
  'dialog (non-modal)': (_) => SizedBox(
    width: 400,
    height: 320,
    child: Stack(
      children: <Widget>[
        CarbonDialog(
          open: true,
          modal: false,
          onRequestClose: () {},
          children: const <Widget>[
            CarbonDialogHeader(children: <Widget>[Text('Details')]),
            CarbonDialogBody(child: Text('Dialog body copy.')),
          ],
        ),
      ],
    ),
  ),
  'date picker': (_) => SizedBox(
    width: 320,
    child: CarbonDatePicker(labelText: 'Start date', onChanged: (_) {}),
  ),
  'file uploader': (_) => SizedBox(
    width: 320,
    child: CarbonFileUploader(
      labelTitle: 'Attachments',
      labelDescription: 'Choose a document',
      items: <CarbonFileUploaderItem>[
        CarbonFileUploaderItem(name: 'report.pdf', onDelete: () {}),
      ],
      child: CarbonFileUploaderButton(onPressed: () {}),
    ),
  ),
  'page header': (_) => SizedBox(
    width: 760,
    child: CarbonPageHeader(
      title: 'Resource overview',
      body: 'Manage the resources in your project.',
      actions: <CarbonPageHeaderAction>[
        CarbonPageHeaderAction(
          id: 'add',
          label: 'Add resource',
          onPressed: () {},
        ),
      ],
      tags: const <Widget>[CarbonTag(label: 'Production')],
      hero: const ColoredBox(color: Color(0xFF0F62FE)),
      heroDecorative: true,
    ),
  ),
  'form': (_) => const SizedBox(
    width: 320,
    child: CarbonFormGroup(
      legend: 'Contact details',
      child: CarbonFormItem(
        children: <Widget>[
          CarbonFormLabel('Name'),
          CarbonField(child: CarbonText('Ada Lovelace')),
          CarbonHelperText('Enter your full name'),
        ],
      ),
    ),
  ),
  'fluid form': (_) => const SizedBox(
    width: 320,
    child: CarbonFluidForm(child: CarbonTextInput(labelText: 'Name')),
  ),
  'password input': (_) => const SizedBox(
    width: 320,
    child: CarbonPasswordInput(labelText: 'Password'),
  ),
  'table toolbar': (_) => SizedBox(
    width: 600,
    child: CarbonTableToolbar(
      onSearchChanged: (_) {},
      actions: <Widget>[CarbonButton(label: 'Add', onPressed: () {})],
      overflowItems: const <Widget>[CarbonMenuItem(label: 'Settings')],
    ),
  ),
  'ui shell': (_) => SizedBox(
    width: 1200,
    child: CarbonHeader(
      name: const CarbonHeaderName(prefix: 'IBM', name: 'Carbide'),
      navigation: <Widget>[
        CarbonHeaderMenuItem(label: 'Catalog', onPressed: () {}),
        const CarbonHeaderMenu(
          label: 'Resources',
          items: <Widget>[CarbonHeaderMenuItem(label: 'Documentation')],
        ),
      ],
      globalActions: <Widget>[
        CarbonHeaderGlobalAction(
          icon: CarbonIcons.notification,
          label: 'Notifications',
          onPressed: () {},
        ),
      ],
    ),
  ),
  'switcher': (_) => SizedBox(
    width: 256,
    child: CarbonSwitcher(
      children: <Widget>[
        CarbonSwitcherItem(label: 'Product catalog', onPressed: () {}),
        const CarbonSwitcherDivider(),
        CarbonSwitcherItem(label: 'Administration', onPressed: () {}),
      ],
    ),
  ),
  'ai label': (_) => const CarbonAILabel(
    textLabel: 'AI suggested',
    content: Text('Review the suggested content.'),
  ),
  'aspect ratio': (_) => const SizedBox(
    width: 320,
    child: CarbonAspectRatio(
      ratio: CarbonAspectRatioValue.r16x9,
      child: ColoredBox(color: Color(0xFF0F62FE)),
    ),
  ),
  'grid': (_) => const SizedBox(
    width: 760,
    child: CarbonGrid(
      children: <Widget>[
        CarbonColumn(sm: 4, md: 4, lg: 8, child: Text('Main content')),
        CarbonColumn(sm: 4, md: 4, lg: 8, child: Text('Supporting content')),
      ],
    ),
  ),
  'heading': (_) => const CarbonSection(child: CarbonHeading('Overview')),
  'stack': (_) => const CarbonStack(
    gapStep: 5,
    children: <Widget>[Text('First item'), Text('Second item')],
  ),
  'list': (_) => const CarbonOrderedList(
    children: <CarbonListItem>[
      CarbonListItem(child: Text('Create a project')),
      CarbonListItem(child: Text('Invite a collaborator')),
    ],
  ),
  'indicators': (_) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      CarbonBadgeIndicator(),
      CarbonIconIndicator(
        kind: CarbonIconIndicatorKind.succeeded,
        label: 'Ready',
      ),
    ],
  ),
  'loading': (_) => const CarbonInlineLoading(
    status: CarbonInlineLoadingStatus.finished,
    description: 'Upload complete',
  ),
  'skeleton': (_) =>
      const SizedBox(width: 320, child: CarbonSkeletonText(paragraph: true)),
  'text': (_) => const CarbonText('A readable paragraph.'),
  'icon': (_) => const CarbonIcon(CarbonIcons.add, semanticLabel: 'Add'),
  'pictogram': (_) => const CarbonPictogram(
    CarbonPictograms.cloud,
    semanticLabel: 'Cloud services',
  ),
  'layer': (_) =>
      const CarbonLayer(child: CarbonTile(child: Text('Nested surface'))),
  'focus ring': (_) => const CarbonFocusRing(
    visible: true,
    child: Padding(padding: EdgeInsets.all(8), child: Text('Focused content')),
  ),
  'overflow menu': (_) => const CarbonOverflowMenu(
    items: <Widget>[
      CarbonMenuItem(label: 'Edit resource'),
      CarbonMenuItem(label: 'Delete resource'),
    ],
  ),
  'context menu': (_) => const CarbonContextMenu(
    items: <Widget>[CarbonMenuItem(label: 'Copy resource')],
    child: SizedBox(
      width: 320,
      height: 80,
      child: Center(child: Text('Context-menu target')),
    ),
  ),
  'popover': (_) => CarbonPopover(
    open: true,
    autoAlign: true,
    align: CarbonPopoverAlignment.bottomStart,
    content: const Padding(
      padding: EdgeInsets.all(16),
      child: Text('Popover information'),
    ),
    child: CarbonButton(label: 'Popover anchor', onPressed: () {}),
  ),
  'tooltip': (_) => CarbonTooltip(
    label: 'Duplicate this resource',
    defaultOpen: true,
    autoAlign: true,
    child: CarbonButton(label: 'Duplicate', onPressed: () {}),
  ),
  'toggletip': (_) => const CarbonToggletip(
    defaultOpen: true,
    autoAlign: true,
    content: Text('Additional context about this field.'),
  ),
  'modal': (_) => const CarbonModal(
    open: true,
    title: 'Confirm changes',
    passiveModal: true,
    child: Text('Review the details before continuing.'),
  ),
};

/// Actions that reveal a family's overlay before geometry assertions run.
/// The marker is asserted visible, preventing a closed trigger from counting
/// as open-state coverage. Already-open controlled specimens need no action.
final Map<String, (Future<void> Function(WidgetTester)?, Finder)>
carbideOpenSpecimens = <String, (Future<void> Function(WidgetTester)?, Finder)>{
  'dropdown': (
    (tester) => tester.tap(find.text('White')),
    find.text('Gray 100'),
  ),
  'select': ((tester) => tester.tap(find.text('Normal')), find.text('Compact')),
  'combo box': (
    (tester) => tester.tap(find.byType(CarbonListBoxMenuIcon)),
    find.text('Berlin'),
  ),
  'multi select': (
    (tester) => tester.tap(find.text('Choose cities')),
    find.byType(CarbonListBoxMenu),
  ),
  'filterable multi select': (
    (tester) => tester.tap(find.byType(CarbonListBoxMenuIcon)),
    find.text('Berlin'),
  ),
  'date picker': (
    (tester) => tester.tap(find.byType(CarbonDatePicker)),
    find.byType(CarbonCalendar),
  ),
  'time picker': ((tester) => tester.tap(find.text('AM')), find.text('PM')),
  'menu': (
    (tester) => tester.tap(find.text('Open document')),
    find.text('Open recent document'),
  ),
  'overflow menu': (
    (tester) => tester.tap(find.byType(CarbonOverflowMenu)),
    find.text('Edit resource'),
  ),
  'context menu': (
    (tester) => tester.longPress(find.text('Context-menu target')),
    find.text('Copy resource'),
  ),
  'popover': (null, find.text('Popover information')),
  'tooltip': (null, find.text('Duplicate this resource')),
  'toggletip': (null, find.text('Additional context about this field.')),
  'modal': (null, find.text('Confirm changes')),
};

/// Mounts the same logical viewport on the VM and Chrome test engines.
/// Chrome can constrain its physical canvas to 800×600; OverflowBox gives the
/// geometry sweep its declared surface without pretending to check web pixels.
Widget carbideSpecimenHost({
  required Widget child,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
  Size size = const Size(1400, 1000),
}) => Directionality(
  textDirection: direction,
  child: MediaQuery(
    data: MediaQueryData(
      size: size,
      textScaler: TextScaler.linear(scale),
      disableAnimations: true,
    ),
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: OverflowBox(
        minWidth: size.width,
        maxWidth: size.width,
        minHeight: size.height,
        maxHeight: size.height,
        alignment: Alignment.topLeft,
        child: FocusTraversalGroup(
          child: Overlay(
            initialEntries: <OverlayEntry>[
              managedOverlayEntry(
                builder: (_) =>
                    Align(alignment: Alignment.topLeft, child: child),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
