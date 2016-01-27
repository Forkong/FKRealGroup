//
//  FKRealGroup.h
//  FKRealGroup
//
//  Created by Fujun on 16/1/26.
//  Copyright © 2016年 Fujun. All rights reserved.
//

#import <AppKit/AppKit.h>

@class FKRealGroup;

static FKRealGroup *sharedPlugin;

@interface FKRealGroup : NSObject

+ (instancetype)sharedPlugin;
- (id)initWithBundle:(NSBundle *)plugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end