int dfu_download(struct stlinkloadercontext *context,
		 unsigned char *data,
		 size_t data_len,
		 uint16_t wBlockNum);
int current_mode(struct stlinkloadercontext *context);
