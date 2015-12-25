#include <Timer.h>
#include "EasyCollection.h"
#include "SensirionSht11.h"
module EasyCollectionC {
	uses interface Boot;
	uses interface SplitControl as RadioControl;
	uses interface SplitControl as AMControl;
	uses interface StdControl as RoutingControl;
	uses interface StdControl as DisseminationControl;
	uses interface Send;
	uses interface Leds;
	uses interface Timer<TMilli>;
	uses interface RootControl;
	uses interface Receive;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface Read<uint16_t> as readTemp;
	uses interface Read<uint16_t> as readHumidity;
	uses interface Read<uint16_t> as readPhoto;
	uses interface DisseminationValue<uint16_t> as ValueI;
	uses interface DisseminationUpdate<uint16_t> as UpdateI;
	uses interface DisseminationValue<uint16_t> as ValueC;
	uses interface DisseminationUpdate<uint16_t> as UpdateC;
}
implementation {
	uint16_t data = 0;
	uint16_t TempData = 0;
	uint16_t HumidityData = 0;
	uint16_t PhotoData = 0;
	message_t packet;
	message_t serialpacket;
	message_t sendBufT;
	message_t sendBufP;
	EasyCollectionMsg localT, localP;
	uint8_t readingT, readingP;
	bool sendBusy = FALSE;
	bool SerialSendBusy = FALSE;


	event void Boot.booted(){
		call RadioControl.start();
		call AMControl.start();
		localT.id = 0x11;
	}

	event void RadioControl.startDone(error_t err){
		if (err != SUCCESS)
			call RadioControl.start();
		else {
			call RoutingControl.start();
			if (TOS_NODE_ID == 1)
				call RootControl.setRoot();
			else
				call Timer.startPeriodic(200);
		}
	}

	event void AMControl.startDone(error_t err){
		if  (err != SUCCESS) {
			call AMControl.start();
		} else {
			call DisseminationControl.start();
		}
	}

	event void RadioControl.stopDone(error_t err) {}

	event void AMControl.stopDone(error_t err) {}

	event void AMSend.sendDone(message_t* msg, error_t error) {
		if (&serialpacket == msg) {
			SerialSendBusy = FALSE;
		}
	}

	void sendMessageT() {
		memcpy(call Send.getPayload(&sendBufT, sizeof(localT)), &localT, sizeof(localT));
		/*
		EasyCollectionMsg* msg = (EasyCollectionMsg*)call Send.getPayload(&packet, sizeof(EasyCollectionMsg));
		msg->data = data;
		msg->nodeid = TOS_NODE_ID;
		msg->TempData = TempData;
		msg->HumidityData = HumidityData;
		msg->PhotoData = PhotoData;
		*/

		if (call Send.send(&sendBufT, sizeof(EasyCollectionMsg)) != SUCCESS){
			
		}
		else{
			sendBusy = TRUE;
		}
	}
	void sendMessageP() {
		memcpy(call Send.getPayload(&sendBufP, sizeof(localP)), &localP, sizeof(localP));
		/*
		EasyCollectionMsg* msg = (EasyCollectionMsg*)call Send.getPayload(&packet, sizeof(EasyCollectionMsg));
		msg->data = data;
		msg->nodeid = TOS_NODE_ID;
		msg->TempData = TempData;
		msg->HumidityData = HumidityData;
		msg->PhotoData = PhotoData;
		*/

		if (call Send.send(&sendBufP, sizeof(EasyCollectionMsg)) != SUCCESS){
			
		}
		else{
			sendBusy = TRUE;
		}
	}

	event void Timer.fired() {
		//call Leds.led2Toggle();
		data++;
		call readTemp.read();
		//call readHumidity.read();
		call readPhoto.read();
		if (!sendBusy && readingP == NREADINGS)
		{
			//call Leds.led1Toggle();
			sendMessageP();
		}
		if (!sendBusy && readingT == NREADINGS)
		{
			//call Leds.led1Toggle();
			sendMessageT();
		}
		
			
	}

	event void Send.sendDone(message_t* m, error_t err) {
		if (err != SUCCESS)
			call Leds.led0Toggle();
		sendBusy = FALSE;
		//call Leds.led0Toggle();
		if (readingP == NREADINGS) {
			readingP = 0;
		}else if (readingT == NREADINGS){
			readingT = 0;
		}

	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		call Leds.led1Toggle();
		if (!SerialSendBusy) {
			EasyCollectionMsg* source = (EasyCollectionMsg*) payload;
			EasyCollectionMsg* ecpkt = (EasyCollectionMsg*)(call Packet.getPayload(&serialpacket, NULL));
			ecpkt->id = source->id;
			ecpkt->count = source->count;
			memcpy(ecpkt->reading, source->reading, (sizeof (nx_uint16_t))*NREADINGS);
			if (call AMSend.send(AM_BROADCAST_ADDR, &serialpacket, sizeof(EasyCollectionMsg)) == SUCCESS) {
							SerialSendBusy = TRUE;
						}
		}
		return msg;
	}
	event void readTemp.readDone(error_t result, uint16_t val){
		if(result == SUCCESS){
			val = -40.1 + 0.01*val;
			TempData = val;
			//call Leds.led2Toggle();
		}
		else{
			TempData = 0xffff;
		}
		if (readingT < NREADINGS) {
			localT.reading[readingT++] = TempData;
		}
		//call Leds.led0Toggle();
	}
	event void readHumidity.readDone(error_t result, uint16_t val){
		if(result == SUCCESS){
			HumidityData = -4 + 4*val/100 + (-28/1000/10000)*(val*val);
			HumidityData = (TempData-25)*(1/100+8*val/100/1000)+HumidityData;
		}
		else{
			HumidityData = 0xffff;
		}
		call Leds.led1Toggle();
	}
	event void readPhoto.readDone(error_t result, uint16_t val){
		if(result == SUCCESS){
			PhotoData = val;
			call Leds.led2Toggle();
		}
		else{
			PhotoData = 0xffff;
		}
		if (readingP < NREADINGS) {
			localP.reading[readingP++] = PhotoData;
		}
		
	}
	event void ValueI.changed() {
		//const uint16_t* newInterval = call ValueI.get();
		//interval = *newInterval;
		//call Timer.startPeriodic(interval);
	}
	event void ValueC.changed() {
		//const uint16_t* newCount = call ValueC.get();
		//if (newCount > count) {
			//count = newCount;
			//suppressCountChange = TRUE;
		//}
	}
}
