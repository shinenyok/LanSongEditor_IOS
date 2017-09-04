//
//  VideoPictureRealTimeVC.m
//  LanSongEditor_all
//
//  Created by sno on 16/12/29.
//  Copyright © 2016年 sno. All rights reserved.
//

#import "Demo1PenMothedVC.h"

#import "LanSongUtils.h"
#import "BlazeiceDooleView.h"

@interface Demo1PenMothedVC ()
{
    DrawPadPreview *drawpad;
    
    NSURL *sampleURL;
    NSString *dstPath;
    NSString *dstTmpPath;
    
    Pen *operationPen;  //当前操作的图层
}
@end

@implementation Demo1PenMothedVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor=[UIColor whiteColor];
    
    
    
    dstPath = [SDKFileUtil genFileNameWithSuffix:@"mp4"];
    dstTmpPath = [SDKFileUtil genFileNameWithSuffix:@"mp4"];
    
    //step1:第一步: 创建画板(尺寸,码率,编码后的目标文件路径,增加一个预览view)
    
    CGFloat     drawPadWidth=480;
    CGFloat     drawPadHeight=480;
    
//    CGFloat     drawPadWidth=1280;  //OK
//    CGFloat     drawPadHeight=720;

//    CGFloat     drawPadWidth=720;  //OK
//    CGFloat     drawPadHeight=1280;
    
//    CGFloat     drawPadWidth=560; //OK
//    CGFloat     drawPadHeight=992;
    
//    CGFloat     drawPadWidth=544;  //OK
//    CGFloat     drawPadHeight=960;
    
//    CGFloat     drawPadWidth=960;  //OK
//    CGFloat     drawPadHeight=544;
    
    
    
    int    drawPadBitRate=1000*1000;
    drawpad=[[DrawPadPreview alloc] initWithWidth:drawPadWidth height:drawPadHeight bitrate:drawPadBitRate dstPath:dstTmpPath];
    
    
    CGSize size=self.view.frame.size;
    CGFloat padding=size.height*0.01;
    
    DrawPadView *filterView;
    if (drawPadWidth>drawPadHeight) {
        filterView=[[DrawPadView alloc] initWithFrame:CGRectMake(0, 60, size.width,size.width*(drawPadHeight/drawPadWidth))];
        
    }else{
        //如果高度大于宽度,则使用屏幕的高度一半作为预览界面.同时为了保证预览的画面宽高比一致,等比例得到宽度的值.
        filterView=[[DrawPadView alloc] initWithFrame:CGRectMake(0, 60, size.height*(drawPadWidth/drawPadHeight)/2,size.height/2)];
        filterView.center=CGPointMake(size.width/2, filterView.center.y);
   }
    
    
    [self.view addSubview: filterView];
    [drawpad setDrawPadPreView:filterView];
    
    
   //第二步: 增加一些图层,当然您也可以在画板开始后增加
    UIImage *imag=[UIImage imageNamed:@"p640x1136"];
    [drawpad addBitmapPen:imag];  //增加一个图片图层,因为先增加的,放到最后,等于是背景.
    
    //增加一个视频图层.
    sampleURL = [[NSBundle mainBundle] URLForResource:@"ping20s" withExtension:@"mp4"];
    GPUImageSepiaFilter  *filter=[[GPUImageSepiaFilter alloc] init];
    operationPen=  [drawpad addMainVideoPen:[SDKFileUtil urlToFileString:sampleURL] filter:filter];
    
    
    //第三步, 设置 进度回调,完成回调, 开始执行.
    __weak typeof(self) weakSelf = self;
    [drawpad setOnProgressBlock:^(CGFloat currentPts) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.labProgress.text=[NSString stringWithFormat:@"当前进度 %f",currentPts];
            
        });
    }];
    
    //设置完成后的回调
    [drawpad setOnCompletionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf addAudio];
            [weakSelf showIsPlayDialog];
            
        });
    }];
    
    // 开始工作
    if([drawpad startDrawPad]==NO)
    {
        NSLog(@"DrawPad 容器线程执行失败, 请联系我们!");
    }
    
    
    //把视频缩小一半,放在背景图上.
    operationPen.scaleWidth=0.5f;
    operationPen.scaleHeight=0.5f;
    
    //-------------以下是ui操作-----------------------
    _labProgress=[[UILabel alloc] init];
    _labProgress.textColor=[UIColor redColor];
    
    [self.view addSubview:_labProgress];
    
    [_labProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(filterView.mas_bottom).offset(padding);
        make.centerX.mas_equalTo(filterView.mas_centerX);
        make.size.mas_equalTo(CGSizeMake(size.width, 40));
    }];
    
    UIView *currslide=  [self createSlide:_labProgress min:0.0f max:1.0f value:0.5f tag:101 labText:@"X坐标:"];
    currslide=  [self createSlide:currslide min:0.0f max:1.0f value:0.5f tag:102 labText:@"Y坐标:"];
    currslide=          [self createSlide:currslide min:0.0f max:3.0f value:1.0f tag:103 labText:@"缩放:"];
    [self createSlide:currslide min:0.0f max:360.0f value:0 tag:104 labText:@"旋转:"];
    
}

