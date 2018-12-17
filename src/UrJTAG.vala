namespace JTAGInABox {
	public class UrJTAG : Gtk.Overlay {
		Vte.Terminal terminal;
		Gtk.Box vbox;
		const string no_urjtag_error_message = "No UrJTAG executable detected. This might be related to a build or installation problem...";
		const string cable_dirtyjtag_command = "cable dirtyjtag\n";
		
		public signal void exited();
		
		public UrJTAG() {
			Object();

			this.vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			this.add_overlay(this.vbox);
			//this.set_overlay_pass_through(this.vbox, true);

			this.terminal = new Vte.Terminal();

			string? jtag_exec = GLib.Environment.find_program_in_path("jtag");

			stdout.printf("exec file : %s\n", jtag_exec);

			if (jtag_exec != null) {
				try {
					this.terminal.spawn_sync(Vte.PtyFlags.DEFAULT,
											 null,
											 { jtag_exec },
											 null,
											 GLib.SpawnFlags.DO_NOT_REAP_CHILD,
											 null,
											 null
						);
					GLib.Thread<int> usbDetectionThread = new GLib.Thread<int>.try(null, this.usbDetection);
					usbDetectionThread.join();
				} catch(Error e) {
					stderr.printf ("Error: %s\n", e.message);
				}
			} else {
				//this.terminal.feed_child(UrJTAG.no_urjtag_error_message.to_utf8());
				GLib.MainContext.default().invoke(
							() => {
								this.showInfoMessage(UrJTAG.no_urjtag_error_message);
								return GLib.Source.REMOVE;
							});
			}

			this.terminal.child_exited.connect(() => {
					this.exited();
				});

			this.add(this.terminal);
			this.terminal.show();
		}

		private int usbDetection() {
			STLink stlink = new STLink();
			bool dirtyjtagDetected = false;
			int i;

			stdout.printf("Attempting DirtyJTAG detection\n");
					
			if (stlink.detect_vid_pid(0x1209, 0xC0CA)) {
				dirtyjtagDetected = true;
			} else {
				if (stlink.detect_vid_pid(0x0483, 0x3748)) {
					stlink.exit_dfu();

					/* Check every 10ms if DirtyJTAG is detected */
					for (i = 0; i < 100; i++) {
						if (stlink.detect_vid_pid(0x1209, 0xC0CA)) {
							dirtyjtagDetected = true;
							break;
						}
						
						GLib.Thread.usleep(10000);
					}
					
					if (!dirtyjtagDetected) {
						GLib.MainContext.default().invoke(
							() => {
								this.showInfoMessage("Unable to activate DirtyJTAG on your ST-Link dongle. Make sure DirtyJTAG is flashed, and try unplugging it and plugging it back.");
								return GLib.Source.REMOVE;
							});
					}
					
				} else {
					GLib.MainContext.default().invoke(
						() => {
							this.showInfoMessage("No DirtyJTAG device detected");
							return GLib.Source.REMOVE;
						});
				}
			}
			
			if (dirtyjtagDetected) {
				GLib.MainContext.default().invoke(
					() => {
						this.terminal.feed_child(UrJTAG.cable_dirtyjtag_command.to_utf8());
						return GLib.Source.REMOVE;
					});
			}
			
			return 0;
		}

		public void showInfoMessage(string message) {
			Gtk.InfoBar bar = new Gtk.InfoBar();
			bar.message_type = Gtk.MessageType.ERROR;
			bar.show_close_button = true;
			var content = bar.get_content_area();
			Gtk.Label text = new Gtk.Label(message);
			content.add(text);
			this.vbox.add(bar);
			this.vbox.show();
			bar.show_all();
			bar.response.connect((bar, id) => {
					this.vbox.remove(bar);
					bar.hide();
				});
		}

		public void set_terminal_focus(bool focus) {
			this.terminal.has_focus = focus;
		}
	}
}