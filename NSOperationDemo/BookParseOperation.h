//
//  BookParseOperation.h
//  NSOperationDemo
//
//  Created by 刘 大兵 on 12-6-4.
//  Copyright (c) 2012年 中华中等专业学校. All rights reserved.
//

#import <Foundation/Foundation.h>

//自定义block
//预览书的前五页
typedef void (^BookPreviewBlock)(NSArray *tempArray);
typedef void (^BookProgressBlock)(NSInteger current,NSInteger total);
typedef void (^BasicBlock)(void);

@interface BookParseOperation : NSOperation{
    BOOL executing;
    BOOL finished;
    CGRect textFrame;
    //block不能加星号，但是是对象
    BookPreviewBlock previewBlock;
    BookProgressBlock progressBlock;
}
//书名，用于获取书的路径
@property(nonatomic,retain) NSString *bookName;
//书的完整内容，从路径加载，需要几秒
@property(nonatomic,retain) NSString *bookContent;
@property(nonatomic,retain) NSArray *rangeArray;
-(id)initWithName:(NSString*)theName frame:(CGRect)frame;
-(void)setPreviewBlock:(BookPreviewBlock)block;
-(void)setProgressBlock:(BookProgressBlock)block;
@end
