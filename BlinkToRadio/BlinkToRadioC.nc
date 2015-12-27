#include <Timer.h>
#include "BlinkToRadio.h"
module BlinkToRadioC {
    uses interface Boot;
    uses interface Timer<TMilli> as Timer;
    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend;
    uses interface Receive;
    uses interface Leds;
    uses interface SplitControl;
}
implementation {
    uint16_t count=0;
    uint16_t nodeid;
    uint16_t pre_seq_num = 0;
    uint16_t qh = 0, qt = 0;
    uint32_t handle_integer[700];
    uint32_t store_integer[700];
    uint32_t heap_integer[700];
    uint32_t sum;
    uint32_t min;
    uint32_t max;
    bool busy = FALSE;
    bool isLost = FALSE;
    message_t pkt;
    message_t query[12];
    


    event void Boot.booted(){
        nodeid = TOS_NODE_ID;
        sum = 0;
        max = 0;
        min = 0xffffffff;
        for(uint16_t i = 0; i < 700; i++){
            handle_integer[i] = 0xffffffff;
            store_integer[i] = 0xffffffff;
            heap_integer[i] = 0xffffffff;
        }
        call AMControl.start();
    }

    event void AMControl.startDone(error_t err) {
        if (err == SUCCESS) {
            call Timer0.startPeriodic(TIMER_PERIOD_MILLLI);
        }
        else {
            call AMControl.start();
        }
    }

    event void Timer0.fired(){
        counter++;
        if (!busy) {
            BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*) (call Packet.getPayload(&pkt, NULL));
            btrpkt->nodeid = MOTE_ID;
            btrpkt->counter = counter;
            if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
                busy = TRUE;
            }
        }
    }
    event void AMControl.stopDone(error_t err) {
    }
    event void AMSend.sendDone(message_t* msg, error_t error) {
        if (&pkt == msg) {
            busy = FALSE;
        }
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

    void buildHeap(uint32_t A[]){
        uint16_t len = count;
        for(uint16_t i = len / 2 - 1; i >= 0; i--){
            Heapfy(A, i, len);
        }
    }
    void Heapfy(uint32_t A[], uint16_t idx, uint16_t len){
        uint16_t left = idx * 2 + 1;
        uint16_t right = left + 1;
        uint16_t largest = idx;
        if(left < len && A[left] > A[idx]){
            largest = left;
        }
        if(right < len && A[largest] < A[right]){
            largest = right;
        }
        if(largest != idx){
            uint32_t temp = A[largest];
            A[largest] = A[idx];
            A[idx] = temp;
            Heapfy(A, largest, len);
        }
    }

    task void sendQuery(){
        Query* dp = (Query*)call Packet.getPayload(&query[qt], sizeof(Query));
        if(SUCCESS != call AMSend.send(AM_DAMASTER, &query[qt], sizeof(Query)))
            post sendQuery();
        else {
            call Leds.led1Toggle();
        }
    }
    void query_in(Query* dp){
        if((qh+1)%12 == qt)
            return;
        memcpy(call Packet.getPayload(&query[qh], sizeof(Query)), dp, sizeof(Query));
        qh = (qh+1)%12;
    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
        //if (call AMPacket.source(msg) == 1000 && len == sizeof(Data)) {
        if (len == sizeof(Data)) { // pkg from node 1000
            Data* datapkt = (Data*)payload;
            uint16_t seq_num = datapkt->sequence_number;
            uint32_t rand_int = datapkt->random_integer;
            if(nodeid % 3 == seq_num % 3){
                if(handle_integer[seq_num / 3] != 0xffffffff){
                    return msg;
                }
                handle_integer[seq_num / 3] = rand_int;
                post calculate_receive(rand_int);
                count++;
                if(seq_num != pre_seq_num + 3){
                    isLost = TRUE;
                    for(uint16_t i = pre_seq_num + 3; i < seq_num; i = i + 3){
                        if(handle_integer[i] != 0xffffffff){
                            continue;
                        }
                        else{
                            Query dp;
                            dp.sequence_number = i;
                            query_in(&dp);
                            post sendQuery();
                        }
                    }
                }
                pre_seq_num = seq_num;
            }
            if(nodeid % 3 == (seq_num % 3 + 1) % 3){
                store_integer[seq_num / 3] = read_int;
            }
        }//else if (call AMPacket.source(msg) == 49 || call AMPacket.source(msg) == 50 || call AMPacket.source(msg) == 51){
        else if (len == sizeof(Query)){ // pkg from neighbors
            Query* datapkt = (Query*)payload;
            uint16_t seq_num = datapkt->sequence_number;
            if(nodeid % 3 == (seq_num % 3 + 1) % 3){
                Data num_data;
                num_data.sequence_number = seq_num;
                num_data.random_integer = store_integer[seq_num / 3];
            }
        }
        return msg;
    }
}