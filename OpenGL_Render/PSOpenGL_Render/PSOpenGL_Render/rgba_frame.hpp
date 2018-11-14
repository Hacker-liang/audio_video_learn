//
//  rgba_frame.hpp
//  PSOpenGL_Render
//
//  Created by 梁鹏帅 on 2018/11/13.
//  Copyright © 2018 梁鹏帅. All rights reserved.
//

#ifndef rgba_frame_hpp
#define rgba_frame_hpp

#include <stdio.h>

class RGBAFrame {
public:
    float position;
    float duration;
    u_int8_t * pixels;
    int width;
    int height;
    RGBAFrame();
    ~RGBAFrame();
    RGBAFrame *clone();
};

#endif /* rgba_frame_hpp */
