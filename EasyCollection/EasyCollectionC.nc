#include <Timer.h>
#include "EasyCollection.h"
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

}
implementation {
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
		msg->data = 0xAAAA;

		if (call Send.send(&packet, sizeof(EasyCollectionMsg)) != SUCCESS)
			call Leds.led0On();
		else
			sendBusy = TRUE;
	}

	event void Timer.fired() {
		call Leds.led2Toggle();
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
			if (call AMSend.send(AM_BROADCAST_ADDR, &serialpacket, sizeof(EasyCollectionMsg)) == SUCCESS) {
                			SerialSendBusy = TRUE;
            			}
		}
		return msg;
	}
}