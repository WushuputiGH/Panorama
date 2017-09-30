//
//  Header.h
//  全景_图片
//
//  Created by huang.ziyang on 16/8/4.
//  Copyright © 2016年 H. All rights reserved.
//

#ifndef Header_h
#define Header_h


#define ES_PI  (3.14159265f)
#define MAX_OVERTURE 95.0
#define MIN_OVERTURE 25.0
#define DEFAULT_OVERTURE 85.0
#define ES_PI  (3.14159265f)
#define ROLL_CORRECTION ES_PI/2.0
#define FramesPerSecond 30
#define SphereSliceNum 200
#define SphereRadius 1.0
#define SphereScale 300

// For digital component video the color format YCbCr is used.
// ITU-R BT.709, which is the standard for HDTV.
// http://www.equasys.de/colorconversion.html
const GLfloat kColorConversion709[] = {
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
};

// Uniform index.
enum {
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_Y,
    UNIFORM_UV,
    UNIFORM_COLOR_CONVERSION_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];


#endif /* Header_h */
