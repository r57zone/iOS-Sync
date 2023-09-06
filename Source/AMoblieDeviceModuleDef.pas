{*******************************************************}
{                                                       }
{       IOS Device Type Define Class                    }
{                                                       }
{       author  :  LAHCS                                }
{                                                       }
{       E-Mail  :  lahcs@qq.com                         }
{                                                       }
{       QQ      :  307643816                            }
{                                                       }
{       Copy Right (C) 2013                             }
{                                                       }
{*******************************************************}
{ ReferenceList£º
  [The iPhone wiki] http://theiphonewiki.com/wiki/MobileDevice_Library
  [Manzana] http://manzana.googlecode.com/
}
unit AMoblieDeviceModuleDef;

interface

uses
  Windows;

const
  AAS_PATH :WideString = '\Apple\Apple Application Support\';
  MDS_PATH :WideString = '\Apple\Mobile Device Support\';
  AFC_STRING : String = 'com.apple.afc';
  AFC2_STRING : String = 'com.apple.afc2';

const
  ADNCI_MSG_CONNECTED    = 1;
  ADNCI_MSG_DISCONNECTED = 2;
  ADNCI_MSG_UNKNOWN      = 3;

type
  mach_error_t = UINT;
  afc_error_t  = UINT;
  afc_file_ref = ULONG;

{struct am_device
    unsigned char unknown0[0x10]; /* 0 - zero */
    unsigned int device_id;     /* 16 */
    unsigned int product_id;    /* 20 - set to AMD_IPHONE_PRODUCT_ID */
    char *serial;               /* 24 - set to AMD_IPHONE_SERIAL */
    unsigned int unknown1;      /* 28 */
    unsigned char unknown2[0x4];  /* 32 */
    unsigned int lockdown_conn; /* 36 */
    unsigned char unknown3[0x8];  /* 40 */
    unsigned char unknown4[0x61];  /* 40 */
    unsigned char unknown5[0x8];  /* 40 */
}
type
  am_device = packed record
     unknown0 : array [0..$10 - 1] of UCHAR;
     device_id : UINT;
     product_id : UINT;
     serial : PChar;
     unknown1 : UINT;
     unknown2 : array [0..$4 - 1] of UCHAR;
     lockdown_conn : UINT;
     unknown3 : array [0..$8 - 1] of UCHAR;
     unknown4 : array [0..$61 - 1] of UCHAR;
     unknown5 : array [0..$8 - 1] of UCHAR;
  end;
  p_am_device = ^am_device;

{  struct am_device_notification_callback_info
    struct am_device *dev;  /* 0    device */
    unsigned int msg;       /* 4    one of ADNCI_MSG_* */
}
type
  am_device_notification_callback_info = record
    dev : p_am_device;
    msg : UINT;                                                  
  end;
  p_am_device_notification_callback_info = ^am_device_notification_callback_info;

{typedef void(*am_device_notification_callback)(struct
    am_device_notification_callback_info *);   }

type
  am_device_notification_callback = procedure(value:p_am_device_notification_callback_info);cdecl;
  p_am_device_notification_callback = ^am_device_notification_callback;
  
type
  am_device_notification = record
    unknown0 : UINT;
    unknown1 : UINT;
    unknown2 : UINT;
    callback : p_am_device_notification_callback;
    unknown3 : UINT;
  end;
  p_am_device_notification = ^am_device_notification;
  p_p_am_device_notification = ^p_am_device_notification;

  afc_connection = record
    handle   : UINT;
    unknown0 : UINT;
    unknown1 : UCHAR;
    padding : array [0..3-1] of UCHAR;
    unknown2 : UINT;
    unknown3 : UINT;
    unknown4 : UINT;
    fs_block_size : UINT;
    sock_block_size : UINT;
    io_timeout : UINT;
    afc_lock : Pointer;
    context : UINT;
  end;
  p_afc_connection = ^afc_connection;
  p_p_afc_connection = ^p_afc_connection;

  afc_device_info = record
    unknown : array [0..12 - 1] of UCHAR;
  end;

  afc_directory = record
    unknown : UCHAR;
  end;
  p_afc_directory = ^afc_directory;

  afc_dictionary = record
    unknown : UCHAR;
  end;
  p_afc_dictionary = ^afc_dictionary;

