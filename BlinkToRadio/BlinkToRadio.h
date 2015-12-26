#ifndef BLINKTORADIO_H
#define BLINKTORADIO_H

enum{
    MOTE_ID = 2,
    AM_BLINKTORADIOMSG = 6,
    TIMER_PERIOD_MILLLI = 250
};

typedef nx_struct BlinkToRadioMsg {
    nx_uint16_t nodeid;
    nx_uint16_t counter;
    nx_uint32_t current_time;
} BlinkToRadioMsg;
#endif