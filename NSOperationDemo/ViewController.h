//
//  ViewController.h
//  NSOperationDemo
//
//  Created by 刘 大兵 on 12-6-4.
//  Copyright (c) 2012年 中华中等专业学校. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController{
    IBOutlet UIProgressView *progressView;
    IBOutlet UILabel *bookLabel;
    IBOutlet UIBarButtonItem *pageButton;
    NSInteger currentPage;
    NSInteger totalPage;
    NSArray *rangeArray;
    NSString *bookContent;
}
-(IBAction)prePageClick:(id)sender;
-(IBAction)nextPageClick:(id)sender;
-(IBAction)parseClick:(id)sender;
@end
