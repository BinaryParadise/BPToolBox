//
//  RYViewController.m
//  ToolboxExample
//
//  Created by rakeyang on 10/25/2019.
//  Copyright (c) 2019 rakeyang. All rights reserved.
//

#import "RYViewController.h"

@interface RYViewController ()

@end

@implementation RYViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    UIImageView *img = [[UIImageView alloc] initWithImage:[ UIImage imageNamed:@"wrapper"]];
    [self.view addSubview:img];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
