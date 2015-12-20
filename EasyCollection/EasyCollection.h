#ifndef EASYCOLLECTION_H
#define EASYCOLLECTION_H

enum {
	AM_EASYCOLLECTIONMSG = 23
};

typedef nx_struct EasyCollectionMsg {
	nx_uint16_t data;
} EasyCollectionMsg;

#endif