#include <Timer.h>
#include "EasyCollection.h"
#include "SensirionSht11.h"
module EasyCollectionC {
	uses interface Boot;
	uses interface SplitControl as RadioControl;
	uses interface SplitControl as AMControl;
	uses interface StdControl as RoutingControl;
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
}
implementation {
	uint16_t data = 0;
	uint16_t TempData = 0;
	uint16_t HumidityData = 0;
	message_t packet;
	message_t serialpacket;
	bool sendBusy = FALSE;
	bool SerialSendBusy = FALSE;

	event void Boot.booted(){
		call RadioControl.start();
		call AMControl.start();
	}

	event void RadioControl.startDone(error_t err){
		if (err != SUCCESS)
			call RadioControl.start();
		else {
			call RoutingControl.start();
			if (TOS_NODE_ID == 1)
				call RootControl.setRoot();
			else
				call Timer.startPeriodic(2000);
		}
	}

	event void AMControl.startDone(error_t err){
		if  (err != SUCCESS) {
			call AMControl.start();
		}
	}

	event void RadioControl.stopDone(error_t err) {}

	event void AMControl.stopDone(error_t err) {}

	event void AMSend.sendDone(message_t* msg, error_t error) {
		if (&serialpacket == msg) {
			SerialSendBusy = FALSE;
		}
	}

	void sendMessage() {
		EasyCollectionMsg* msg = (EasyCollectionMsg*)call Send.getPayload(&packet, sizeof(EasyCollectionMsg));
		msg->data = data;
		msg->nodeid = TOS_NODE_ID;
		msg->TempData = TempData;
		msg->HumidityData = HumidityData;

		if (call Send.send(&packet, sizeof(EasyCollectionMsg)) != SUCCESS){
			call Leds.led0Toggle();
			call Leds.led1Toggle();
			call Leds.led2Toggle();
		}
		else
			sendBusy = TRUE;
	}

	event void Timer.fired() {
		data++;
		call Leds.led2Toggle();
		call readTemp.read();
		call readHumidity.read();
		if (!sendBusy)
			sendMessage();
	}

	event void Send.sendDone(message_t* m, error_t err) {
		if (err != SUCCESS)
			call Leds.led0On();
		sendBusy = FALSE;
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		call Leds.led1Toggle();
		if (!SerialSendBusy) {
			EasyCollectionMsg* source = (EasyCollectionMsg*) payload;
			EasyCollectionMsg* ecpkt = (EasyCollectionMsg*)(call Packet.getPayload(&serialpacket, NULL));
			ecpkt->data = source->data;
			ecpkt->nodeid = source->nodeid;
			ecpkt->TempData = source->TempData;
			ecpkt->HumidityData = source -> HumidityData;
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
        }
        else{
            TempData = 0xffff;
        }
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
        call Leds.led1Toggle();
    }
}