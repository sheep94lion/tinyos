#include "EasyCollection.h"

configuration EasyCollectionAppC {}
implementation {
	components EasyCollectionC, MainC, LedsC, ActiveMessageC;
	components CollectionC as Collector;
	components new CollectionSenderC(0xee);
	components new SensirionSht11C();
	components new HamamatsuS1087ParC();
	components new TimerMilliC() as TimerMilliC0;
	components new TimerMilliC() as TimerMilliC1;
	components SerialActiveMessageC;
	components DisseminationC;
	components new DisseminatorC(uint16_t, 0x1234) as Diss16CI;
	components new SerialAMSenderC(AM_OSCILLOSCOPE);
	components new SerialAMReceiverC(AM_OSCILLOSCOPE);

	EasyCollectionC.Packet -> SerialAMSenderC;
	EasyCollectionC.AMPacket -> SerialAMSenderC;
	EasyCollectionC.AMSend -> SerialAMSenderC;
	EasyCollectionC.SReceive -> SerialAMReceiverC;
	EasyCollectionC.AMControl -> SerialActiveMessageC;
	EasyCollectionC.Boot -> MainC;
	EasyCollectionC.RadioControl -> ActiveMessageC;
	EasyCollectionC.RoutingControl -> Collector;
	EasyCollectionC.Leds -> LedsC;
	EasyCollectionC.Timer0 -> TimerMilliC0;
	EasyCollectionC.Timer1 -> TimerMilliC1;
	EasyCollectionC.Send -> CollectionSenderC;
	EasyCollectionC.RootControl -> Collector;
	EasyCollectionC.CReceive -> Collector.Receive[0xee];
	EasyCollectionC.readTemp -> SensirionSht11C.Temperature;
	EasyCollectionC.readHumidity -> SensirionSht11C.Humidity;
	EasyCollectionC.readPhoto -> HamamatsuS1087ParC;
	EasyCollectionC.DisseminationControl -> DisseminationC;
	EasyCollectionC.ValueI -> Diss16CI;
	EasyCollectionC.UpdateI -> Diss16CI;

}