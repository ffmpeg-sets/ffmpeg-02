//
//  STMOpenGLView.h
//  ffmpeg-02
//
//  Created by suntongmian on 2018/1/11.
//  Copyright © 2018年 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef enum {
    STMVideoFrameFormatRGB,
    STMVideoFrameFormatYUV,
} STMVideoFrameFormat;

@interface STMVideoFrame : NSObject
@property (nonatomic) STMVideoFrameFormat format;
@property (nonatomic) NSUInteger width;
@property (nonatomic) NSUInteger height;
@end

@interface STMVideoFrameRGB : STMVideoFrame
@property (nonatomic) NSUInteger linesize;
@property (nonatomic) UInt8 *rgb;
@end

@interface STMVideoFrameYUV : STMVideoFrame
@property (nonatomic) UInt8 *luma;
@property (nonatomic) UInt8 *chromaB;
@property (nonatomic) UInt8 *chromaR;
@end


@interface STMOpenGLView : UIView

- (id)initWithFrame:(CGRect)frame videoFrameSize:(CGSize)videoFrameSize videoFrameFormat:(STMVideoFrameFormat)videoFrameFormat;

- (void)render:(STMVideoFrame *)frame;

@end
