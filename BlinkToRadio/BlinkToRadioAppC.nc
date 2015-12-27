#include <Timer.h>
#include "BlinkToRadio.h"

configuration BlinkToRadioAppC {

} implementation {
    components MainC;
    components LedsC;
    components DAmasterC as App;
    components ActiveMessageC;
    components new AMSenderC(AM_DAMASTER);
    components new AMReceiverC(AM_DAMASTER);
    components SerialPrintfC;
    components new TimerMilliC() as Timer;
    
    App.SplitControl -> ActiveMessageC;
    App.Boot -> MainC;
    App.Timer -> Timer;
    App.Leds -> LedsC;
    App.Packet -> AMSenderC;
    App.AMPacket -> AMSenderC;
    App.AMSend -> AMSenderC;
    App.Receive -> AMReceiverC;
}
