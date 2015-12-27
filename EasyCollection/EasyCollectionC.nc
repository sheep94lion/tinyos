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
	uses interface DisseminationValue<Inte> as ValueI;
	uses interface DisseminationUpdate<Inte> as UpdateI;
}
implementation {
	uint16_t count=0;
    uint16_t nodeid;
    uint16_t pre_seq_num = 0;
    uint16_t qh = 0, qt = 0;
    uint32_t handle_integer[2001];
    uint32_t* handle_integerp;
    uint32_t* handle_integer0;
    uint32_t* handle_integer1;
    uint32_t* handle_integer2;
    uint16_t in0, in1, in2;
    uint16_t out1, out2, out0;
    uint32_t sum;
    uint32_t min;
    uint32_t max;
    bool busy = FALSE;
    bool isLost = FALSE;
    bool medianstart = FALSE;
    message_t pkt;
    message_t package;
    message_t rp;
    message_t query[12];
    uint8_t start;
    uint8_t end;
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
			call DisseminationControl.start();
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
                busy = TRUE;
            }
		}
		

	}

	event void Timer1.fired() {

	}

	

	void calculate_receive(uint32_t num){
        sum += num;
        if(num < min){
            min = num;
        }
        if(num > max){
            max = num;
        }
    }
    void Heapfy(uint32_t A[], uint16_t idx, uint16_t length){
        uint16_t left = idx * 2 + 1;
        uint16_t right = left + 1;
        uint16_t largest = idx;
        uint32_t temp;
        if(left < length && A[left] > A[idx]){
            largest = left;
        }
        if(right < length && A[largest] < A[right]){
            largest = right;
        }
        if(largest != idx){
            temp = A[largest];
            A[largest] = A[idx];
            A[idx] = temp;
            Heapfy(A, largest, length);
        }
    }
    void buildHeap(uint32_t A[], uint16_t length){
    	uint16_t i;
        for(i = length / 2 - 1; i >= 0; i--){
            Heapfy(A, i, length);
        }
    }
    

	void result() {
		uint16_t i;
		uint32_t pre, old, item;
		Value* ecpkt = (Value*)(call Packet.getPayload(&rp, NULL));
		handle_integerp = &handle_integer[1];
		buildHeap(handle_integerp, 2000);
		call Leds.led1Toggle();

		for (i = 0; i < 2000; i++) {
			item = handle_integerp[0];
			handle_integerp[0] = handle_integerp[len];
			len--;
			Heapfy(handle_integerp, 0, len);
			if (i == 999) {
				pre = item;
			}
			if (i == 1000) {
				old = item;
				break;
			}
		}
		ecpkt->group_id = 17;
		ecpkt->max = max;
		ecpkt->min = min;
		ecpkt->sum = sum;
		ecpkt->average = sum / 2000;
		ecpkt->median = (old + pre) / 2;
		call Timer0.startPeriodic(100);
	}
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
		call UpdateI.change(&inte);
		call Leds.led0Toggle();
	}
	event message_t* SReceive.receive(message_t* msg, void* payload, uint8_t length) {
		Data* data = (Data*) payload;
		call Leds.led2Toggle();
		count++;
		handle_integer[data->sequence_number] = data->random_integer;
		calculate_receive(data->random_integer);
		if (count == 2000) {
			checkinte();
			
		}
		return msg;
	}

	
	event void ValueI.changed() {
		const Inte* newInte = call ValueI.get();
		if (newInte->flag == 1 && newInte->seq == check){
			//call Leds.led0Toggle();
			handle_integer[newInte->seq] = newInte->num;
			checkinte();
			//call Leds.led0Toggle();
		} else {
			//call Leds.led1Toggle();
			
			//call Leds.led0Toggle();
			fixinte.flag = 1;
			fixinte.seq = newInte->seq;
			fixinte.num = handle_integer[newInte->seq];
			call UpdateI.change(&fixinte);
		}
	}
}
