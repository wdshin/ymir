#include "OgreEvent.h"

extern "C" {
#include <gen_cnode.h>
}

using namespace OIS;

bool OgreEvent::keyPressed( const KeyEvent& e ){
    ei_x_buff key = {0};

    ei_x_new(&key);

    gen_cnode_format(&key, "~i", e.key);
    
    gen_cnode_notify("keyPressed", &key);

    ei_x_free(&key);

    return true;
}

bool OgreEvent::keyReleased( const KeyEvent& e ){
    ei_x_buff key = {0};

    ei_x_new(&key);

    gen_cnode_format(&key, "~i", e.key);
    
    gen_cnode_notify("keyReleased", &key);

    ei_x_free(&key);

    return true;
}

bool OgreEvent::mouseMoved( const MouseEvent& e ){
    ei_x_buff event = {0};

    ei_x_new(&event);

    encodeMouseEvent((MouseButtonID)0, e, &event);

    gen_cnode_notify("mouseMoved", &event);

    ei_x_free(&event);

    return true;
}

bool OgreEvent::mousePressed( const MouseEvent& e, MouseButtonID id ){
    ei_x_buff event = {0};

    ei_x_new(&event);

    encodeMouseEvent(id, e, &event);

    gen_cnode_notify("mousePressed", &event);

    ei_x_free(&event);

    return true;
}

bool OgreEvent::mouseReleased( const MouseEvent& e, MouseButtonID id ){
    ei_x_buff event = {0};

    ei_x_new(&event);

    encodeMouseEvent(id, e, &event);

    gen_cnode_notify("mouseReleased", &event);

    ei_x_free(&event);
    return true;
}

//Exported utility functions
int OgreEvent::encodeMouseEvent( MouseButtonID id,
                                 const MouseEvent& event, 
                                 ei_x_buff* output ){

    if( ei_x_encode_tuple_header(output, 2) ||
        ei_x_encode_ulong(output, id) ||
        ei_x_encode_list_header(output, 3) ||
        
        //Encode X position
        ei_x_encode_tuple_header(output, 2) ||
        ei_x_encode_long(output, event.state.X.abs) ||
        ei_x_encode_long(output, event.state.X.rel) ||

        //Encode Y position
        ei_x_encode_tuple_header(output, 2) ||
        ei_x_encode_long(output, event.state.Y.abs) ||
        ei_x_encode_long(output, event.state.Y.rel) ||

        //Encode Z position
        ei_x_encode_tuple_header(output, 2) ||
        ei_x_encode_long(output, event.state.Z.abs) ||
        ei_x_encode_long(output, event.state.Z.rel) ||
       
        //Encode end of list 
        ei_x_encode_empty_list(output) ) 
    {
        return -1;
    }

    return 0;
}
