#pragma once
#import <Foundation/Foundation.h>
#include "session_state.hpp"

namespace mitaka::gui {
void decode_session_layers(NSDictionary *object, SessionState& state);
NSDictionary *encode_session_layers(const SessionState& state);
}
