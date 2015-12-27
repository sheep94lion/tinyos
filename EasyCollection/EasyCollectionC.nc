#include <Timer.h>
#include "EasyCollection.h"
#include "SensirionSht11.h"
module EasyCollectionC {
	uses interface Boot;
	uses interface SplitControl as RadioControl;
	uses interface SplitControl as AMControl;
	uses interface StdControl as RoutingControl;
	uses interface StdControl as DisseminationControl;
	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as Timer1;
	uses interface RootControl;
	uses interface Receive as SReceive;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
}
implementation {
	uint16_t count=0;
    uint16_t nodeid;
    uint16_t pre_seq_num = 0;
    uint16_t qh = 0, qt = 0;
    uint32_t handle_integer[2001];
    uint32_t* handle_integerp;
    uint32_t sum;
    uint32_t min;
    uint32_t max;
    bool busy = FALSE;
    bool isLost = FALSE;
    bool medianstart = FALSE;
    message_t pkt;
    message_t package;
    message_t rp;

    uint8_t remain;
    uint16_t check = 1;
    Inte inte;
    Inte fixinte;
    uint16_t hstart;
    uint16_t hend;
    uint16_t len;
    uint8_t hready = 0;
    uint16_t rank;
    uint16_t imedian;
    uint16_t pmedian;


	event void Boot.booted(){
		uint16_t i = 0;
		nodeid = TOS_NODE_ID;
        sum = 0;
        max = 0;
        min = 0xffffffff;
        for(i = 0; i < 2000; i++){
            handle_integer[i] = 0xffffffff;
        }
		call RadioControl.start();
		call AMControl.start();
	}

	event void RadioControl.startDone(error_t err){
		if (err != SUCCESS)
			call RadioControl.start();
	}

	event void AMControl.startDone(error_t err){
		if  (err != SUCCESS) {
			call AMControl.start();
		} else {
			
		}
	}

	event void RadioControl.stopDone(error_t err) {}

	event void AMControl.stopDone(error_t err) {}

	event void AMSend.sendDone(message_t* msg, error_t error) {
		if (&rp == msg) {
			busy = FALSE;
		}

	}


	event void Timer0.fired() {
		if(!busy) {
			if (call AMSend.send(AM_DAMASTER, &rp, sizeof(Value)) == SUCCESS) {
				call Leds.led0Toggle();
                busy = TRUE;
            }
		}
		

	}

	event void Timer1.fired() {

	}
    

	void result() {
		uint16_t i, j;
		uint32_t temp;
		uint32_t pre, old, item;
		Value* ecpkt = (Value*)(call Packet.getPayload(&rp, NULL));
		handle_integer[0] = handle_integer[2000];
		call Leds.led2Toggle();

		for (i = 1; i < 2000; i++) {
			for (j = i; j >= 1; j--) {
				if (handle_integer[j] < handle_integer[j - 1]){
					temp = handle_integer[j];
					handle_integer[j] = handle_integer[j-1];
					handle_integer[j-1]=temp;
				} else {
					break;
				}
			}
		}
		pre = handle_integer[999];
		old = handle_integer[1000];
		ecpkt->group_id = 17;
		ecpkt->max = handle_integer[1999];
		ecpkt->min = handle_integer[0];
		sum = 0;
		for (i = 0; i < 2000; i++) {
			sum = sum + handle_integer[i];
		}
		ecpkt->sum = sum;
		ecpkt->average = sum / 2000;
		ecpkt->median = (old + pre) / 2;
		call Timer0.startPeriodic(100);
		call Leds.led2Toggle();
	}
	/*
	void checkinte(){
		
		for (; check <= 2000; check++) {
			if (handle_integer[check] == 0xffffffff) {
				break;
			}
		}
		if (check > 2000) {
			result();
			return;
		}
		inte.flag = 0;
		inte.seq = check;
		inte.num = 0;
		call Leds.led0Toggle();
	}
	*/
	void ccheck(){
		uint16_t i;
		call Leds.led0Toggle();
		for (i = 1; i <= 2000; i++){
			if (handle_integer[i] == 0xffffffff) {
				count = 0;
				return;
			}
		}
		result();
	}
	event message_t* SReceive.receive(message_t* msg, void* payload, uint8_t length) {
		Data* data = (Data*) payload;
		if(call AMPacket.source(msg) != 1000){
			return msg;
		}
		call Leds.led1Toggle();
		
		if (count == 2000) {
			ccheck();
			count++;
			return msg;
		}
		if (count > 2000){
			count++;
			return msg;
		}
		
		count++;
		handle_integer[data->sequence_number] = data->random_integer;

		/*(if (count == 2000) {
			checkinte();	
		}*/
		return msg;

	}

}
