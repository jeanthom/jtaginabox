namespace JTAGInABox {
	public class JTAGInABoxWindow : Gtk.Window {
		Gtk.HeaderBar header;
		Gtk.Button previousButton;

		Homepage homepage = null;
		UrJTAG urjtag = null;
		Flashing flashing = null;
		
		public JTAGInABoxWindow() {
			/* Set up window UI */
			this.header = new Gtk.HeaderBar();
			this.header.show_close_button = true;
			this.header.title = "JTAG in a box";
			this.header.show();
			
			this.previousButton = new Gtk.Button.from_icon_name("go-previous-symbolic");
			this.previousButton.clicked.connect(this.action_previous);
			this.header.pack_start(this.previousButton);
			
			this.set_titlebar(this.header);
			
            this.title = "JTAG in a box";
			
			this.set_default_size(640, 480);
			this.window_position = Gtk.WindowPosition.CENTER;

			setup_homepage();
		}
		
		public bool main_quit () {
            this.destroy();

            return false;
        }

		private void setup_homepage() {
			this.homepage = new Homepage();
			this.homepage.action_chosen.connect(this.action_chosen);
			this.add(this.homepage);
			this.homepage.show_all();
			this.previousButton.hide();
		}

		private void setup_urjtag() {
			this.urjtag = new UrJTAG();
			this.urjtag.exited.connect(this.action_previous);
			this.add(this.urjtag);
			this.urjtag.set_terminal_focus(true);
			this.urjtag.show();
			this.previousButton.show();
		}

		private void setup_flashing() {
			this.flashing = new Flashing();
			this.add(this.flashing);
			this.flashing.show();
			this.previousButton.show();
		}

		public void action_chosen(string identifier) {
			if (identifier == "urjtag") {
				this.remove(this.homepage);
				this.homepage.destroy();
				this.homepage = null;
				setup_urjtag();
			} else if (identifier == "flash") {
				this.remove(this.homepage);
				this.homepage.destroy();
				this.homepage = null;
				setup_flashing();				   
			}
		}

		private void action_previous() {
			if (this.urjtag != null) {
				this.remove(this.urjtag);
				this.urjtag.destroy();
				this.urjtag = null;
				setup_homepage();
			} else if (this.flashing != null) {
				this.remove(this.flashing);
				this.flashing.destroy();
				this.flashing = null;
				this.urjtag = null;
				setup_homepage();
			}
		}
	}
}