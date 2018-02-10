[CCode (cheader_filename = "stlinkloader.h")]
namespace STLinkLoader {
	[Compact]
	[CCode (cname="struct stlinkloadercontext", destroy_function="stlinkloader_free", cprefix="stlinkloader_", has_type_id = false)]
	public class Context {
		[CCode (cname="progress_func")]
		public delegate void ProgressFunc(double progress);
		
		[CCode (cname = "stlinkloader_init")]
		public Context();
		
		public int is_correct_mode();
		public int read_infos();
		public unowned uint8[] get_id();
		public string get_id_str() {
			uint8[] id = this.get_id();
			GLib.StringBuilder builder = new GLib.StringBuilder ();

			for (int i = 0; i < 12; i++) {
				builder.append("%02X".printf(id[i]));
			}

			return builder.str;
		}
		public uint8 get_stlink_version();
		public uint8 get_jtag_version();
		public uint8 get_swim_version();
		public int flash(string filename, uint base_offset, uint chunk_size, ProgressFunc progress_callback);
	}
}