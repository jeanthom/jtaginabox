namespace JTAGInABox {
	public class STLink {
		LibUSB.Context* ctx;
		
		public STLink() {
			LibUSB.Context.init(out this.ctx);
		}

		~STLink() {
			delete this.ctx;
		}

		public bool can_claim_vid_pid(uint16 vid, uint16 pid, int interface_num) {
			LibUSB.DeviceHandle dh;
			int res;
			bool ret;
			
			dh = this.ctx->open_device_with_vid_pid(vid, pid);
			if (dh != null) {
				res = dh.claim_interface(interface_num);

				if (res != 0) {
					ret = false;
				} else {
					ret = true;
					dh.release_interface(interface_num);
				}
			} else {
				ret = false;
			}

			return ret;
		}

		public bool detect_vid_pid(uint16 vid, uint16 pid) {
			LibUSB.Device[] devices;
			int i = 0;
			bool res = false;
			
			this.ctx->get_device_list(out devices);

			while (devices[i] != null) {
				LibUSB.DeviceDescriptor desc = LibUSB.DeviceDescriptor(devices[i]);

				if (desc.idVendor == vid && desc.idProduct == pid) {
					res = true;
				}

				i++;
			}
			
			return res;
		}
		
		public void exit_dfu() {
			LibUSB.DeviceHandle dh = this.ctx->open_device_with_vid_pid(0x0483, 0x3748);
			int transferred;

			if (dh != null) {
				// TODO : check that the interface has correctly been claimed
				dh.claim_interface(0);

				uint8 cmd[] = {0xF3, 0x07};
				dh.bulk_transfer(2, cmd, out transferred, 100);
				
				dh.release_interface(0);
			}
		}
	}
}