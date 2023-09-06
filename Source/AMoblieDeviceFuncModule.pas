{*******************************************************}
{                                                       }
{       iTunesMobileDevice Function Class               }
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
unit AMoblieDeviceFuncModule;

interface

uses
  AMoblieDeviceModuleDef;

type

  TAMoblieDeviceFuncModule = class(TObject)
  public
    lpf_CFStringCreateWithCString : FunType_CFStringCreateWithCString;
    lpf_CFPropertyListCreateFromXMLData : FunType_CFPropertyListCreateFromXMLData;
    lpf_CFPropertyListCreateXMLData : FunType_CFPropertyListCreateXMLData;
  public
    lpf_AMDeviceNotificationSubscribe : FunType_AMDeviceNotificationSubscribe;
    lpf_AMDeviceNotificationUnsubscribe : FunType_AMDeviceNotificationUnsubscribe;
    lpf_AMDeviceConnect : FunType_AMDeviceConnect;
    lpf_AMDeviceDisconnect : FunType_AMDeviceDisconnect;
    lpf_AMDeviceIsPaired : FunType_AMDeviceIsPaired;
    lpf_AMDeviceValidatePairing : FunType_AMDeviceValidatePairing;
    lpf_AMDeviceStartSession : FunType_AMDeviceStartSession;
    lpf_AMDeviceStopSession : FunType_AMDeviceStopSession;
    lpf_AMDeviceStartService : FunType_AMDeviceStartService;
    lpf_AMDeviceCopyValue : FunType_AMDeviceCopyValue;
  public
    lpf_AFCConnectionOpen : FunType_AFCConnectionOpen;
    lpf_AFCConnectionClose : FunType_AFCConnectionClose;
    lpf_AFCDirectoryOpen : FunType_AFCDirectoryOpen;
    lpf_AFCDirectoryRead : FunType_AFCDirectoryRead;
    lpf_AFCDirectoryClose : FunType_AFCDirectoryClose;
    lpf_AFCDirectoryCreate : FunType_AFCDirectoryCreate;
    lpf_AFCDeviceInfoOpen : FunType_AFCDeviceInfoOpen;
    lpf_AFCFileInfoOpen : FunType_AFCFileInfoOpen;
    lpf_AFCKeyValueRead : FunType_AFCKeyValueRead;
    lpf_AFCKeyValueClose : FunType_AFCKeyValueClose;
    lpf_AFCRemovePath : FunType_AFCRemovePath;
    lpf_AFCRenamePath : FunType_AFCRenamePath;
    lpf_AFCFileRefOpen : FunType_AFCFileRefOpen;
    lpf_AFCFileRefClose : FunType_AFCFileRefClose;
    lpf_AFCFileRefRead : FunType_AFCFileRefRead;
    lpf_AFCFileRefWrite : FunType_AFCFileRefWrite;
    lpf_AFCFlushData : FunType_AFCFlushData;
    lpf_AFCFileRefSeek : FunType_AFCFileRefSeek;
    lpf_AFCFileRefTell : FunType_AFCFileRefTell;
    lpf_AFCFileRefSetFileSize : FunType_AFCFileRefSetFileSize;
  end;

var
  FuncModule : TAMoblieDeviceFuncModule;

implementation

end.
