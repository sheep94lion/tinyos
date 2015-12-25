#ifndef EASYCOLLECTION_H
#define EASYCOLLECTION_H

enum {
	AM_EASYCOLLECTIONMSG = 23,
	NREADINGS = 5
};

typedef nx_struct EasyCollectionMsg {
	nx_uint16_t id;
	nx_uint16_t count;
	nx_uint16_t reading[NREADINGS];
} EasyCollectionMsg;

#endif