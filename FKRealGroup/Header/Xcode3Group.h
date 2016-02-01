//
//  Xcode3Group.h
//  FKRealGroup
//
//  Created by Fujun on 16/1/28.
//  Copyright © 2016年 Fujun. All rights reserved.
//

@interface DVTModelObject : NSObject
@end

@interface IDEContainerItem : DVTModelObject
@end

@interface IDEGroup : IDEContainerItem
- (NSArray *)subitems;
- (NSImage *)navigableItem_image;
@end

@interface Xcode3Group : IDEGroup

@end
