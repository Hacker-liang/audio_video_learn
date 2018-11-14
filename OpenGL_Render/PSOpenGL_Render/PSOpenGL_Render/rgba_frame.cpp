//
//  rgba_frame.cpp
//  PSOpenGL_Render
//
//  Created by 梁鹏帅 on 2018/11/13.
//  Copyright © 2018 梁鹏帅. All rights reserved.
//

#include "rgba_frame.hpp"
#include <string>

RGBAFrame::RGBAFrame() {
    position = 0.0;
    duration = 0.0;
    pixels = NULL;
    width = 0;
    height = 0;
}

RGBAFrame::~RGBAFrame() {
    if (NULL!=pixels) {
        delete [] pixels;
        pixels = NULL;
    }
}

RGBAFrame* RGBAFrame::clone() {
    RGBAFrame *ret = new RGBAFrame();
    ret->duration = this->duration;
    ret->width = this->width;
    ret->height = this->height;
    ret->position = this->position;
    int pixelsLength = this->width * this->height * 4;
    ret->pixels = new u_int8_t[pixelsLength];

    memcpy(ret->pixels, this->pixels, pixelsLength);
    return ret;
}
