###三体云SDK和相芯科技结合使用

#### 1. 加入房间前调用

```
[rtcEngine setBeautyFaceStatus:NO beautyLevel:0 brightLevel:0];

[rtcEngine setLocalVideoFrameCaptureFormat:TTTRtc_VideoFrameFormat_Texture isVideoSizeSameWithProfile:NO];

```

#### 2. 不再使用原来预览显示视频

```
- (int)setupLocalVideo:(TTTRtcVideoCanvas*)local;
```

#### 3. 声明CIContext

```
#import <CoreImage/CoreImage.h>

@property (nonatomic, strong) CIContext *temporaryContext;

_temporaryContext = [CIContext contextWithOptions:nil];

```

#### 4. 实现本地视频采集回调

```
- (void)rtcEngine:(TTTRtcEngineKit *)engine localVideoFrameCaptured:(TTTRtcVideoFrame *)videoFrame {
    //不要变更线程  美颜 videoFrame.textureBuffer
    CVPixelBufferRef imageBuffer = videoFrame.textureBuffer;
    CVPixelBufferRetain(imageBuffer);
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    if (ciImage == nil) {
        CVPixelBufferRelease(imageBuffer);
        return;
    }
    CGFloat imageWidth = CVPixelBufferGetWidth(imageBuffer);
    CGFloat imageHeight = CVPixelBufferGetHeight(imageBuffer);
    CGImageRef videoImage = [self.temporaryContext createCGImage:ciImage fromRect:CGRectMake(0, 0, imageWidth, imageHeight)];
    if (videoImage == nil) {
        CVPixelBufferRelease(imageBuffer);
        return;
    }
    UIImage *image = [[UIImage alloc] initWithCGImage:videoImage];
    CGImageRelease(videoImage);
    CVPixelBufferRelease(imageBuffer);
    dispatch_async(dispatch_get_main_queue(), ^{
        //显示视频 imageView.image = image;
    });
}
```

