#ifndef EASYCOLLECTION_H
#define EASYCOLLECTION_H

enum {
	AM_OSCILLOSCOPE = 0x93,
	NREADINGS = 1,
	DEFAULT_INTERVAL = 200
};

typedef nx_struct EasyCollectionMsg {
	nx_uint16_t id;
	nx_uint16_t seq;
	nx_uint16_t TempData;
	nx_uint16_t HumidityData;
	nx_uint16_t PhotoData;
} EasyCollectionMsg;

typedef nx_struct oscilloscope {
  nx_uint16_t version; 
  nx_uint16_t interval; 
  nx_uint16_t id; 
  nx_uint16_t count; 
  nx_uint16_t readings[NREADINGS];
} oscilloscope_t;

#endif