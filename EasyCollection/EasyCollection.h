#ifndef EASYCOLLECTION_H
#define EASYCOLLECTION_H

enum {
	AM_DAMASTER = 0,
	TIMER_PERIOD_MILLI = 250,
	GROUP_ID = 17
};

typedef nx_struct Data {
	nx_uint16_t sequence_number;
	nx_uint32_t random_integer;
} Data;

typedef nx_struct Value {
	nx_uint8_t group_id;
	nx_uint32_t max;
	nx_uint32_t min;
	nx_uint32_t sum;
	nx_uint32_t average;
	nx_uint32_t median;
} Value;

typedef nx_struct Median {
	nx_uint8_t remain;
	nx_uint32_t num;
} Median;

typedef nx_struct ACK {
	nx_uint8_t group_id;
} ACK;
typedef nx_struct Inte {
	nx_uint8_t flag;
	nx_uint16_t seq;
	nx_uint32_t num;
} Inte;

#endif