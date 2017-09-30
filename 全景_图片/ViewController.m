//
//  ViewController.m
//  全景_图片
//
//  Created by huang.ziyang on 16/8/4.
//  Copyright © 2016年 H. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>
#define ES_PI  (3.14159265f)


 
@interface ViewController ()


@property (nonatomic, strong)EAGLContext *context; // 渲染环境
@property (nonatomic, assign)CGFloat overture; // 相机的广角角度


/// 索引数
@property (nonatomic, assign)int numIndices;

/// 顶点索引缓存指针
@property (nonatomic, assign)GLuint vertexIndicesBufferID;

/// 顶点缓存指针
@property (nonatomic, assign)GLuint vertexBufferID;

/// 纹理缓存指针
@property (nonatomic, assign)GLuint vertexTexCoordID;

/// 着色器
@property (nonatomic, strong)GLKBaseEffect *effect;

/// 图片的纹理信息
@property (nonatomic, strong)GLKTextureInfo *textureInfo;

/// 运动管理(加速器与陀螺仪)
@property (nonatomic, strong)CMMotionManager *motionManager;

/// 运动属性
//@property (nonatomic, strong)CMAttitude *referenceAttitude;

/// 模型坐标系
@property (nonatomic, assign)GLKMatrix4 modelViewMatrix;


/// 平移手势
@property (nonatomic, strong)UIPanGestureRecognizer *pan;
/// 平移时候x轴的偏移量
@property (nonatomic, assign)CGFloat panX;
@property (nonatomic, assign)CGFloat panY;

/// 缩放手势
@property (nonatomic, strong)UIPinchGestureRecognizer *pinch;
/// 缩放比例
@property (nonatomic, assign)CGFloat scale;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

    /// 使用ES2创建一个"EAGLContext"
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    /// 将“view”的context设置为这个“EAGLContext”实例的引用
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    /// 设置颜色格式和深度格式
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    self.preferredFramesPerSecond = 30;

    /// 设置GL
    [self setupGL];
    
    /// 检测屏幕位置(加速器与陀螺仪)
     [self startDeviceMotion];
    
    /// 添加手势
    [self addGestureRecognizer];
    
    
}


#pragma mark ---设置GL---

- (void)setupGL {
    
    /// 将此“EAGLContext”实例设置为OpenGL的“当前激活”的“Context”, 这样，以后所有“GL”的指令均作用在这个“Context”上
    [EAGLContext setCurrentContext:self.context];
    /// 激活“深度检测”: 注意, 设置深度检测一定要放在设置上一句的下面, 要不然context还没有激活
    glEnable(GL_DEPTH_TEST);
    
    
    /// 设置buffer
    [self setupBuffers];
    
}



- (void)setupBuffers{
    
    /// 顶点
    GLfloat *vVertices = NULL;
    
    /// 纹理
    GLfloat *vTextCoord = NULL;
    
    /// 索引
    GLushort *indices = NULL;
    
    int numVertices = 0;
    
    self.numIndices = esGenSphere(200, 1.0, &vVertices, &vTextCoord, &indices, &numVertices);
    
//    /// 将c数组, 转化为OC数组
//    
//    NSMutableArray *array = [NSMutableArray array];
//    for (int i = 0; i< numVertices; i++) {
//        float n = vVertices[i];
//        [array addObject:[NSNumber numberWithFloat:n]];
//    }
    
    
    /// 索引
    glGenBuffers(1, &_vertexIndicesBufferID);
    // GL_ELEMENT_ARRAY_BUFFER（表示索引数据）
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.vertexIndicesBufferID);
    
    /**
     *  self.numIndices*sizeof(GLushort) : 索引缓冲的长度,
        indices索引缓冲的数据, 参数“GL_STATIC_DRAW”，它表示此缓冲区内容只能被修改一次，但可以无限次读取。
     */
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, self.numIndices*sizeof(GLushort), indices, GL_STATIC_DRAW);

    /// 顶点数据
    glGenBuffers(1, &_vertexBufferID);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBufferID);
    glBufferData(GL_ARRAY_BUFFER, numVertices*3*sizeof(GLfloat), vVertices, GL_STATIC_DRAW);
    /// 激活顶点位置属性
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*3, NULL);
    
    /// 纹理数据
    glGenBuffers(1, &_vertexTexCoordID);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexTexCoordID);
    glBufferData(GL_ARRAY_BUFFER, numVertices*2*sizeof(GLfloat), vTextCoord, GL_DYNAMIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*2, NULL);

    /// 将图片转换成为纹理信息
    NSString *testPath = [[NSBundle mainBundle] pathForResource:@"test3" ofType:@"jpg"];
    
    /// 由于OpenGL的默认坐标系设置在左下角, 而GLKit在左上角, 因此需要转换
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], GLKTextureLoaderOriginBottomLeft, nil];
    
    self.textureInfo = [GLKTextureLoader textureWithContentsOfFile:testPath options:options error:nil];
    
    /// 设置着色器的纹理
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect. texture2d0.enabled = GL_TRUE;
    self.effect.texture2d0.name = self.textureInfo.name;
