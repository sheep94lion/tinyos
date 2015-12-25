#ifndef EASYCOLLECTION_H
#define EASYCOLLECTION_H

enum {
	AM_EASYCOLLECTIONMSG = 23
};

typedef nx_struct EasyCollectionMsg {
	nx_uint16_t nodeid;
	nx_uint16_t data;
	nx_uint16_t TempData;
	nx_uint16_t HumidityData;
	nx_uint16_t PhotoData;
} EasyCollectionMsg;

#endif