//==============================================================================
// iTunesMobileDevice.dll
//==============================================================================

  FunType_AMDeviceNotificationSubscribe
    = function(callback:am_device_notification_callback;unused0,unused1,dn_unknown3:UINT;notification:p_p_am_device_notification):mach_error_t;cdecl;

  FunType_AMDeviceNotificationUnsubscribe
    = function(notification:p_am_device_notification):mach_error_t;cdecl;

  FunType_AMDeviceConnect
    = function(device:p_am_device):mach_error_t;cdecl;

  FunType_AMDeviceIsPaired
    = function(device:p_am_device):Integer;cdecl;

  FunType_AMDeviceValidatePairing
    = function(device:p_am_device):mach_error_t;cdecl;

  FunType_AMDeviceStartSession
    = function(device:p_am_device):mach_error_t;cdecl;

  FunType_AMDeviceStartService
    = function(device:p_am_device;service_name:Pointer;handle:p_p_afc_connection;unknown:PUINT):mach_error_t;cdecl;

  FunType_AMDeviceStopSession
    = function(device:p_am_device):mach_error_t;cdecl;

  FunType_AFCConnectionClose
    = function(conn:p_afc_connection):afc_error_t;cdecl;

  FunType_AMDeviceDisconnect
    = function(device:p_am_device):mach_error_t;cdecl;

  //public extern static int AMDeviceGetConnectionID(ref AMDevice device);

  //public extern static int AMRestoreModeDeviceCreate(uint unknown0, int connection_id, uint unknown1);

  //public extern static IntPtr AMDeviceCopyValue(ref AMDevice device, uint unknown, byte[] cfstring);
  FunType_AMDeviceCopyValue
    = function(device:p_am_device;unknow: UINT;cfstring:Pointer):Pointer;cdecl;
  //public extern static int AMRestoreRegisterForDeviceNotifications(
