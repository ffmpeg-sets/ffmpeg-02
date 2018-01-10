//
//  VideoDecodeViewController.m
//  ffmpeg-02
//
//  Created by suntongmian on 2018/1/10.
//  Copyright © 2018年 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import "VideoDecodeViewController.h"
#include "libavformat/avformat.h"
#include "libavcodec/avcodec.h"
#include "libavutil/avutil.h"
#include "libavutil/imgutils.h"
#import "STMOpenGLView.h"

@interface VideoDecodeViewController ()
{
    AVFormatContext *_pFormatContext;
    AVCodecParameters *_pVideoCodecParameters, *_pAudioCodecParameters;
    AVCodec *_pVideoCodec, *_pAudioCodec;
    AVStream *_pVideoStream, *_pAudioStream;
    AVCodecContext *_pVideoCodecContext, *_pAudioCodecContext;
    int _videoCodecOpenResult, _audioCodecOpenResult;
    
    STMVideoFrameYUV *_videoFrameYUV;
    STMOpenGLView *_openGLView;
}

@end

@implementation VideoDecodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _videoFrameYUV= [[STMVideoFrameYUV alloc] init];
   
    _openGLView = [[STMOpenGLView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width * 288 / 480) videoFrameSize:CGSizeMake(480, 288) videoFrameFormat:STMVideoFrameFormatYUV];
    _openGLView.center = self.view.center;
    [self.view addSubview:_openGLView];
    
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(10, 32, 100, 40);
    backButton.backgroundColor = [UIColor blueColor];
    [backButton setTitle:@"返回" forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    startButton.frame = CGRectMake(260, 32, 100, 40);
    startButton.backgroundColor = [UIColor blueColor];
    [startButton setTitle:@"start" forState:UIControlStateNormal];
    [startButton addTarget:self action:@selector(startButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startButton];
}

- (void)startButtonEvent:(id)sender {
    [self displayImage];
}

- (void)displayImage {
    NSString *liveStreamingString = @"rtmp://live.hkstv.hk.lxdns.com/live/hks";
    const char *liveStreamingURL = [liveStreamingString UTF8String];
    
    av_register_all();
    
    avformat_network_init();
    
    _pFormatContext = avformat_alloc_context();
    
    if(avformat_open_input(&_pFormatContext, liveStreamingURL, NULL, NULL) != 0) {
        NSLog(@"Couldn't open input stream");
        return;
    }
    
    if(avformat_find_stream_info(_pFormatContext, NULL) < 0) {
        NSLog(@"Couldn't find stream information");
        return;
    }
    
    av_dump_format(_pFormatContext, 0, liveStreamingURL, 0);
    
    int videoIndex = -1;
    for(int i = 0; i < _pFormatContext->nb_streams; i++) {
        if(_pFormatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoIndex = i;
            break;
        }
    }
    
    if(videoIndex == -1) {
        NSLog(@"Didn't find a video stream");
    } else {
        _pVideoStream = _pFormatContext->streams[videoIndex];
    }
    
    int audioIndex = -1;
    for(int i = 0; i < _pFormatContext->nb_streams; i++) {
        if(_pFormatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            audioIndex = i;
            break;
        }
    }
    
    if(audioIndex == -1) {
        NSLog(@"Didn't find a audio stream");
    } else {
        _pAudioStream = _pFormatContext->streams[audioIndex];
    }
    
    if (_pVideoStream) {
        _pVideoCodecParameters = _pVideoStream->codecpar;
        _pVideoCodec = avcodec_find_decoder(_pVideoCodecParameters->codec_id);
        if(_pVideoCodec == NULL) {
            NSLog(@"Video codec not found");
        }
    }
    
    if (_pAudioStream) {
        _pAudioCodecParameters = _pAudioStream->codecpar;
        _pAudioCodec = avcodec_find_decoder(_pAudioCodecParameters->codec_id);
        if(_pAudioCodec == NULL) {
            NSLog(@"Audio codec not found");
        }
    }
    
    
    if (_pVideoCodec) {
        _pVideoCodecContext = avcodec_alloc_context3(_pVideoCodec);
        avcodec_parameters_to_context(_pVideoCodecContext, _pVideoCodecParameters);
        av_codec_set_pkt_timebase(_pVideoCodecContext, _pVideoStream->time_base);

        _videoCodecOpenResult = avcodec_open2(_pVideoCodecContext, _pVideoCodec, NULL);
        if(_videoCodecOpenResult != 0) {
            NSLog(@"Could not open video codec");
        }
    }
    
    if (_videoCodecOpenResult == 0) {
        AVFrame *pFrame = av_frame_alloc();
        AVPacket *packet=(AVPacket *)malloc(sizeof(AVPacket));
        int y_size = _pVideoCodecParameters->width * _pVideoCodecParameters->height;
        av_new_packet(packet, y_size);
        
        while(av_read_frame(_pFormatContext, packet) >= 0) {
            if(packet->stream_index == videoIndex) {
                avcodec_send_packet(_pVideoCodecContext, packet);
                int ret = avcodec_receive_frame(_pVideoCodecContext, pFrame);
                if (ret != 0) {
                    continue;
                }
                
                if (_pVideoCodecContext->pix_fmt == AV_PIX_FMT_YUV420P) {
                    NSLog(@"Video pix fmt is: AV_PIX_FMT_YUV420P");

                    uint8_t *buf = (uint8_t *)malloc(pFrame->width * pFrame->height * 3/2);
                    
                    AVFrame *pict = pFrame;
                    int w, h;
                    uint8_t *y, *u, *v;
                    w = pFrame->width;
                    h = pFrame->height;
                    y = buf;
                    u = y + w * h;
                    v = u + w * h/4;
                    
                    for (int i = 0; i < h; i++)
                        memcpy(y + w * i, pict->data[0] + pict->linesize[0] * i, w);
                    for (int i = 0; i < h/2; i++)
                        memcpy(u + w/2 * i, pict->data[1] + pict->linesize[1] * i, w / 2);
                    for (int i = 0; i < h/2; i++)
                        memcpy(v + w/2 * i, pict->data[2] + pict->linesize[2] * i, w / 2);
                    
                    int yuvWidth, yuvHeight;
                    void *planY, *planU, *planV;
                    
                    yuvWidth = pFrame->width;
                    yuvHeight = pFrame->height;
                    
                    planY = buf;
                    planU = buf + pFrame->width * pFrame->height;
                    planV = buf + pFrame->width * pFrame->height * 5/4;
                    
                    _videoFrameYUV.format = STMVideoFrameFormatYUV;
                    _videoFrameYUV.width = yuvWidth;
                    _videoFrameYUV.height = yuvHeight;
                    _videoFrameYUV.luma = planY;
                    _videoFrameYUV.chromaB = planU;
                    _videoFrameYUV.chromaR = planV;
                    
                    [_openGLView render:_videoFrameYUV];
                    
                    free(buf);
                }
            }
        }
        av_packet_unref(packet);
        av_frame_free(&pFrame);
    }
}

- (void)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    avformat_close_input(&_pFormatContext);
    _pFormatContext = NULL;
    
    avcodec_free_context(&_pVideoCodecContext);
    _pVideoCodecContext = NULL;
}

@end
