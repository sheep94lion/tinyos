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
	uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as Timer1;
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
}
implementation {
	uint16_t seq = 0;
	uint16_t TempData = 0;
	uint16_t HumidityData = 0;
	uint16_t PhotoData = 0;
	uint16_t version = 0;
	uint16_t interval = DEFAULT_INTERVAL;
	uint32_t current_time = 0;
	message_t packet;
	message_t serialpacketP, serialpacketT, serialpacketH;
	message_t sendBuf;

	EasyCollectionMsg local;
	oscilloscope_t sendqueue[50];
	uint8_t start = 0;
	uint8_t end = 0;
	bool sendBusy = FALSE;
	bool SerialSendBusy = FALSE;
	bool suppressCountChange = FALSE;


	event void Boot.booted(){
		call RadioControl.start();
		call AMControl.start();
		local.id = TOS_NODE_ID;
	}

	event void RadioControl.startDone(error_t err){
		if (err != SUCCESS)
			call RadioControl.start();
		else {
			call RoutingControl.start();
			if (TOS_NODE_ID == 1){
				call RootControl.setRoot();
				call Timer1.startOneShot(200);
			}
				
			else{
				call Timer0.startPeriodic(DEFAULT_INTERVAL);
			}
				
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
		start = (start + 1) % 50;
		if (end != start) {
			oscilloscope_t* ecpkt = (oscilloscope_t*)(call Packet.getPayload(&serialpacketP, NULL));
			ecpkt->id = sendqueue[start].id;
			ecpkt->count = sendqueue[start].count;
			ecpkt->readings[0] = sendqueue[start].readings[0];
			ecpkt->version = sendqueue[start].version;
			ecpkt->interval = sendqueue[start].interval;
			ecpkt->current_time = sendqueue[start].current_time;
			call AMSend.send(AM_BROADCAST_ADDR, &serialpacketP, sizeof(oscilloscope_t));
		} else {
			call Timer1.startOneShot(200);
		}
	}

	void sendMessage() {
		memcpy(call Send.getPayload(&sendBuf, sizeof(local)), &local, sizeof(local));
		if (call Send.send(&sendBuf, sizeof(EasyCollectionMsg)) != SUCCESS){
		}
		else{
			sendBusy = TRUE;
		}
	}

	event void Timer0.fired() {
		seq++;
		local.seq = seq;
		call readPhoto.read();
		call readHumidity.read();
		call readTemp.read();
		current_time = call Timer0.getNow();
		local.current_time = current_time;

		sendMessage();
	}

	event void Timer1.fired() {
		call Leds.led1Toggle();
		if (end != start) {
			oscilloscope_t* ecpkt = (oscilloscope_t*)(call Packet.getPayload(&serialpacketP, NULL));
			ecpkt->id = sendqueue[start].id;
			ecpkt->count = sendqueue[start].count;
			ecpkt->readings[0] = sendqueue[start].readings[0];
			ecpkt->version = sendqueue[start].version;
			ecpkt->interval = sendqueue[start].interval;
			ecpkt->current_time = sendqueue[start].current_time;
			call AMSend.send(AM_BROADCAST_ADDR, &serialpacketP, sizeof(oscilloscope_t));
		} else {
			call Timer1.startOneShot(200);
		}
	}

	event void Send.sendDone(message_t* m, error_t err) {
		sendBusy = FALSE;
	}

	event message_t* CReceive.receive(message_t* msg, void* payload, uint8_t len) {
		//call Leds.led0Toggle();

		EasyCollectionMsg* source = (EasyCollectionMsg*) payload;
		sendqueue[end].id = source->id * 10 + 1;
		sendqueue[end].count = source->seq;
		sendqueue[end].readings[0] = source->PhotoData;
		sendqueue[end].version = version;
		sendqueue[end].interval = interval;
		sendqueue[end].current_time = source->current_time;
		end = (end + 1) % 50;
		sendqueue[end].id = source->id * 10 + 2;
		sendqueue[end].count = source->seq;
		sendqueue[end].readings[0] = source->TempData;
		sendqueue[end].version = version;
		sendqueue[end].interval = interval;
		sendqueue[end].current_time = source->current_time;
		end = (end + 1) % 50;
		sendqueue[end].id = source->id * 10 + 3;
		sendqueue[end].count = source->seq;
		sendqueue[end].readings[0] = source->HumidityData;
		sendqueue[end].version = version;
		sendqueue[end].interval = interval;
		sendqueue[end].current_time = source->current_time;
		end = (end + 1) % 50;
		call Leds.led0Toggle();
		return msg;
	}
	event message_t* SReceive.receive(message_t* msg, void* payload, uint8_t len) {
		oscilloscope_t *omsg = payload;
		if (omsg->version > version) {
			version = omsg->version;
			interval = omsg->interval;
			call UpdateI.change(&interval);
		}
		return msg;
	}
	event void readTemp.readDone(error_t result, uint16_t val){
		if(result == SUCCESS){
			val = -40.1 + 0.01*val;
			TempData = val;
		}
		else{
			TempData = 0xffff;
		}
		local.TempData = TempData;
		call Leds.led0Toggle();
	}
	event void readHumidity.readDone(error_t result, uint16_t val){
		if(result == SUCCESS){
			HumidityData = -4 + 4*val/100 + (-28/1000/10000)*(val*val);
			HumidityData = (TempData-25)*(1/100+8*val/100/1000)+HumidityData;
		}
		else{
			HumidityData = 0xffff;
		}
		local.HumidityData = HumidityData;
		call Leds.led1Toggle();
	}
	event void readPhoto.readDone(error_t result, uint16_t val){
		if(result == SUCCESS){
			PhotoData = val;
		}
		else{
			PhotoData = 0xffff;
		}
		local.PhotoData = PhotoData;
		call Leds.led2Toggle();
	}
	event void ValueI.changed() {
		const uint16_t* newInterval = call ValueI.get();
		interval = *newInterval;
		if (TOS_NODE_ID != 1){
			call Timer0.startPeriodic(interval);
		}
	}
}
