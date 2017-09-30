//
//  ViewController.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/6/26.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "ViewController.h"
#import "XXCameraHardEncodeDecodeViewController.h"
#import "XXH264FileDecodeViewController.h"
#import "XXH265CameraViewController.h"
#import "XXFFmpegRemuxerViewController.h"
#import "XXFFmpegDecoderViewController.h"
#import "XXH265FileDecodeViewController.h"
#import "XXH264RGBFileDecodeViewController.h"
#import "XXH265RGBFileDecodeViewController.h"
#import "XXFFmpegHwFileDcodeViewController.h"
#import "LAScreenEx.h"

#define BASECELLIDENDIFIFY @"BASE_CELL_IDENDIFIFY"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property(nonatomic,strong) NSArray *listArray;
@property(nonatomic,strong) UITableView *baseTableView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSMutableArray *array = [[NSMutableArray alloc] initWithObjects:
                             @"H264硬件-实时编解码",
                             @"H264硬件-文件解码显示",
                             @"H265硬件-编码写文件",
                             @"H264FFmpeg-纯净版格式转换保存本地",
                             @"H264FFmpeg-解码保存与显示",
                             @"H265硬件-解码文件显示",
                             @"H264硬解-RGB格式并上屏",
                             @"H265硬解-RGB格式并上屏",
                             @"H265硬解-FFmpeg读取上屏",nil];
    self.listArray = array;
    
}

-(void)loadView
{
    [super loadView];
    
    UITableView* tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    //    CZ_SetClearBackgroundColor(tableView);
    [tableView setBackgroundColor:[UIColor clearColor]];
    
    tableView.backgroundView = nil;
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    _baseTableView = tableView;
    
    [_baseTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:BASECELLIDENDIFIFY];
    [self.view addSubview:_baseTableView];
}

#pragma mark- Delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _adapt_H(44);
}


- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [UIView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return _adapt_H(20.f);;
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [UIView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == [tableView numberOfSections] - 1) {
        return _adapt_H(20);
    }  else {
        return _adapt_H(0.01);
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIViewController *viewController = nil;
    switch (indexPath.row) {
        case 0:{
                viewController = [[XXCameraHardEncodeDecodeViewController alloc] init];
            }
            break;
        case 1:{
            viewController = [[XXH264FileDecodeViewController alloc] init];
            }
            break;
        case 2:{
            viewController = [[XXH265CameraViewController alloc] init];
            }
            break;
        case 3:{
            viewController = [[XXFFmpegRemuxerViewController alloc] init];
            }
            break;
        case 4:{
            viewController = [[XXFFmpegDecoderViewController alloc] init];
            }
            break;
        case 5:{
            viewController = [[XXH265FileDecodeViewController alloc] init];
        }
            break;
        case 6:{
            viewController = [[XXH264RGBFileDecodeViewController alloc] init];
        }
            break;
        case 7:{
            viewController = [[XXH265RGBFileDecodeViewController alloc] init];
        }
            break;
        case 8:{
            viewController = [[XXFFmpegHwFileDcodeViewController alloc] init];
        }
            break;
        default:
            break;
    }
    [self presentViewController:viewController animated:YES completion:^{
    }];
    
}

#pragma mark- DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;              // Default is 1 if not implemented
{
    return 1.f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.listArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:BASECELLIDENDIFIFY forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:BASECELLIDENDIFIFY];
    }
    
    cell.textLabel.text = [self.listArray objectAtIndex:row];
    
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
