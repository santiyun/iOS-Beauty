### 三体云SDK和相芯科技结合使用

#### 1. 加入房间前调用

```
[rtcEngine setBeautyFaceStatus:NO beautyLevel:0 brightLevel:0];

[rtcEngine setLocalVideoFrameCaptureFormat:TTTRtc_VideoFrameFormat_Texture isVideoSizeSameWithProfile:NO];

```

#### 2. 不再使用原来预览显示视频

```
- (int)setupLocalVideo:(TTTRtcVideoCanvas*)local;
```

#### 3. 实现本地视频采集回调

```
- (void)rtcEngine:(TTTRtcEngineKit *)engine localVideoFrameCaptured:(TTTRtcVideoFrame *)videoFrame {
    //不要变更线程  美颜 videoFrame.textureBuffer
    
    //...美颜
    
    //美颜接口调用之后处理下面代码
    CVPixelBufferRef imageBuffer = videoFrame.textureBuffer;
    
    //下载文件TTTMetalPlayer.h TTTMetalPlayer.m使用TTTMetalPlayer做渲染
    //注意视频的显示模式，通过contentMode设置
    [_metalPlayer display:pixelBuffer];
    
}
```

