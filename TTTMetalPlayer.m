//
//  TTTMetalPlayer.m
//  LinkPK
//
//  Created by Work on 2020/4/16.
//  Copyright © 2020 yanzhen. All rights reserved.
//

#import "TTTMetalPlayer.h"
#import <MetalKit/MetalKit.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

@interface TTTMetalPlayer ()<MTKViewDelegate>
@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;
@property (nonatomic) dispatch_queue_t renderQueue;

@property (nonatomic) CGFloat frameWidth;
@property (nonatomic) CGFloat frameHeight;
@end

@implementation TTTMetalPlayer {
    dispatch_semaphore_t _renderingSemaphore;
    CVPixelBufferRef _renderBuffer;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _renderQueue = dispatch_queue_create("com.ttt.renderQueue", DISPATCH_QUEUE_SERIAL);
        _renderingSemaphore = dispatch_semaphore_create(1);
        [self setupMetal];
    }
    return self;
}

- (void)setContentMode:(UIViewContentMode)contentMode  {
    [super setContentMode:contentMode];
    self.mtkView.contentMode = contentMode;
}

- (void)setupMetal {
    self.mtkView = [[MTKView alloc] initWithFrame:self.bounds];
    self.mtkView.device = MTLCreateSystemDefaultDevice();
    [self insertSubview:self.mtkView atIndex:0];
    self.mtkView.delegate = self;
    self.mtkView.framebufferOnly = NO;
    self.commandQueue = [self.mtkView.device newCommandQueue];
    CVMetalTextureCacheCreate(NULL, NULL, self.mtkView.device, NULL, &_textureCache);
}


- (void)display:(CVPixelBufferRef)pixelBuffer {
    if (!pixelBuffer) { return; }
    if (dispatch_semaphore_wait(_renderingSemaphore, DISPATCH_TIME_NOW) != 0) {
        return;
    }
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    if (self.frameWidth != width || self.frameHeight != height) {
        self.frameWidth = width;
        self.frameHeight = height;
        [self initResultTexture];
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    uint8_t *originBuffer = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    CVPixelBufferLockBaseAddress(_renderBuffer, 0);
    uint8_t *renderBuffer = CVPixelBufferGetBaseAddress(_renderBuffer);
    CVPixelBufferUnlockBaseAddress(_renderBuffer, 0);
    memcpy(renderBuffer, originBuffer, bytesPerRow * height);
    
    CVPixelBufferRetain(_renderBuffer);
    dispatch_async(_renderQueue, ^{
        CVMetalTextureRef tmpTexture = NULL;
        CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, self->_renderBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &tmpTexture);
        if(status == kCVReturnSuccess)
        {
            self.mtkView.drawableSize = CGSizeMake(width, height);
            self.texture = CVMetalTextureGetTexture(tmpTexture);
            CFRelease(tmpTexture);
        }
        CVPixelBufferRelease(self->_renderBuffer);
        dispatch_semaphore_signal(self->_renderingSemaphore);
    });
}

- (void)initResultTexture {
    if (_renderBuffer) {
        CFRelease(_renderBuffer);
    }
    CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault,
                                               NULL,
                                               NULL,
                                               0,
                                               &kCFTypeDictionaryKeyCallBacks,
                                               &kCFTypeDictionaryValueCallBacks);

    CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                             1,
                                                             &kCFTypeDictionaryKeyCallBacks,
                                                             &kCFTypeDictionaryValueCallBacks);

    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);

    CVReturn cvRet = CVPixelBufferCreate(kCFAllocatorDefault,
                                         self.frameWidth,
                                         self.frameHeight,
                                         kCVPixelFormatType_32BGRA,
                                         attrs,
                                         &_renderBuffer);
    CFRelease(attrs);
    CFRelease(empty);
    if (kCVReturnSuccess != cvRet) {
        NSLog(@"TTT OpenGL Error CVPixelBufferCreate %d" , cvRet);
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.mtkView.frame = self.bounds;
}

- (void)dealloc
{
    if (_renderBuffer) {
        CFRelease(_renderBuffer);
    }
}
#pragma mark - MTKViewDelegate
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

- (void)drawInMTKView:(MTKView *)view {
    if (self.texture) {
        id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
        id<MTLTexture> drawingTexture = view.currentDrawable.texture;
        
        MPSImageGaussianBlur *filter = [[MPSImageGaussianBlur alloc] initWithDevice:self.mtkView.device sigma:0];
        [filter encodeToCommandBuffer:commandBuffer sourceTexture:self.texture destinationTexture:drawingTexture];
        [commandBuffer presentDrawable:view.currentDrawable];
        [commandBuffer commit];
        self.texture = NULL;
    }
}

@end