- (void)slideChanged:(UISlider*)sender
{
    CGFloat val=[(UISlider *)sender value];
    
    CGFloat posX=drawpad.drawpadSize.width*val;
    CGFloat posY=drawpad.drawpadSize.height*val;
    
    
    switch (sender.tag) {
        case 101:  //weizhi
            /*
             你可以通过
           
             */
            operationPen.positionX=posX;
            break;
        case 102:  //Y坐标
            operationPen.positionY=posY;
            break;
        case 103:  //scale
            if (operationPen!=nil) {
                operationPen.scaleHeight=val;
                operationPen.scaleWidth=val;
            }
            break;
        case 104:  //rotate;
            if (operationPen!=nil) {
                operationPen.rotateDegree=val;
            }
            break;
            
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 初始化一个slide
 */
-(UIView *)createSlide:(UIView *)parentView  min:(CGFloat)min max:(CGFloat)max  value:(CGFloat)value tag:(int)tag labText:(NSString *)text;

{
    UILabel *labPos=[[UILabel alloc] init];
    labPos.text=text;
    
    UISlider *slidePos=[[UISlider alloc] init];
    
    slidePos.maximumValue=max;
    slidePos.minimumValue=min;
    slidePos.value=value;
    slidePos.continuous = YES;
    slidePos.tag=tag;
    
    [slidePos addTarget:self action:@selector(slideChanged:) forControlEvents:UIControlEventValueChanged];
    
    
    CGSize size=self.view.frame.size;
    CGFloat padding=size.height*0.01;
    
    [self.view addSubview:labPos];
    [self.view addSubview:slidePos];
    
    
    [labPos mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(parentView.mas_bottom).offset(padding);
        make.left.mas_equalTo(self.view.mas_left);
        make.size.mas_equalTo(CGSizeMake(80, 40));
    }];
    
    [slidePos mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(labPos.mas_centerY);
        make.left.mas_equalTo(labPos.mas_right);
        make.size.mas_equalTo(CGSizeMake(size.width-80, 15));
    }];
    return labPos;
}
-(void)addAudio
{
    if ([SDKFileUtil fileExist:dstTmpPath]) {
        [VideoEditor drawPadAddAudio:[SDKFileUtil urlToFileString:sampleURL] newMp4:dstTmpPath dstFile:dstPath];
    }else{
        dstPath=dstTmpPath;
    }
}
-(void)showIsPlayDialog
{
    UIAlertView *alertView=[[UIAlertView alloc] initWithTitle:@"提示" message:@"视频已经处理完毕,是否需要预览" delegate:self cancelButtonTitle:@"预览" otherButtonTitles:@"返回", nil];
    [alertView show];
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex==0) {
        [LanSongUtils startVideoPlayerVC:self.navigationController dstPath:dstPath];
    }else {  //返回
        
    }
}
-(void)viewDidDisappear:(BOOL)animated
{
    if (drawpad!=nil) {
        [drawpad stopDrawPad];
    }
}

-(void)dealloc
{
    operationPen=nil;
    drawpad=nil;
    if([SDKFileUtil fileExist:dstPath]){
        [SDKFileUtil deleteFile:dstPath];
    }
    if([SDKFileUtil fileExist:dstTmpPath]){
        [SDKFileUtil deleteFile:dstTmpPath];
    }
    NSLog(@"VideoPictureRealTime VC  dealloc");
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end

