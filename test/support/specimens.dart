// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

/// One representative specimen per component family, shared by the
/// repo-wide sweeps (text scaling #228, RTL crash guard #227, leak
/// tracking #234).
///
/// Each entry builds a self-contained, inline-renderable configuration —
/// no Overlay-dependent popups (those components appear via their trigger
/// chrome, which is what a layout sweep can exercise). Keep entries
/// representative rather than exhaustive: one specimen per family, biased
/// toward text-bearing, fixed-height chrome (that is what breaks under
/// scaling and mirroring).
library;

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

/// The registry: family name → specimen builder.
final Map<String, WidgetBuilder> carbideSpecimens = <String, WidgetBuilder>{
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
    width: 420,
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
};
