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
	uses interface Receive as CReceive;
	uses interface Receive as SReceive;
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
	uint16_t count = 0;
	uint16_t TempData = 0;
	uint16_t HumidityData = 0;
	uint16_t PhotoData = 0;
	uint16_t version = 0;
	message_t packet;
	message_t serialpacket;
	message_t sendBufT;
	message_t sendBufP;
	message_t sendBufH;
	EasyCollectionMsg localT, localP, localH;
	uint8_t readingT, readingP, readingH;
	bool ifsendP, ifsendT, ifsendH;
	bool trysendP, trysendT, trysendH;
	bool sendBusy = FALSE;
	bool SerialSendBusy = FALSE;
	bool suppressCountChange = FALSE;


	event void Boot.booted(){
		call RadioControl.start();
		call AMControl.start();
		localP.id = TOS_NODE_ID * 10 + 1;
		localT.id = TOS_NODE_ID * 10 + 2;
		localH.id = TOS_NODE_ID * 10 + 3;
		localP.count = 0;
		localT.count = 0;
		localH.count = 0;
		ifsendH = FALSE;
		ifsendT = FALSE;
		ifsendP = FALSE;
		trysendP = FALSE;
		trysendH = FALSE;
		trysendT = FALSE;
	}

	event void RadioControl.startDone(error_t err){
		if (err != SUCCESS)
			call RadioControl.start();
		else {
			call RoutingControl.start();
			if (TOS_NODE_ID == 1)
				call RootControl.setRoot();
			else
				call Timer.startPeriodic(DEFAULT_INTERVAL);
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
		localT.count = count;
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

			trysendT = FALSE;
		}
		else{
			sendBusy = TRUE;
		}
	}
	void sendMessageP() {
		localP.count = count;
		memcpy(call Send.getPayload(&sendBufP, sizeof(localP)), &localP, sizeof(localP));
		if (call Send.send(&sendBufP, sizeof(EasyCollectionMsg)) != SUCCESS){

			trysendP = FALSE;
		}
		else{
			sendBusy = TRUE;
		}
	}
	void sendMessageH() {
		localH.count = count;
		memcpy(call Send.getPayload(&sendBufH, sizeof(localH)), &localH, sizeof(localH));
		if (call Send.send(&sendBufH, sizeof(EasyCollectionMsg)) != SUCCESS){
			trysendH = FALSE;
		}
		else{
			sendBusy = TRUE;
		}
	}

	event void Timer.fired() {
		//call Leds.led2Toggle();
		bool ifreadP = TRUE;
		bool ifreadT = TRUE;
		bool ifreadH = TRUE;

		if (readingP == NREADINGS){
			//call Leds.led1Toggle();
			ifreadP = FALSE;		
			if(!sendBusy && !ifsendP && !trysendP){
				localP.count++;
				//call Leds.led0Toggle();
				trysendP = TRUE;
				sendMessageP();
			}
		}
		if (readingT == NREADINGS){
			ifreadT = FALSE;
			if(!sendBusy && !ifsendT && !trysendT){
				localT.count++;
				//call Leds.led1Toggle();
				trysendT = TRUE;
				sendMessageT();
			}
			//call Leds.led1Toggle();
		}
		if (readingH == NREADINGS){
			//call Leds.led1Toggle();
			ifreadH = FALSE;
			if(!sendBusy && !ifsendH && !trysendH){
				localH.count++;
				//call Leds.led2Toggle();
				trysendH = TRUE;
				sendMessageH();
			}
		}
		
		if(ifreadT){
			call readTemp.read();
		}
		if(ifreadH){
			call readHumidity.read();
		}
		if(ifreadP){
			call readPhoto.read();
		}
				
	}

	event void Send.sendDone(message_t* m, error_t err) {
		//call Leds.led1Toggle();
		EasyCollectionMsg *msg = call Send.getPayload(m, sizeof(EasyCollectionMsg));
		sendBusy = FALSE;
		if (err != SUCCESS){
			//call Leds.led0Toggle();
			if (readingP == NREADINGS) {
				trysendP = FALSE;
			}else if (readingT == NREADINGS){
				trysendT = FALSE;
			}else if (readingH == NREADINGS){
				trysendH = FALSE;
			}
			return;
		}
		//call Leds.led0Toggle();
		if (msg->id == localP.id) {
			call Leds.led0Toggle();
			readingP = 0;
			ifsendP = TRUE;
			trysendP = FALSE;
		}else if (msg->id == localT.id){
			call Leds.led1Toggle();
			readingT = 0;
			ifsendT = TRUE;
			trysendT = FALSE;
		}else if (msg->id == localH.id){
			call Leds.led2Toggle();
			readingH = 0;
			ifsendH = TRUE;
			trysendH = FALSE;
		}
		if(ifsendH && ifsendT && ifsendP){
			if (!suppressCountChange) {
				count++;
				call UpdateC.change(&count);
			}
			trysendP = FALSE;
			trysendH = FALSE;
			trysendT = FALSE;
			ifsendP = FALSE;
			ifsendT = FALSE;
			ifsendH = FALSE;
		}
	}

	event message_t* CReceive.receive(message_t* msg, void* payload, uint8_t len) {
		call Leds.led1Toggle();
		if (!SerialSendBusy) {
			EasyCollectionMsg* source = (EasyCollectionMsg*) payload;
			oscilloscope_t* ecpkt = (oscilloscope_t*)(call Packet.getPayload(&serialpacket, NULL));
			ecpkt->id = source->id;
			ecpkt->count = source->count;
			memcpy(ecpkt->readings, source->reading, (sizeof (nx_uint16_t))*NREADINGS);
			ecpkt->version = version;
			ecpkt->interval = DEFAULT_INTERVAL;
			if (call AMSend.send(AM_BROADCAST_ADDR, &serialpacket, sizeof(oscilloscope_t)) == SUCCESS) {
				SerialSendBusy = TRUE;
			}
		}
		return msg;
	}
	event message_t* SReceive.receive(message_t* msg, void* payload, uint8_t len) {
		oscilloscope_t *omsg = payload;
		if (omsg->version > version) {
			interval = omsg->interval;
			call UpdateI.change(&interval);
		}
	}
	event void readTemp.readDone(error_t result, uint16_t val){
		if(result == SUCCESS){
			val = -40.1 + 0.01*val;
			TempData = val;
		}
		else{
			TempData = 0xffff;
		}
		if (readingT < NREADINGS) {
			localT.reading[readingT++] = TempData;
		}
		
	}
	event void readHumidity.readDone(error_t result, uint16_t val){
		if(result == SUCCESS){
			HumidityData = -4 + 4*val/100 + (-28/1000/10000)*(val*val);
			HumidityData = (TempData-25)*(1/100+8*val/100/1000)+HumidityData;
		}
		else{
			HumidityData = 0xffff;
		}
		if (readingH < NREADINGS) {
			localH.reading[readingH++] = HumidityData;
		}
		
	}
	event void readPhoto.readDone(error_t result, uint16_t val){
		if(result == SUCCESS){
			PhotoData = val;
		}
		else{
			PhotoData = 0xffff;
		}
		if (readingP < NREADINGS) {
			localP.reading[readingP++] = PhotoData;
		}
		
		
	}
	event void ValueI.changed() {
		const uint16_t* newInterval = call ValueI.get();
		interval = *newInterval;
		call Timer.startPeriodic(interval);
	}
	event void ValueC.changed() {
		const uint16_t* newCount = call ValueC.get();
		if (*newCount > count) {
			count = *newCount;
			suppressCountChange = TRUE;
		}
	}
}
