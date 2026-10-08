// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Carbide is an unofficial, independent port of the IBM Carbon Design System.
// It is not affiliated with, endorsed by, or sponsored by IBM. "IBM",
// "Carbon", and "IBM Plex" are trademarks of International Business Machines
// Corporation. Design tokens are derived from the Apache-2.0 licensed Carbon
// Design System; see the NOTICE file for attribution.

/// Carbide — an unofficial Flutter port of the IBM Carbon Design System.
///
/// Carbide is built strictly on `package:flutter/widgets.dart`. It deliberately
/// does not depend on Material or Cupertino: every token, theme, and component
/// is implemented from Flutter's base widgets so the result matches Carbon's
/// specification rather than Material's.
///
/// Public API is exported from this barrel as each layer lands. Foundations
/// (design tokens) are tracked in milestone M1, theming in M2, and components
/// from M4 onward.
library;

// Foundations — design tokens.
export 'src/foundations/colors.dart';
export 'src/foundations/fluid_text_style.dart';
export 'src/foundations/fluid_spacing.dart';
export 'src/foundations/fluid_typography.dart';
export 'src/foundations/fonts.dart';
export 'src/foundations/layout.dart';
export 'src/foundations/motion.dart';
export 'src/foundations/typography.dart';

// Components.
export 'src/components/accordion/carbon_accordion.dart';
export 'src/components/ai_label/carbon_ai_label.dart';
export 'src/components/aspect_ratio/carbon_aspect_ratio.dart';
export 'src/components/breadcrumb/carbon_breadcrumb.dart';
export 'src/components/button/carbon_button.dart';
export 'src/components/button/carbon_button_set.dart';
export 'src/components/chat_button/carbon_chat_button.dart';
export 'src/components/checkbox/carbon_checkbox.dart';
export 'src/components/code_snippet/carbon_code_snippet.dart';
export 'src/components/combo_box/carbon_combo_box.dart';
export 'src/components/contained_list/carbon_contained_list.dart';
export 'src/components/content_switcher/carbon_content_switcher.dart';
export 'src/components/context_menu/carbon_context_menu.dart';
export 'src/components/copy_button/carbon_copy_button.dart';
export 'src/components/form/carbon_form.dart';
export 'src/components/grid/carbon_grid.dart';
export 'src/components/heading/carbon_heading.dart';
export 'src/components/icon_button/carbon_icon_button.dart';
export 'src/components/indicator/carbon_indicators.dart';
export 'src/components/link/carbon_link.dart';
export 'src/components/data_table/carbon_data_table.dart';
export 'src/components/data_table/carbon_table_toolbar.dart';
export 'src/components/date_picker/carbon_date_picker.dart';
export 'src/components/date_picker/date_picker_localizations.dart';
export 'src/components/dialog/carbon_dialog.dart';
export 'src/components/file_uploader/carbon_file_uploader.dart';
export 'src/components/page_header/carbon_page_header.dart';
export 'src/components/time_picker/carbon_time_picker.dart';
export 'src/components/time_picker/time_format.dart';
export 'src/components/tree_view/carbon_tree_view.dart';
export 'src/components/dropdown/carbon_dropdown.dart';
export 'src/components/list/carbon_list.dart';
export 'src/components/list_box/carbon_list_box.dart';
export 'src/components/list_box/list_box_semantics.dart'
    show CarbonListBoxActiveOptionFormatter, carbonListBoxActiveOptionLabel;
export 'src/components/loading/carbon_inline_loading.dart';
export 'src/components/loading/carbon_loading.dart';
export 'src/components/menu/carbon_menu.dart';
export 'src/components/modal/carbon_modal.dart';
export 'src/components/multi_select/carbon_multi_select.dart';
export 'src/components/overflow_menu/carbon_overflow_menu.dart';
export 'src/components/number_input/carbon_number_input.dart';
export 'src/components/notification/carbon_notification.dart';
export 'src/components/popover/carbon_popover.dart';
export 'src/components/pagination/carbon_pagination.dart';
export 'src/components/pagination_nav/carbon_pagination_nav.dart';
export 'src/components/progress_bar/carbon_progress_bar.dart';
export 'src/components/progress_indicator/carbon_progress_indicator.dart';
export 'src/components/radio_button/carbon_radio_button.dart';
export 'src/components/search/carbon_search.dart';
export 'src/components/select/carbon_select.dart';
export 'src/components/slider/carbon_slider.dart';
export 'src/components/skeleton/carbon_ai_skeleton.dart';
export 'src/components/skeleton/carbon_component_skeletons.dart';
export 'src/components/skeleton/carbon_skeleton.dart';
export 'src/components/skeleton/carbon_skeleton_shapes.dart';
export 'src/components/skeleton/carbon_skeleton_text.dart';
export 'src/components/stack/carbon_stack.dart';
export 'src/components/structured_list/carbon_structured_list.dart';
export 'src/components/tag/carbon_interactive_tags.dart';
export 'src/components/tag/carbon_tag.dart';
export 'src/components/tabs/carbon_tabs.dart';
export 'src/components/text/carbon_text.dart';
export 'src/components/text/carbon_fluid_text.dart';
export 'src/components/toggle/carbon_toggle.dart';
export 'src/components/tooltip/carbon_tooltip.dart';
export 'src/components/toggletip/carbon_toggletip.dart';
export 'src/components/ui_shell/carbon_header.dart';
export 'src/components/ui_shell/carbon_side_nav.dart';
export 'src/components/ui_shell/carbon_switcher.dart';
export 'src/components/text_area/carbon_text_area.dart';
export 'src/components/text_input/carbon_text_input.dart';
export 'src/components/tile/carbon_expandable_tile.dart';
export 'src/components/tile/carbon_radio_tile.dart';
export 'src/components/tile/carbon_tile.dart';

// Icons — generated Carbon icon data and the icon widget.
export 'src/icons/carbon_icon.dart';
export 'src/icons/carbon_icon_data.dart';
export 'src/icons/carbon_icon_painter.dart';
export 'src/icons/carbon_icons.dart';

// Pictograms — Carbon's larger expressive illustrations.
export 'src/pictograms/carbon_pictogram.dart';
export 'src/pictograms/carbon_pictograms.dart';

// Theme — semantic token sets and propagation.
export 'src/theme/carbon_layer.dart';
export 'src/theme/carbon_theme.dart';
export 'src/theme/carbon_theme_data.dart';

// Utilities — interaction & styling primitives.
export 'src/utils/focus_ring.dart';
export 'src/utils/interaction.dart';
