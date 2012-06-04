//
//  ViewController.m
//  NSOperationDemo
//
//  Created by 刘 大兵 on 12-6-4.
//  Copyright (c) 2012年 中华中等专业学校. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "BookParseOperation.h"

@interface ViewController()
-(NSArray*)getPagesOfString:(NSString*)cache withFont:(UIFont*)theFont inRect:(CGRect)r;
-(void)showCurrentPage;
-(void)showCurrentPage:(BOOL)isNext;
@end

@implementation ViewController
#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
}

- (void)dealloc {
    [bookContent release];
    [rangeArray release];
    [super dealloc];
}

-(IBAction)prePageClick:(id)sender{
    if (currentPage>0) {
        currentPage--;
        [self showCurrentPage:NO];
    }
}

-(IBAction)nextPageClick:(id)sender{
    if (currentPage<totalPage) {
        //不是最后一页才能往下翻
        currentPage++;
        [self showCurrentPage:YES];
    }
}

-(IBAction)parseClick:(id)sender{
//    NSBlockOperation *parseOperation = [NSBlockOperation blockOperationWithBlock:^{
//        NSString *path = [[NSBundle mainBundle]pathForResource:@"无限恐怖-1" ofType:@"txt"];
//        [bookContent release];
//        bookContent = [[NSString alloc]initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
//        [rangeArray release];
//        rangeArray = [[self getPagesOfString:bookContent withFont:[UIFont systemFontOfSize:14] inRect:bookLabel.bounds]retain];
//        
//        currentPage = 0;
//        totalPage = rangeArray.count;
//        //获取第一页
//        [self showCurrentPage:YES];
//    }];
    BookParseOperation *parseOperation = [[BookParseOperation alloc]initWithName:@"无限恐怖-1" frame:bookLabel.frame];
    [parseOperation setPreviewBlock:^(NSArray *tempArray){
        [bookContent release];
        //解析完成以后，从operation中获取书的内容
        bookContent = [parseOperation.bookContent retain];
        currentPage = 0;
        [rangeArray release];
        rangeArray = [tempArray retain];
        totalPage = rangeArray.count;
        [self showCurrentPage:YES];
    }];
    //解析进度提示
    [parseOperation setProgressBlock:^(NSInteger current,NSInteger total){
        progressView.progress = (CGFloat)current/total; 
    }];
    [parseOperation setCompletionBlock:^{
        [rangeArray release];
        rangeArray = [parseOperation.rangeArray retain];
        totalPage = rangeArray.count;
        [self showCurrentPage:YES];
    }];
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc]init];
    //不用调研operation的start，也不用调用queue的start
    [operationQueue addOperation:parseOperation];
}

-(void)showCurrentPage:(BOOL)isNext{
    //显示页码
    NSString *pageStr = [NSString stringWithFormat:@"%d/%d",currentPage,totalPage];
    pageButton.title = pageStr;
    
    NSRange firstRange = [[rangeArray objectAtIndex:currentPage]rangeValue];
    //使用动画呈现出往上翻和往下翻的效果
    CATransition *transition = [CATransition animation];
    transition.type = @"push";
    if (isNext) {
        transition.subtype = @"fromRight";
    }else{
        transition.subtype = @"fromLeft";
    }
    bookLabel.text = [bookContent substringWithRange:firstRange];
    //在对label的text进行更改以后增加animation
    [bookLabel.layer addAnimation:transition forKey:@"animation"];
}

@end
