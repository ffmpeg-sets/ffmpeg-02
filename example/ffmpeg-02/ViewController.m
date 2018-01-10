//
//  ViewController.m
//  ffmpeg-02
//
//  Created by suntongmian on 2018/1/10.
//  Copyright © 2018年 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import "ViewController.h"
#import "VideoDecodeViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *videoDecodeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    videoDecodeButton.frame = CGRectMake(100, 100, 100, 50);
    videoDecodeButton.backgroundColor = [UIColor blueColor];
    [videoDecodeButton setTitle:@"视频解码" forState:UIControlStateNormal];
    [videoDecodeButton addTarget:self action:@selector(videoDecodeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:videoDecodeButton];
    
}

- (void)videoDecodeButtonClicked:(id)sender {
    VideoDecodeViewController *videoDecodeViewController = [[VideoDecodeViewController alloc] init];
    [self presentViewController:videoDecodeViewController animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
