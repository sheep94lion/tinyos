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
	uses interface DisseminationValue<Inte> as ValueI;
	uses interface DisseminationUpdate<Inte> as UpdateI;
}
implementation {
	uint16_t count=0;
    uint16_t nodeid;
    uint16_t pre_seq_num = 0;
    uint16_t qh = 0, qt = 0;
    uint32_t handle_integer[2001];
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
		nodeid = TOS_NODE_ID;
        sum = 0;
        max = 0;
        min = 0xffffffff;
        for(uint16_t i = 0; i < 2000; i++){
            handle_integer[i] = 0xffffffff;
        }
		call RadioControl.start();
		call AMControl.start();
	}

	event void RadioControl.startDone(error_t err){
		if (err != SUCCESS)
			call RadioControl.start();
		else {
			call RoutingControl.start();
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
		if (&rp == msg) {
			busy = FALSE;
		}
		/*
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
		*/
	}


	event void Timer0.fired() {
		if(!busy) {
			if (call AMSend.send(AM_DAMASTER, &rp, sizeof(Value)) == SUCCESS) {
                busy = TRUE;
            }
		}
		
		/*
		seq++;
		local.seq = seq;
		call readPhoto.read();
		call readHumidity.read();
		call readTemp.read();
		current_time = call Timer0.getNow();
		local.current_time = current_time;

		sendMessage();
		*/
	}

	event void Timer1.fired() {
		/*
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
		*/
	}

	event void Send.sendDone(message_t* m, error_t err) {
		
		//sendBusy = FALSE;
		
	}

	task void calculate_receive(uint32_t num){
        sum += num;
        if(num < min){
            min = num;
        }
        if(num > max){
            max = num;
        }
    }
    void buildHeap(uint32_t A[], uint16_t len){
    	uint16_t i;
        for(i = len / 2 - 1; i >= 0; i--){
            Heapfy(A, i, len);
        }
    }
    void Heapfy(uint32_t A[], uint16_t idx, uint16_t len){
        uint16_t left = idx * 2 + 1;
        uint16_t right = left + 1;
        uint16_t largest = idx;
        uint32_t temp;
        if(left < len && A[left] > A[idx]){
            largest = left;
        }
        if(right < len && A[largest] < A[right]){
            largest = right;
        }
        if(largest != idx){
            temp = A[largest];
            A[largest] = A[idx];
            A[idx] = temp;
            Heapfy(A, largest, len);
        }
    }
    /*
    void heap(){
    	uint16_t i;
    	for (i = 0; i < 667; i++) {
    		if (remain == 0){
    			handle_integer[i] = handle_integer[i*3+remain]
    		} else {
    			handle_integer[i+1] = handle_integer[i*3+remain]
    		}
    	}
    	handle_integer = handle_integer + 1;
    	if (remain == 0) {
    		len = 666;
    	} else {
    		len = 667;
    	}
    	buildHeap(handle_integer, len);
    	ValueH.change(&hready);
    }
    */
    /*
    void median(){
    	Median* msg = (Median*)call Send.getPayload(&package, sizeof(Median));
    	msg->num = handle_integer[0];
    	msg->remain = remain;
    	handle_integer[0] = handle_integer[len - 1];
    	len--;
    	if (len > 0)
    		Heapfy(handle_integer, 0, len);
    	call Send.send(&package, sizeof(Median));   	
    }
    */
    /*
	event message_t* CReceive.receive(message_t* msg, void* payload, uint8_t len) {
		//call Leds.led0Toggle();

		return msg;
	}
	*/
	event message_t* SReceive.receive(message_t* msg, void* payload, uint8_t len) {
		Data* data = (Data*) payload;
		if (count <= 2000) {
			handle_integer[data.sequence_number] = data.random_integer;
			count++;
			post calculate_receive(data.random_integer);
			if (count == 2000) {
				checkinte();
				count++;
			}
		}
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
		call ValueI.change(&inte);
	}
	void result() {
		uint16_t i;
		uint32_t pre, old, item;
		handle_integer = handle_integer+1;
		buildHeap(handle_integer, 2000);
		for (i = 0; i < 2000; i++) {
			item = handle_integer[0];
			handle_integer[0] = handle_integer[len];
			len--;
			Heapfy(handle_integer, 0, len);
			if (i == 999) {
				pre = item;
			}
			if (i == 1000) {
				old = item;
				break;
			}
		}
		Value* ecpkt = (Value*)(call Packet.getPayload(&rp, NULL));
		ecpkt.group_id = 17;
		ecpkt.max = max;
		ecpkt.min = min;
		ecpkt.sum = sum;
		ecpkt.average = sum / 2000;
		ecpkt.median = (old + pre) / 2;
		call Timer0.startPeriodic(100);
	}
	event void ValueI.changed() {
		const Inte* newInte = call ValueI.get();
		if (newInte->flag == 1 && newInte->seq == check){
			handle_integer[newInte->seq] = newInte->num;
			checkinte();
		} else {
			if (handle_integer[newInte->seq] != 0xffffffff){
				fixinte.flag = 1;
				fixinte.seq = newInte->seq;
				fixinte.num = handle_integer[newInte->seq];
				ValueI.change(&fixinte);
			}
		}
	}
}
