#include "../../includes/am_types.h"

generic configuration NeighborDiscoveryC(int channel){
    provides interface NeighborDiscovery;
    uses interface List<pack> as neighborListC;
}

implementation{
    components new NeighborDiscoveryP();
    NeighborDiscovery = NeighborDiscoveryP;

    components new SimpleSendC(AM_NEIGHBOR);
    NeighborDiscoveryP.Sender -> SimpleSendC;

    components new AMReceiverC(AM_NEIGHBOR);


    components new TimerMilliC() as sendTimer;
    NeighborDiscoveryP.sendTimer -> neigborDiscoveryTimer;
    

    components new HashmapC(uint16_t, 256) as neighborhood;
    NeighborDiscoveryP.Neighbors-> neighborhood;
}
