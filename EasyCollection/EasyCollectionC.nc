#include <Timer.h>
module EasyCollectionC {
	uses interface Boot;
	uses interface SplitControl as RadioControl;
	uses interface StdControl as RoutingControl;
	uses interface Send;
	uses interface Leds;
	uses interface Timer<TMilli>;
	uses interface RootControl;
	uses interface Receive;
}
implementation {
	message_t packet;
	bool sendBusy = FALSE;

	typedef nx_struct EasyCollectionMsg {
		nx_uint16_t data;
	} EasyCollectionMsg;

	event void Boot.booted(){
		call RadioControl.start();
	}

	event void RadioControl.startDone(error_t err){
		if (err != SUCCESS)
			call RadioControl.start();
		else {
			call RoutingControl.start();
			if (TOS_NODE_ID == 1)
				call RootControl.setRoot();
			else
				call Timer.startPeriodic(2000);
		}
	}

	event
}