#include "EasyCollection.h"

configuration EasyCollectionAppC {}
implementation {
	components EasyCollectionC, MainC, LedsC, ActiveMessageC;
	components new SensirionSht11C();
	components new HamamatsuS1087ParC();
	components new TimerMilliC() as TimerMilliC0;
	components new TimerMilliC() as TimerMilliC1;
	components DisseminationC;
	components new DisseminatorC(Inte, 0x1234) as Diss16CI;
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

	EasyCollectionC.DisseminationControl -> DisseminationC;
	EasyCollectionC.ValueI -> Diss16CI;
	EasyCollectionC.UpdateI -> Diss16CI;

}