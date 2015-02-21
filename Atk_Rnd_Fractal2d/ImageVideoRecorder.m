//
//  ImageVideoRecorder.m
//  Atk_Rnd_Fractal2d
//
//  Created by Rick Boykin on 12/1/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "ImageVideoRecorder.h"

@interface ImageVideoRecorder()

@property (nonatomic) AVAssetWriter *videoWriter;
@property (nonatomic) NSURL *videoOutputPath;
@property (nonatomic) NSUInteger width;
@property (nonatomic) NSUInteger height;
@property (nonatomic) dispatch_queue_t processingQueue;

@end

@implementation ImageVideoRecorder

- (void)initializeVideoRecorder
{
    NSError *error = nil;
    
    _videoWriter = [[AVAssetWriter alloc] initWithURL:_videoOutputPath fileType:AVFileTypeMPEG4 error:&error];
    // Codec compression settings
    NSDictionary *videoSettings = @{
                                    AVVideoCodecKey : AVVideoCodecH264,
                                    AVVideoWidthKey : @(_width),
                                    AVVideoHeightKey : @(_height),
                                    AVVideoCompressionPropertiesKey : @{
                                            AVVideoAverageBitRateKey : @(20000*1000), // 20 000 kbits/s
                                            AVVideoProfileLevelKey : AVVideoProfileLevelH264High40,
                                            AVVideoMaxKeyFrameIntervalKey : @(1)
                                            }
                                    };
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                     sourcePixelBufferAttributes:nil];
    
    videoWriterInput.expectsMediaDataInRealTime = NO;
    [_videoWriter addInput:videoWriterInput];
    [_videoWriter startWriting];
    [_videoWriter startSessionAtSourceTime:kCMTimeZero];
    

    [adaptor.assetWriterInput requestMediaDataWhenReadyOnQueue:self.processingQueue usingBlock:^{
        CMTime time = CMTimeMakeWithSeconds(1, 30);
        
        // loop here to create the video images.
        NSImage* image = nil;
        CVPixelBufferRef buffer = [self pixelBufferFromImage:image withWidth:_width height:_height];
        [self appendToAdapter:adaptor pixelBuffer:buffer atTime:time];
        CVPixelBufferRelease(buffer);
        
        time = CMTimeAdd(time, CMTimeMake(1, 30));

        [videoWriterInput markAsFinished];
        [_videoWriter endSessionAtSourceTime:time];
        [_videoWriter finishWritingWithCompletionHandler:^{
            NSLog(@"Video writer has finished creating video");
        }];
    }];
}

- (CVPixelBufferRef)pixelBufferFromImage:(NSImage*)image withWidth:(NSUInteger)width height:(NSUInteger)height
{
    /*
    CGImageRef cgImage = image.;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          size.width,
                                          size.height,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    if (status != kCVReturnSuccess){
        NSLog(@"Failed to create pixel buffer");
    }
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, 4*size.width, rgbColorSpace, 2);
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage)), cgImage);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
     */
    return nil;
}

- (BOOL)appendToAdapter:(AVAssetWriterInputPixelBufferAdaptor*)adaptor
            pixelBuffer:(CVPixelBufferRef)buffer
                 atTime:(CMTime)time
{
    while (!adaptor.assetWriterInput.readyForMoreMediaData) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    return [adaptor appendPixelBuffer:buffer withPresentationTime:time];
}


@end
