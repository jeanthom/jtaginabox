using Gtk;

namespace JTAGInABox {
	public class JTAGInABox : Gtk.Application {
		private static JTAGInABox app;
		private JTAGInABoxWindow window = null;

		protected override void activate () {
			// if app is already open
			if (window != null) {
				window.present();
				return;
			}

			try {
				Gtk.CssProvider cssProvider = new Gtk.CssProvider();
				cssProvider.load_from_resource("/css/jtaginabox.css");
				Gdk.Screen screen=Gdk.Screen.get_default();
				Gtk.StyleContext.add_provider_for_screen(screen, cssProvider,
														 Gtk.STYLE_PROVIDER_PRIORITY_USER);
			} catch (GLib.Error e) {
				stderr.printf("Error while loading CSS\n");
			}
			
			window = new JTAGInABoxWindow ();
			window.set_application (this);
			window.delete_event.connect(window.main_quit);
			window.show();
		}

		public static JTAGInABox get_instance () {
			if (app == null) {
				app = new JTAGInABox ();
			}
			
			return app;
		}

		public static int main (string[] args) {
			/* Intl.setlocale (LocaleCategory.ALL, "");
			Intl.bind_textdomain_codeset (Build.GETTEXT_PACKAGE, "UTF-8");
			Intl.textdomain (Build.GETTEXT_PACKAGE); */

			app = new JTAGInABox();
 
			return app.run(args);
		}
	}
}
