#include <glib.h>
#include <stdint.h>

typedef void(*progress_func)(double progress, gpointer user_data);

struct stlinkloadercontext;

struct stlinkloadercontext* stlinkloader_init(void);
void stlinkloader_free(struct stlinkloadercontext *context);
int stlinkloader_read_infos(struct stlinkloadercontext *context);
int stlinkloader_is_correct_mode(struct stlinkloadercontext *context);
uint8_t* stlinkloader_get_id(struct stlinkloadercontext *context, int *id_length);
uint8_t stlinkloader_get_stlink_version(struct stlinkloadercontext *context);
uint8_t stlinkloader_get_jtag_version(struct stlinkloadercontext *context);
uint8_t stlinkloader_get_swim_version(struct stlinkloadercontext *context);
int stlinkloader_flash(struct stlinkloadercontext *context,
		       const char *filename,
		       unsigned int base_offset,
		       unsigned int chunk_size,
		       progress_func progress_callback,
		       gpointer user_data);