//
    
 
}

#pragma mark --- 生成球的几何结构----
#pragma mark - Generate Sphere
//https://github.com/danginsburg/opengles-book-samples/blob/604a02cc84f9cc4369f7efe93d2a1d7f2cab2ba7/iPhone/Common/esUtil.h#L110
int esGenSphere(int numSlices, float radius, float **vertices,
                float **texCoords, uint16_t **indices, int *numVertices_out) {
    int numParallels = numSlices / 2;
    int numVertices = (numParallels + 1) * (numSlices + 1);
    int numIndices = numParallels * numSlices * 6;
    float angleStep = (2.0f * 3.14159265f) / ((float) numSlices);
    
    if (vertices != NULL) {
        *vertices = malloc(sizeof(float) * 3 * numVertices);
    }
    
    if (texCoords != NULL) {
        *texCoords = malloc(sizeof(float) * 2 * numVertices);
    }
    
    if (indices != NULL) {
        *indices = malloc(sizeof(uint16_t) * numIndices);
    }
    
    for (int i = 0; i < numParallels + 1; i++) {
        for (int j = 0; j < numSlices + 1; j++) {
            int vertex = (i * (numSlices + 1) + j) * 3;
            
            if (vertices) {
                (*vertices)[vertex + 0] = radius * sinf(angleStep * (float)i) * sinf(angleStep * (float)j);
                (*vertices)[vertex + 1] = radius * cosf(angleStep * (float)i);
                (*vertices)[vertex + 2] = radius * sinf(angleStep * (float)i) * cosf(angleStep * (float)j);
            }
            
            if (texCoords) {
                int texIndex = (i * (numSlices + 1) + j) * 2;
                (*texCoords)[texIndex + 0] = (float)j / (float)numSlices;
                (*texCoords)[texIndex + 1] = 1.0f - ((float)i / (float)numParallels);
            }
        }
    }
    
    // Generate the indices
    if (indices != NULL) {
        uint16_t *indexBuf = (*indices);
        for (int i = 0; i < numParallels ; i++) {
            for (int j = 0; j < numSlices; j++) {
                *indexBuf++ = i * (numSlices + 1) + j;
                *indexBuf++ = (i + 1) * (numSlices + 1) + j;
                *indexBuf++ = (i + 1) * (numSlices + 1) + (j + 1);
                
                *indexBuf++ = i * (numSlices + 1) + j;
                *indexBuf++ = (i + 1) * (numSlices + 1) + (j + 1);
                *indexBuf++ = i * (numSlices + 1) + (j + 1);
            }
        }
    }
    
    if (numVertices_out) {
        *numVertices_out = numVertices;
    }
    
    return numIndices;
}

#pragma mark ---开始驱动位置检测(加速区与陀螺仪)---

- (CMMotionManager *)motionManager{
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
        
        /**设置运动更新间隔*/
        _motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
        
        /**是否展示运动?*/
        _motionManager.showsDeviceMovementDisplay = YES;
        
    }
    return _motionManager;
}

