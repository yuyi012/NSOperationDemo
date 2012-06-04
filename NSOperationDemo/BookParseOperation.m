//
//  BookParseOperation.m
//  NSOperationDemo
//
//  Created by 刘 大兵 on 12-6-4.
//  Copyright (c) 2012年 中华中等专业学校. All rights reserved.
//

#import "BookParseOperation.h"

@interface BookParseOperation()
-(NSArray*)getPagesOfString:(NSString*)cache withFont:(UIFont*)theFont inRect:(CGRect)r;
@end

@implementation BookParseOperation
@synthesize bookName;
@synthesize bookContent;
@synthesize rangeArray;
-(id)initWithName:(NSString*)theName frame:(CGRect)frame{
    self = [super init];
    if (self) {
        //初始化中指定完成状态
        finished = NO;
        executing = NO;
        self.bookName = theName;
        textFrame = frame;
    }
    return self;
}

- (void)dealloc {
    [previewBlock release];
    [progressBlock release];
    [bookName release];
    [bookContent release];
    [rangeArray release];
    [super dealloc];
}

-(void)setPreviewBlock:(BookPreviewBlock)block{
    [previewBlock release];
    previewBlock = [block copy];
}

-(void)setProgressBlock:(BookProgressBlock)block{
    [progressBlock release];
    progressBlock = [block copy];
}

- (void)start{
    //key-value-observer,就是监测某些属性的变化
    if ([self isCancelled])
    {
        // Must move the operation to the finished state if it is canceled.
        [self willChangeValueForKey:@"isFinished"];
        //对属性进行更新提醒
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    // If the operation is not canceled, begin executing the task.
    [self willChangeValueForKey:@"isExecuting"];
    //解析的操作放在main方法里面
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)performBlockOnMainThread:(BasicBlock)block
{
    //在主线程中回调用block
	[self performSelectorOnMainThread:@selector(callBlock:) withObject:[[block copy] autorelease] waitUntilDone:[NSThread isMainThread]];
}

- (void)callBlock:(BasicBlock)block
{
	block();
}

- (void)main{
    //捕获异常
    @try {
        //在main方法中必须声明autorelease pool
        NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];        
        // Do the main work of the operation here.
        //获取书的路径
        NSString *bookPath = [[NSBundle mainBundle]pathForResource:self.bookName ofType:@"txt"];
        //获取书的内容
        self.bookContent = [[NSString alloc]initWithContentsOfFile:bookPath encoding:NSUTF8StringEncoding error:NULL];
        //解析
        self.rangeArray = [self getPagesOfString:self.bookContent withFont:[UIFont systemFontOfSize:14] inRect:textFrame];
        //解析完成
        [self willChangeValueForKey:@"isFinished"];
        [self willChangeValueForKey:@"isExecuting"];
        
        executing = NO;
        finished = YES;
        
        [self didChangeValueForKey:@"isExecuting"];
        [self didChangeValueForKey:@"isFinished"];
        [pool release];
    }
    @catch(...) {
        // Do not rethrow exceptions.
    }
}

-(NSArray*)getPagesOfString:(NSString*)cache withFont:(UIFont*)theFont inRect:(CGRect)r{
	//返回一个数组, 包含每一页的字符串开始点和长度(NSRange)
	NSMutableArray *ranges=[NSMutableArray array];
	//显示字体的行高
	CGFloat lineHeight=[@"Sample样本" sizeWithFont:theFont].height;
	NSInteger maxLine=floor(r.size.height/lineHeight);
	NSInteger totalLines=0;
	NSLog(@"Max Line Per Page: %d (%.2f/%.2f)",maxLine,r.size.height,lineHeight);
	NSString *lastParaLeft=nil;
	NSRange range=NSMakeRange(0, 0);
	//把字符串按段落分开, 提高解析效率
	NSArray *paragraphs=[cache componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    UILineBreakMode lineBreakMode = UILineBreakModeWordWrap;
	for (int p=0;p< [paragraphs count];p++) {
		NSString *para;
		if (lastParaLeft!=nil) {
			//上一页完成后剩下的内容继续计算
			para=lastParaLeft;
			lastParaLeft=nil;
		}else {
			para=[paragraphs objectAtIndex:p];
			if (p<[paragraphs count]-1)
				para=[para stringByAppendingString:@"/n"]; //刚才分段去掉了一个换行,现在还给它
		}
		CGSize paraSize=[para sizeWithFont:theFont
						 constrainedToSize:r.size
							 lineBreakMode:lineBreakMode];
		NSInteger paraLines=floor(paraSize.height/lineHeight);
		if (totalLines+paraLines<maxLine) {
			totalLines+=paraLines;
			range.length+=[para length];
			if (p==[paragraphs count]-1) {
				//到了文章的结尾 这一页也算
				[ranges addObject:[NSValue valueWithRange:range]];
				//IMILog(@”===========Page Over=============”);
			}
		}else if (totalLines+paraLines==maxLine) {
			//很幸运, 刚好一段结束,本页也结束, 有这个判断会提高一定的效率
			range.length+=[para length];
			[ranges addObject:[NSValue valueWithRange:range]];
			range.location+=range.length;
			range.length=0;
			totalLines=0;
			//IMILog(@”===========Page Over=============”);
		}else{
			//重头戏, 页结束时候本段文字还有剩余
			NSInteger lineLeft=maxLine-totalLines;
			CGSize tmpSize;
			NSInteger i;
			for (i=1; i<[para length]; i++) {
				//逐字判断是否达到了本页最大容量
				NSString *tmp=[para substringToIndex:i];
				tmpSize=[tmp sizeWithFont:theFont
						constrainedToSize:r.size
							lineBreakMode:lineBreakMode];
				int nowLine=floor(tmpSize.height/lineHeight);
				if (lineLeft<nowLine) {
					//超出容量,跳出, 字符要回退一个, 应为当前字符已经超出范围了
					lastParaLeft=[para substringFromIndex:i-1];
					break;
				}
			}
			range.length+=i-1;
			[ranges addObject:[NSValue valueWithRange:range]];
            
            
			range.location+=range.length;
			range.length=0;
			totalLines=0;
			p--;
			//IMILog(@”===========Page Over=============”);
		}
        //调用预览5页的block
        //当循环进行了5次，就可以调用预览block
        if (ranges.count==5) {
            [self performBlockOnMainThread:^{
                if (previewBlock) {
                    previewBlock(ranges);
                }
            }];
        }
        //调用progressBlock，提示加载进度
        [self performBlockOnMainThread:^{
            if (progressBlock) {
                //p当前解析完成的段落index，paragraphs是所有的段落
                progressBlock(p,[paragraphs count]);
            }
        }];
	}
	return [NSArray arrayWithArray:ranges];
}

- (BOOL)isExecuting{
    //进程是否在执行
    return executing;
}

- (BOOL)isFinished{
    //进程是否完成
    return finished;
}

- (BOOL)isConcurrent{
    return YES;
}
@end
