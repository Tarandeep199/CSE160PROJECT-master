#include "../../includes/packet.h"

interface Flooding{
   //command void start();
   command error_t floodOut(pack *message);
   //command void neighborReceived(pack *myMsg);
   //command error_t send(pack msg, uint16_t dest );
}