- (void)startDeviceMotion{
    
    /**设置初始坐标系, 并开始监控
     CMAttitudeReferenceFrameXArbitraryCorrectedZVertical: 描述的参考系默认设备平放(垂直于Z轴)，在X轴上取任意值。实际上当你开始刚开始对设备进行motion更新的时候X轴就被固定了。不过这里还使用了罗盘来对陀螺仪的测量数据做了误差修正
     使用pull形式获取数据
     */
    
    [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical];
    
    
    self.modelViewMatrix = GLKMatrix4Identity;

    
}


#pragma mark -----添加手势-----

- (void)addGestureRecognizer{
    
    /// 平移手势
    self.pan =[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    [self.view addGestureRecognizer:self.pan];

    /// 捏合手势
    self.pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchAction:)];
    [self.view addGestureRecognizer:self.pinch];
    self.scale = 1.0;
}

- (void)panAction:(UIPanGestureRecognizer *)pan{
    
    // 获取位置
    CGPoint point = [pan translationInView:self.view];
    self.panX += point.x;
    self.panY += point.y;
    
    //每次变换之后, 把改变值归零
    [pan setTranslation:CGPointZero inView:self.view];
    
}

- (void)pinchAction:(UIPinchGestureRecognizer *)pinch{
    self.scale *= pinch.scale;
    pinch.scale = 1.0;
}

#pragma mark ---GLKViewDelegate, 绘制----

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    
    /**清除颜色缓冲区内容时候: 使用蓝色填充*/
    glClearColor(0.3f, 0.6f, 1.0f, 1.0f);
    /**清除颜色缓冲区与深度缓冲区内容*/
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    [self.effect prepareToDraw];
    glDrawElements(GL_TRIANGLES, self.numIndices, GL_UNSIGNED_SHORT, 0);
}

#pragma mark ---变换坐标系投影-------

- (void)update{
    
    CGSize size = self.view.bounds.size;
    float aspect = fabs(size.width / size.height);
    
    /**
     *  根据缩放比例, 设置焦距
     */
    CGFloat ovyRadians = 100 / self.scale;
    
    // ovyRadians不小于50, 不大于110;
    if (ovyRadians < 50) {
        ovyRadians = 50;
        self.scale = 1 / (50.0/100);
    }
    if (ovyRadians>110) {
        ovyRadians = 110;
        self.scale = 1 / (110.0/100);
    }
    
  
    /**GLKMatrix4MakePerspective 配置透视图
     第一个参数, 类似于相机的焦距, 比如10表示窄角度, 100表示广角 一般65-75;
     第二个参数: 表示时屏幕的纵横比
     第三个, 第四参数: 是为了实现透视效果, 近大远处小, 要确保模型位于远近平面之间
     */
    
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(ovyRadians), aspect, 0.1f, 400.0f);
    projectionMatrix = GLKMatrix4Scale(projectionMatrix, -1.0f, 1.0f, 1.0f);
    
    CMDeviceMotion *deviceMotion = self.motionManager.deviceMotion;
    
    double w = deviceMotion.attitude.quaternion.w;
    double wx = deviceMotion.attitude.quaternion.x;
    double wy = deviceMotion.attitude.quaternion.y;
    double wz = deviceMotion.attitude.quaternion.z;
    
    NSLog(@"w = %f, wx = %f, wy = %f wz = %f", w, wx, wy,wz);
 
    projectionMatrix = GLKMatrix4RotateX(projectionMatrix, -0.005*self.panY);
    
    GLKQuaternion quaternion = GLKQuaternionMake(-wx, wy, wz, w);
    GLKMatrix4 rotation = GLKMatrix4MakeWithQuaternion(quaternion);
    
    projectionMatrix = GLKMatrix4Multiply(projectionMatrix, rotation);
    
    /// 为了保证在水平放置手机的时候, 是从下往上看, 因此首先坐标系沿着x轴旋转90度
    projectionMatrix = GLKMatrix4RotateX(projectionMatrix, M_PI_2);
    self.effect.transform.projectionMatrix = projectionMatrix;
    
  
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, 0.005*self.panX);
//    self.panX = 0;
//    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, 0.01*self.panY);
//    self.panY = 0;
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
