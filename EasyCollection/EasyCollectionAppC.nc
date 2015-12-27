#include "EasyCollection.h"

configuration EasyCollectionAppC {}
implementation {
	components EasyCollectionC, MainC, LedsC, ActiveMessageC;
	components new TimerMilliC() as TimerMilliC0;
	components new TimerMilliC() as TimerMilliC1;
	components new AMSenderC(AM_DAMASTER);
	components new AMReceiverC(AM_DAMASTER);

	EasyCollectionC.Packet -> AMSenderC;
	EasyCollectionC.AMPacket -> AMSenderC;
	EasyCollectionC.AMSend -> AMSenderC;
	EasyCollectionC.SReceive -> AMReceiverC;
	EasyCollectionC.AMControl -> ActiveMessageC;
	EasyCollectionC.Boot -> MainC;
	EasyCollectionC.RadioControl -> ActiveMessageC;

	EasyCollectionC.Leds -> LedsC;
	EasyCollectionC.Timer0 -> TimerMilliC0;
	EasyCollectionC.Timer1 -> TimerMilliC1;

}