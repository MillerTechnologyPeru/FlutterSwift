// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef __APPLE__

#include <assert.h>
#include <stdlib.h>

#include <map>
#include <mutex>
#include <string>
#include <thread>

// FIXME: how can we include <Block/Block.h>
extern "C" {
    extern void *_Block_copy(const void *aBlock);
    extern void _Block_release(const void *aBlock);
};

#include "CxxFlutterSwift.h"

// +1 on block because it goes out of scope and is only called once

static void FlutterDesktopMessengerBinaryReplyThunk(const uint8_t* data,
                                                    size_t data_size,
                                                    void* user_data) {
    auto replyBlock = (FlutterDesktopBinaryReplyBlock)user_data;
    replyBlock(data, data_size);
    _Block_release(replyBlock);
}

bool FlutterDesktopMessengerSendWithReplyBlock(
    FlutterDesktopMessengerRef messenger,
    const char* channel,
    const uint8_t* message,
    const size_t message_size,
    FlutterDesktopBinaryReplyBlock replyBlock) {
    return FlutterDesktopMessengerSendWithReply(messenger,
                                                channel,
                                                message,
                                                message_size,
                                                replyBlock ? FlutterDesktopMessengerBinaryReplyThunk : nullptr,
                                                replyBlock ? _Block_copy(replyBlock) : nullptr);
}

static std::map<std::string, const void *>
flutterSwiftCallbacks{};
static std::mutex
flutterSwiftCallbacksMutex;

static void FlutterDesktopMessageCallbackThunk(
    FlutterDesktopMessengerRef messenger,
    const FlutterDesktopMessage *message,
    void* user_data) {
    auto block = (FlutterDesktopMessageCallbackBlock)user_data;
    block(messenger, message);
}

void FlutterDesktopMessengerSetCallbackBlock(
    FlutterDesktopMessengerRef messenger,
    const char* _Nonnull channel,
    FlutterDesktopMessageCallbackBlock callbackBlock) {
    std::lock_guard<std::mutex> guard(flutterSwiftCallbacksMutex);
    if (callbackBlock != nullptr) {
        flutterSwiftCallbacks[channel] = _Block_copy(callbackBlock);
        FlutterDesktopMessengerSetCallback(messenger, channel, FlutterDesktopMessageCallbackThunk, callbackBlock);
    } else {
        auto savedCallbackBlock = flutterSwiftCallbacks[channel];
        flutterSwiftCallbacks.erase(channel);
        _Block_release(savedCallbackBlock);
        FlutterDesktopMessengerSetCallback(messenger, channel, nullptr, nullptr);
    }
}

#endif /* !__APPLE__ */
