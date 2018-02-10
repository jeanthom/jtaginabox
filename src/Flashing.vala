namespace JTAGInABox {
	[GtkTemplate (ui="/ui/overlayspinner.ui")]
	public class OverlaySpinner : Gtk.Box {
		[GtkChild] Gtk.Spinner spinner;
		[GtkChild] Gtk.Label info;

		public void set_spinner(bool status) {
			if (status) {
				this.spinner.show();
			} else {
				this.spinner.hide();
			}
		}

		public void set_text(string text) {
			this.info.set_label(text);
		}
	}
	
	[GtkTemplate (ui="/ui/stlinkinfobox.ui")]
	public class STLinkInfoBox : Gtk.Frame {
		[GtkChild] Gtk.Label infos_label;
		
		[GtkChild] Gtk.Label progress_label;
		[GtkChild] Gtk.ProgressBar progress_bar;
		
		[GtkChild] Gtk.Button install_button;

		public signal void install_action();
		
		public STLinkInfoBox() {
			this.install_button.clicked.connect(
				() => {
					this.install_action();
				});
		}

		public void show_buttons(bool active) {
			if (active) {
				this.install_button.show();
			} else {
				this.install_button.hide();
			}
		}

		public void show_progress_bar(bool active) {
			if (active) {
				this.progress_bar.show();
				this.progress_label.show();
			} else {
				this.progress_bar.hide();
				this.progress_label.hide();
			}
		}

		public void set_infos(string serial, string version) {
			this.infos_label.label = "<b>Serial :</b> %s\n<b>Version :</b> %s".printf(serial, version);
		}

		public void set_progress_bar(double level) {
			this.progress_bar.set_fraction(level);
			if (level == 1.0f) {
				this.progress_label.label = "Complete!";
			} else {
				this.progress_label.label = "%02d%%".printf((int)(level * 100));
			}
			this.progress_bar.queue_draw();
		}

		public void set_progress_label(string text) {
			this.progress_label.label = text;
		}
	}
	
	public class Flashing : Gtk.Box {
		STLink* stlink = null;
		STLinkLoader.Context *loader_ctx = null;
		STLinkInfoBox stlinkInfoBox;
		OverlaySpinner overlay_spinner;
		bool should_wait_for_dongle = true;
		
		public Flashing() {
			Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);
			
			this.overlay_spinner = new OverlaySpinner();
			this.overlay_spinner.set_text("Waiting for ST-Link dongle...");
			this.set_center_widget(this.overlay_spinner);

			this.stlink = new STLink();

			this.wait_for_dongle.begin((obj, res) => {
					this.wait_for_dongle.end(res);
				});

			this.destroy.connect(() => {
					this.should_wait_for_dongle = false;
				});
		}

		~Flashing() {
			if (this.stlink != null) {
				delete this.stlink;
			}
			if (this.loader_ctx != null) {
				delete this.loader_ctx;
			}
		}

		private async void wait_for_dongle() {
			new Thread<int>(null, () => {
					while (this.should_wait_for_dongle) {
						if (this.stlink->detect_vid_pid(0x0483, 0x3748)) {
							if (this.stlink->can_claim_vid_pid(0x0483, 0x3748, 0)) {
								GLib.MainContext.default().invoke(
									() => {
										this.should_wait_for_dongle = false;
										this.remove(this.overlay_spinner);
										this.overlay_spinner.destroy();
										this.set_stlink_info_box();
										return GLib.Source.REMOVE;
									});
							} else {
								GLib.MainContext.default().invoke(
									() => {
										this.should_wait_for_dongle = false;
										this.overlay_spinner.set_text("Cannot connect correctly to ST-Link dongle.\nPlease start <i>JTAG in a box</i> as root user.");
										this.overlay_spinner.set_spinner(false);
										this.queue_draw(); /* Force redrawing otherwise the overlay borders are messy */
										return GLib.Source.REMOVE;
									});
							}
						} else if (this.stlink->detect_vid_pid(0x1209, 0xC0CA)) {
							GLib.MainContext.default().invoke(
								() => {
									this.overlay_spinner.set_text("Please unplug and replug your dongle...");
									this.queue_draw(); /* Force redrawing otherwise the overlay borders are messy */
									return GLib.Source.REMOVE;
								});
						}
						
						Thread.usleep(10000);
					}
					
                    return 0;
                });

			yield;
		}

		private void set_stlink_info_box() {
			delete this.stlink;
			this.stlink = null;
			
			loader_ctx = new STLinkLoader.Context();
			if (loader_ctx == null) {
				return;
			}
			loader_ctx->read_infos();
			
			this.stlinkInfoBox = new STLinkInfoBox();
			this.stlinkInfoBox.install_action.connect(this.upload_firmware);
			this.stlinkInfoBox.show_progress_bar(false);
			this.stlinkInfoBox.set_infos(
				loader_ctx->get_id_str(),
				"V%dJ%dS%d".printf(
					loader_ctx->get_stlink_version(),
					loader_ctx->get_jtag_version(),
					loader_ctx->get_swim_version()
					)
				);
			
			this.add(this.stlinkInfoBox);
			this.stlinkInfoBox.show_buttons(true);
			this.stlinkInfoBox.show();
		}

		private void upload_firmware() {
			this.stlinkInfoBox.show_progress_bar(true);
			this.stlinkInfoBox.set_progress_bar(0.0f);
			this.stlinkInfoBox.show_buttons(false);
			new Thread<int>(null, () => {
					int res = this.loader_ctx->flash("dirtyjtag.bin", 0x08004000, 1024,
													 (progress) => {
														 GLib.MainContext.default().invoke(
															 () => {
																 this.stlinkInfoBox.set_progress_bar(progress);
																 return GLib.Source.REMOVE;
															 });
													 });
					GLib.MainContext.default().invoke(
						() => {
							if (res == 0) {
								this.stlinkInfoBox.set_progress_bar(1.0f);
							} else {
								this.stlinkInfoBox.set_progress_label("An error occured during firmware flashing (code=%d)".printf(res));
							}
							
							return GLib.Source.REMOVE;
						});
					return 0;
				});
		}
	}
}