//			DeviceRestoreNotificationCallback dfu_connect,
//			DeviceRestoreNotificationCallback recovery_connect, 
//			DeviceRestoreNotificationCallback dfu_disconnect,
//			DeviceRestoreNotificationCallback recovery_disconnect,
//			uint unknown0,
//			IntPtr user_info);

  FunType_AFCConnectionOpen
    = function(conn:p_afc_connection;io_timeout:UINT;pconn:p_p_afc_connection):afc_error_t;cdecl;

  //public extern static int AFCDirectoryOpen(IntPtr conn, string path, ref IntPtr dir);
  FunType_AFCDirectoryOpen
    = function(conn:p_afc_connection;path:PChar;var dir: Pointer):afc_error_t;cdecl;

  //public extern static int AFCDirectoryRead(IntPtr conn, IntPtr dir, ref IntPtr dirent);
  FunType_AFCDirectoryRead
    = function(conn:p_afc_connection;dir: Pointer;var dirent:Pointer):afc_error_t;cdecl;

  //public extern static int AFCDirectoryClose(IntPtr conn, IntPtr dir);
  FunType_AFCDirectoryClose
    = function(conn:p_afc_connection;dir: Pointer):afc_error_t;cdecl;

  //public extern static int AFCDirectoryCreate(IntPtr conn, string path);
  FunType_AFCDirectoryCreate
    = function(conn:p_afc_connection;path: PChar):afc_error_t;cdecl;

  //public static extern unsafe int AFCDeviceInfoOpen(void* conn, ref void* dict);
  FunType_AFCDeviceInfoOpen
    = function(conn:p_afc_connection;var dict:Pointer):afc_error_t;cdecl;
    
  //public extern static int AFCGetFileInfo(IntPtr conn, string path, ref IntPtr buffer, out uint length);
  //FunType_AFCGetFileInfo
  //  = function(handle:p_afc_connection;path: PChar;var buffer:Pointer; var Length:UINT):afc_error_t;cdecl;
  //unsafe public extern static int AFCFileInfoOpen(void* conn, string path, ref void* dict);
  FunType_AFCFileInfoOpen
    = function(conn:p_afc_connection;path: PChar;var dict:Pointer):afc_error_t;cdecl;

  //public static extern unsafe int AFCKeyValueRead(void* dict, out void* key, out void* val);
  FunType_AFCKeyValueRead
    = function(dict: p_afc_dictionary;out key: PChar;out val: PChar):afc_error_t;cdecl;

  //public static extern unsafe int AFCKeyValueClose(void* dict);
  FunType_AFCKeyValueClose
    = function(dict: p_afc_dictionary):afc_error_t;cdecl;
    
  //public extern static int AFCRemovePath(IntPtr conn, string path);
  FunType_AFCRemovePath
    = function(conn:p_afc_connection;path: PChar):afc_error_t;cdecl;

  //public extern static int AFCRenamePath(IntPtr conn, string old_path, string new_path);
  FunType_AFCRenamePath
    = function(conn:p_afc_connection;old_path: PChar;new_path:PChar):afc_error_t;cdecl;

  //public extern static int AFCFileRefOpen(IntPtr conn, string path, int mode, int unknown, out Int64 handle);
  FunType_AFCFileRefOpen   
    = function(conn:p_afc_connection;path: PChar;mode : Integer;unknow:Integer;var handle:Int64):afc_error_t;cdecl;

  //public extern static int AFCFileRefClose(IntPtr conn, Int64 handle);
  FunType_AFCFileRefClose
    = function(conn:p_afc_connection;handle:Int64):afc_error_t;cdecl;

  //public extern static int AFCFileRefRead(IntPtr conn, Int64 handle, byte[] buffer, ref uint len);
  FunType_AFCFileRefRead
    = function(conn:p_afc_connection;handle:Int64;buffer:Pointer;var len:UINT):afc_error_t;cdecl;

  //public extern static int AFCFileRefWrite(IntPtr conn, Int64 handle, byte[] buffer, uint len);
  FunType_AFCFileRefWrite
    = function(conn:p_afc_connection;handle:Int64;buffer:Pointer;len:UINT):afc_error_t;cdecl;

  //public extern static int AFCFlushData(IntPtr conn, Int64 handle);
  FunType_AFCFlushData
    = function(conn:p_afc_connection;handle:Int64):afc_error_t;cdecl;

  //public extern static int AFCFileRefSeek(IntPtr conn, Int64 handle, uint pos, uint origin);
  FunType_AFCFileRefSeek
    = function(conn:p_afc_connection;handle:Int64;pos:UINT;origin:UINT):afc_error_t;cdecl;

  //public extern static int AFCFileRefTell(IntPtr conn, Int64 handle, ref uint position); 
  FunType_AFCFileRefTell
    = function(conn:p_afc_connection;handle:Int64;var position:UINT):afc_error_t;cdecl;

  //public extern static int AFCFileRefSetFileSize(IntPtr conn, Int64 handle, uint size); 
  FunType_AFCFileRefSetFileSize
    = function(conn:p_afc_connection;handle:Int64;size:UINT):afc_error_t;cdecl;

//==============================================================================
// CoreFoundation.dll
//==============================================================================
    
  FunType_CFStringCreateWithCString
      = function(allocator:Pointer;const data:PChar;encoding:UINT):Pointer;cdecl;

  
  enum_CFPropertyListMutabilityOptions =
  (
    kCFPropertyListImmutable = 0,
    kCFPropertyListMutableContainers = 1,
    kCFPropertyListMutableContainersAndLeaves = 2
  );

  FunType_CFPropertyListCreateFromXMLData
     = function(allocator: Pointer; const xmlData: PChar;
                optionFlags: enum_CFPropertyListMutabilityOptions;
                errorString: PChar):Pointer;cdecl;

  FunType_CFPropertyListCreateXMLData
     = function(allocator: Pointer; propertyList: Pointer):PChar;cdecl;

implementation

end.
