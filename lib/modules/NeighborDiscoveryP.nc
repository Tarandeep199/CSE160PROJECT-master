#include "../../includes/packet.h"
#include "../../includes/sendInfo.h"
#include "../../includes/channels.h"


generic module NeighborDiscoveryP(){

    provides interface NeighborDiscovery;

    uses interface Timer<TMilli> as neighborTimer;
    //ONLY UTILIZE PING, REPLY, FLOODING AND TTL
    uses interface SimpleSend as sendTimer;
    uses interface Receive;

    uses interface Hashmap<neighbor> as neighborhood;
    
}

implementation{

    //IF THE RECIEVER DOESNT REPSOND AT LEAST 5 TIMES THEN THEY ARE DROPPED FROM NEIGHBOR LIST
    uint16_t dropThreshold = 5;
    bool busy = FALSE;
    message_t pkt;




    //SETS UP THE PACKET HEADERS THAT WILL BE SENT FROM NODE TO NODE
    void makePack(pack *msg, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        neighborPackage->src = src;
        neighborPackage->dest = AM_BROADCAST_ADDR;
        neighborPackage->TTL = TTL;
        neighborPackage->seq = seq;
        neighborPackage->protocol = NEWMESSAGE;
        memcpy(neighborPackage->payload, "NEIGHBOR DISVORY PAYLOAD!!!", length);
    }



    //TIMER IMPLEMENTATION TO AVOID COLLISIONS
    command void NeighborDiscovery.delay() {
        dbg(GENERAL_CHANNEL,"DELAYING TASK....\n");
		call discoveryTimer.find(1000);
	}




    //FLOODS PACKET WITH SPECIFIC SEQ NUM 
    command void NeighborDiscovery.sendMessage(pack *msg){

        makePack(&pkt, TOS_NODE_ID, AM_BROADCAST_ADDR, message -> TTL, PROTOCOL_PING, message -> seq, message -> payload, PACKET_MAX_PAYLOAD_SIZE);
        dbg(NEIGHBOR_CHANNEL, "[SENDING PACKET]Broadcasting sequence %d from node %d!\n\n", message -> seq, TOS_NODE_ID);
        //FLOODING DONE HERE
        call sender.send(*msg, AM_BROADCAST_ADDR);
    }



    ///SORTS THE REPLY RECIEVED
    command void NeighborDiscovery.replydechipher(pack *msg){
        msg -> protocol = statusCode;
        
        if(statusCode == NEWMESSAGE){
            call neighborhood.insert(msg->src,dropThreshold);
            dbg(NEIGHBOR_CHANNEL, "NEW NEIGHBOR DISCOVERY/.... %d Added to list!\n",msg->src);
            msg ->src = TOS_NODE_ID;
            msg ->protocol = PROTOCOL_PINGREPLY;
            call Sender.send(*msg, AM_BROADCAST_ADDR);
            return;
        }
        else
        {
            call neighborhood.insert(msg->src, dropThreshold);
            dbg("%d added to neighbor list !", msg->src);
            return;
        }

    }



    void dropCheck()
    {   
        unit32_t* neighborhoods = call neighborhood.getKeys();
        for(uint16_t i = 0; i < call neighborhood.size(); i++)
        {
            uint16_t timeout = call neighborhood.get(neighborhoods[i]);
            call neighborhood.insert(neighborhoods[i],timeout - 1);

            if(timeout - 1 <= 0){
                uint32_t dropped = neighborhood[i]; 
                call neighborhood.remove(neighborhood[i]);
                dbg(NEIGHBOR_CHANNEL,"%d Dropped from Neighbor List!",dropped);
            }

        } 

    }


    command void NeighborDiscovery.find(){
        pack msg;
        dropCheck();
        makePack(&msg);
        call Sender.send(msg,AM_BROADCAST_ADDR);
    }


}
