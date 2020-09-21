#include "../../includes/am_types.h"

generic configuration FloodingC(){
    provides interface Flooding;
    //uses interface Hashmap<pack> as messagesReceivedC;
}

implementation{
    components new FloodingP();
    Flooding = FloodingP.Flooding;

    components new SimpleSendC(AM_FLOODING);
    FloodingP.sender -> SimpleSendC;
    components new AMReceiverC(AM_FLOODING);
    FloodingP.Receive -> AMReceiverC;


    //components new TimerMilliC() as sendTimer;
    //FloodingP.sendTimer -> sendTimer;
    
    components RandomC as Random;
    FloodingP.Random -> Random;

    components new HashmapC(pack, 20) as messagesReceivedC;
    FloodingP.messagesReceived -> messagesReceivedC;
}
