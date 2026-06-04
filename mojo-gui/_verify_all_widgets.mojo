"""
Verification harness for the widget 0.26 migration.

Importing each widget module's primary struct forces the whole module to
PARSE + typecheck (catching inout/inheritance/alias/str issues). If this file
builds with exit 0, every widget module is migration-clean.
"""

from mojo_src.widgets.accordion_int import AccordionInt
from mojo_src.widgets.advanced_widgets_int import DockPanelInt as AdvDockPanelInt
from mojo_src.widgets.breadcrumb_int import BreadcrumbInt
from mojo_src.widgets.button_int import ButtonInt
from mojo_src.widgets.checkbox_int import CheckboxInt
from mojo_src.widgets.colorpicker_int import ColorPickerInt
from mojo_src.widgets.columnheader_int import ColumnHeaderInt
from mojo_src.widgets.combobox_int import ComboBoxInt
from mojo_src.widgets.container_int import ContainerInt
from mojo_src.widgets.contextmenu_int import ContextMenuInt
from mojo_src.widgets.datetimepicker_int import DateTimePickerInt
from mojo_src.widgets.dialog_int import DialogButtonInt
from mojo_src.widgets.dockpanel_int import DockPanelInt
from mojo_src.widgets.dropdown_int import DropdownInt
from mojo_src.widgets.filedialog_int import FileDialogInt
from mojo_src.widgets.icon_int import IconInt
from mojo_src.widgets.listbox_int import ListItemInt
from mojo_src.widgets.listview_int import ListViewInt
from mojo_src.widgets.menu_int import MenuItemInt
from mojo_src.widgets.navbar_int import NavigationBarInt
from mojo_src.widgets.node_graph_int import PortInt
from mojo_src.widgets.progressbar_int import ProgressBarInt
from mojo_src.widgets.scrollbar_int import ScrollBarInt
from mojo_src.widgets.searchbox_int import SearchBoxInt
from mojo_src.widgets.slider_int import SliderInt
from mojo_src.widgets.source_editor_int import SourceEditorInt
from mojo_src.widgets.spinbox_int import SpinBoxInt
from mojo_src.widgets.statusbar_int import StatusBarInt
from mojo_src.widgets.tabcontrol_int import TabPageInt
from mojo_src.widgets.textedit_int import TextEditInt
from mojo_src.widgets.textlabel_int import TextLabelInt
from mojo_src.widgets.toolbar_int import ToolBarInt
from mojo_src.widgets.treeview_int import TreeViewInt
from mojo_src.widgets.widget_events_int import MouseEventInt


fn main():
    print("widgets ok")
