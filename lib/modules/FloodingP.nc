/**
 * ANDES Lab - University of California, Merced
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include "../../includes/packet.h"
#include "../../includes/sendInfo.h"
#include "../../includes/channels.h"

/*  Neighbor entry
 *      Neighbor reference(Unknown. Packet?)
 *      Quality of link(float?)
 *      Active(bool)
 */



generic module FloodingP(){
    // provides shows the interface we are implementing. See lib/interface/Flooding.nc
    // to see what funcitons we need to implement.
    provides interface Flooding;

    uses interface SimpleSend as sender;
    uses interface Receive;

    //uses interface Timer<TMilli> as sendTimer;
    uses interface Random as Random;

    uses interface Hashmap<pack> as messagesReceived;
    uses interface Packet;
}

implementation{
    uint16_t sequenceNum = 0;
    //uint16_t number;
    bool busy = FALSE;
    pack pkt;

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }

    command error_t Flooding.floodOut(pack *message){
        //logPack(message);
        //uint32_t* sequences = call messagesReceived.getKeys();
        //uint16_t i = 0;
        call messagesReceived.insert((uint32_t) message -> seq, *message);
        //for(i = 0; i < 3; i++){
        //    dbg(FLOODING_CHANNEL,"Sequence %d\n", *(sequences + i));
        //}
        makePack(&pkt, TOS_NODE_ID, AM_BROADCAST_ADDR, message -> TTL, PROTOCOL_PING, message -> seq, message -> payload, PACKET_MAX_PAYLOAD_SIZE);
        dbg(FLOODING_CHANNEL, "[SENDING PACKET]Broadcasting sequence %d from node %d!\n\n", message -> seq, TOS_NODE_ID);
        call sender.send(*message, AM_BROADCAST_ADDR);
    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
        
        pack* myMsg=(pack*) payload;
        uint16_t newTTL = myMsg -> TTL - 1;
        uint32_t* sequences = call messagesReceived.getKeys();
        uint16_t i = 0;
        dbg(FLOODING_CHANNEL, "[RECEIVING PACKET] Node %d received flooding packet from node %d for sequence %d. Beginning processing of data...\n", TOS_NODE_ID, myMsg -> src, myMsg -> seq);
        if(newTTL == 0){
            dbg(FLOODING_CHANNEL,"[DROPPING PACKET] The packet for sequence: %d has timed out.\n\n", myMsg -> seq);
            return msg;
        }
        //dbg(FLOODING_CHANNEL,"Printing out sequences seen of size %d:\n", call messagesReceived.size());
        
        //for(i = 0; i < 3; i++){
        //    dbg(FLOODING_CHANNEL,"Sequence %d\n", *(sequences + i));
        //}

        if(call messagesReceived.contains(myMsg -> seq)){ //Checks to see if the message we recieved is from the person we wanted MESSAGE RECIEVED METHOD
            dbg(FLOODING_CHANNEL,"[DROPPING PACKET] Node %d has received message for sequence: %d already!\n\n", TOS_NODE_ID, myMsg -> seq);
            return msg;
        }
        
        //call messagesReceived.insert((uint32_t) myMsg -> seq, *myMsg);
        //for(i = 0; i < 3; i++){
        //    dbg(FLOODING_CHANNEL,"Sequence %d\n", *(sequences + i));
        //}
        makePack(&pkt, TOS_NODE_ID, AM_BROADCAST_ADDR, newTTL, PROTOCOL_PING, myMsg -> seq, payload, PACKET_MAX_PAYLOAD_SIZE);
        //dbg(FLOODING_CHANNEL, "[SENDING PACKET]Broadcasting sequence %d from node %d!\n\n", myMsg -> seq, TOS_NODE_ID);

        call Flooding.floodOut(&pkt);
        return msg;
    }
    /*
    event void AMSend.sendDone(message_t* msg, error_t error){
      //Clear Flag, we can send again.
      if(&pkt == msg){
         busy = FALSE;
         postSendTask();
      }
    }*/
}
