struct stlinkloadercontext {
  libusb_context *usb_context;
  libusb_device_handle *usb_dev_handle;
  
  uint8_t firmware_key[16];
  uint8_t id[12];
  uint8_t stlink_version;
  uint8_t jtag_version;
  uint8_t swim_version;
  uint16_t loader_version;
};

enum DeviceStatus {
  OK = 0x00,
  errTARGET = 0x01,
  errFILE = 0x02,
  errWRITE = 0x03,
  errERASE = 0x04,
  errCHECK_ERASED = 0x05,
  errPROG = 0x06,
  errVERIFY = 0x07,
  errADDRESS = 0x08,
  errNOTDONE = 0x09,
  errFIRMWARE = 0x0A,
  errVENDOR = 0x0B,
  errUSBR = 0x0C,
  errPOR = 0x0D,
  errUNKNOWN = 0x0E,
  errSTALLEDPKT = 0x0F
};

enum DeviceState {
  appIDLE = 0,
  appDETACH = 1,
  dfuIDLE = 2,
  dfuDNLOAD_SYNC = 3,
  dfuDNBUSY = 4,
  dfuDNLOAD_IDLE = 5,
  dfuMANIFEST_SYNC = 6,
  dfuMANIFEST = 7,
  dfuMANIFEST_WAIT_RESET = 8,
  dfuUPLOAD_IDLE = 9,
  dfuERROR = 10
};

struct DFUStatus {
  enum DeviceStatus bStatus : 8;
  unsigned int bwPollTimeout : 24;
  enum DeviceState bState : 8;
  unsigned char iString : 8;
};

