namespace JTAGInABox {
	public class ActionList : Gtk.Frame {
		Gtk.ListBox listbox = null;

		public signal void action_chosen(string identifier);
		
		public ActionList() {
			Object(label: null);

			this.shadow_type = Gtk.ShadowType.IN;
			this.listbox = new Gtk.ListBox();
			this.listbox.set_activate_on_single_click(true);
			this.listbox.set_selection_mode(Gtk.SelectionMode.NONE);
			this.listbox.row_activated.connect(row_activated);

			this.add(listbox);
		}

		public void add_action(Action action) {
			this.listbox.add(action);
		}

		private void row_activated(Gtk.ListBoxRow row) {
			string identifier = row.get_name();

			if (identifier != null) {
				action_chosen(identifier);
			}
		}
	}

	public class Action : Gtk.ListBoxRow {
		Gtk.Box container = null;
		Gtk.Label actionLabel = null;
		Gtk.Image icon = null;
		
		public Action(string identifier, string action_name, string icon_name) {
			Object();
			
			this.container = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

			this.icon = new Gtk.Image.from_icon_name(icon_name, Gtk.IconSize.DIALOG);
			this.icon.margin = 15;
			this.container.add(this.icon);

			this.actionLabel = new Gtk.Label(action_name);
			this.container.add(this.actionLabel);

			this.add(this.container);
			this.set_name(identifier);
		}
	}

	[GtkTemplate (ui="/ui/Homepage.ui")]
	public class Homepage : Gtk.Box {
		ActionList actionList;
		Action flashAction;
		Action urjtagAction;

		public signal void action_chosen(string identifier);
		
		public Homepage() {
			/* Action list (flash DirtyJTAG, launch UrJTAG) */
			this.actionList = new ActionList();
			this.flashAction = new Action("flash", "Install DirtyJTAG on an ST-Link v2 dongle", "document-save");
			this.urjtagAction = new Action("urjtag", "Launch UrJTAG", "utilities-terminal");
			this.actionList.add_action(this.flashAction);
			this.actionList.add_action(this.urjtagAction);
			this.actionList.action_chosen.connect((identifier) => {
					this.action_chosen(identifier);
				});
			this.add(this.actionList);
		}
	}
}