//
//  FKRealGroup.m
//  FKRealGroup
//
//  Created by Fujun on 16/1/26.
//  Copyright © 2016年 Fujun. All rights reserved.
//

#import "FKRealGroup.h"
#import "DVTPlugInLocalizedString.h"
#import "JRSwizzle.h"
#import <objc/runtime.h>
#import "IDEStructureNavigator.h"
#import "IDEContainerItemStructureEditingTarget.h"
#import "PBXGroup.h"
#import "PBXGroup-PBXDropReceiverAdditions.h"
#import "PBXGroupTreeModule.h"
#import "Xcode3GroupWrapper.h"

static NSString * const kFKRealGroupKey = @"FKRealGroup";

static NSString * const kFKRealGroupCreateNotificationKey = @"FKRealGroupCreateNotification";

static NSString * const kFKRealGroupRealCreateNotificationKey = @"FKRealGroupRealCreateNotification";

@interface FKRealGroup()
<NSMenuDelegate, NSControlTextEditingDelegate, NSTextFieldDelegate>

@property (nonatomic, assign) NSCellStateValue menuState;

@property (nonatomic, strong, readwrite) NSBundle *bundle;

@property (nonatomic, copy) NSString *pathString;
@property (nonatomic, copy) NSString *dictName;

@property (nonatomic, assign) BOOL isRealCreate;
@end

@implementation FKRealGroup

#pragma mark - life circle
+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init])
    {
        self.bundle = plugin;
        [self addMethod];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didApplicationFinishLaunchingNotification:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(fkRealGroupCreateNotification:)
                                                     name:kFKRealGroupCreateNotificationKey
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(fkRealGroupRealCreateNotification:)
                                                     name:kFKRealGroupRealCreateNotificationKey
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(menuDidAddItemNotification:)
                                                     name:NSMenuDidAddItemNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(menuDidChangeItemNotification:)
                                                     name:NSMenuDidChangeItemNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(controlTextDidEndEditingNotification:)
                                                     name:NSControlTextDidEndEditingNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(controlTextDidBeginEditingNotification:)
                                                     name:NSControlTextDidBeginEditingNotification
                                                   object:nil];
    }
    return self;
}

- (void)addMethod
{
    [self addMethodWithClass:NSClassFromString(@"IDEStructureNavigator")
                   newMethod:@selector(fk_contextMenu_newGroupFolderOrPage:)
                originMethod:@selector(contextMenu_newGroupFolderOrPage:)];
    
    [self addMethodWithClass:NSClassFromString(@"IDEStructureNavigator")
                   newMethod:@selector(fk_contextMenu_newRealGroupFolderOrPage:)
                originMethod:nil];
    
    [self addMethodWithClass:NSClassFromString(@"IDEContainerItemStructureEditingTarget")
                   newMethod:@selector(fk_addNewSubgroupAtIndex:newGroupBlock:)
                originMethod:@selector(_addNewSubgroupAtIndex:newGroupBlock:)];
}

- (void)addMethodWithClass:(Class)className newMethod:(SEL)newMethod originMethod:(SEL)originMethod
{
    Method targetMethod = class_getInstanceMethod(className, newMethod);
    
    Method consoleMethod = class_getInstanceMethod(self.class, newMethod);
    IMP consoleIMP = method_getImplementation(consoleMethod);
    
    if (!targetMethod)
    {
        class_addMethod(className, newMethod, consoleIMP, method_getTypeEncoding(consoleMethod));
        
        if (originMethod)
        {
            NSError *error;
            [className
             jr_swizzleMethod:newMethod
             withMethod:originMethod
             error:&error];
            NSLog(@"error = %@", error);
        }
    }
}

- (void)addClassMethodWithClass:(Class)className newMethod:(SEL)newMethod originMethod:(SEL)originMethod
{
    Method targetMethod = class_getClassMethod(className, newMethod);
    
    Method consoleMethod = class_getClassMethod(self.class, newMethod);
    IMP consoleIMP = method_getImplementation(consoleMethod);
    
    if (!targetMethod)
    {
        class_addMethod(className, newMethod, consoleIMP, method_getTypeEncoding(consoleMethod));
        
        if (originMethod)
        {
            NSError *error;
            [className jr_swizzleClassMethod:newMethod
                             withClassMethod:originMethod
                                       error:&error];
            NSLog(@"error = %@", error);
        }
    }
}

#pragma mark -- notification
- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSApplicationDidFinishLaunchingNotification
                                                  object:nil];
    
    [self addMenu];
}

- (void)menuDidChangeItemNotification:(NSNotification *)noti
{
    NSMenu *menu = noti.object;
    if ([menu.title isKindOfClass:NSClassFromString(@"DVTPlugInLocalizedString")] &&
        [[menu.title valueForKeyPath:@"_key"] isEqualToString:@"Xcode.IDEStructureNavigator.MenuDefinition.ContextualMenu"])
    {
        NSInteger index = [noti.userInfo[@"NSMenuItemIndex"] integerValue];
        NSMenuItem *item = menu.itemArray[index];
        if (![item.title isKindOfClass:NSClassFromString(@"DVTPlugInLocalizedString")] &&
            [item.title isEqualToString:@"New Real Group"])
        {
            //与New Group保持一致
            NSMenuItem *newGroupItem = menu.itemArray[index-1];
            item.enabled = newGroupItem.enabled;
        }
    }
}

- (void)menuDidAddItemNotification:(NSNotification *)noti
{
    NSMenu *menu = noti.object;
    if ([menu.title isKindOfClass:NSClassFromString(@"DVTPlugInLocalizedString")] &&
        [[menu.title valueForKeyPath:@"_key"] isEqualToString:@"Xcode.IDEStructureNavigator.MenuDefinition.ContextualMenu"] &&
        menu.delegate != self)
    {
        menu.delegate = self;
    }
}

- (void)controlTextDidEndEditingNotification:(NSNotification *)noti
{
    if (self.menuState == NSOffState ||
        !self.isRealCreate)
    {
        return;
    }
    
    //真实修改文件名称
    self.pathString = nil;
    self.dictName   = nil;
    self.isRealCreate = NO;
    
    NSTextField *textField = noti.object;
    if (textField.delegate == self)
    {
        textField.delegate = nil;
    }
}
- (void)controlTextDidBeginEditingNotification:(NSNotification *)noti
{
    if (self.menuState == NSOffState ||
        !self.isRealCreate)
    {
        return;
    }
    
    NSTextField *textField = noti.object;
    textField.delegate = self;
}

- (void)fkRealGroupRealCreateNotification:(NSNotification *)noti
{
    self.isRealCreate = YES;
}

- (void)fkRealGroupCreateNotification:(NSNotification *)noti
{
    if (self.menuState == NSOffState ||
        !self.isRealCreate)
    {
        return;
    }
    
    NSDictionary *userInfo = noti.userInfo;
    
    self.pathString = userInfo[@"pathString"];
    
    if (self.pathString &&
        ![self.pathString isEqualToString:@""])
    {
        self.dictName = [NSDate date].description;
        
        NSString *dictPath = [NSString stringWithFormat:@"%@/%@", self.pathString, self.dictName];
        
        NSError *error;
        BOOL isSuccess = [[NSFileManager defaultManager] createDirectoryAtPath:dictPath
                                                   withIntermediateDirectories:YES
                                                                    attributes:nil
                                                                         error:&error];
        
        NSLog(@"%@%@",dictPath, isSuccess?@"创建成功":@"创建失败");
    }
    else
    {
        self.dictName = nil;
    }
}
#pragma mark -- delegate
- (void)menuWillOpen:(NSMenu *)menu
{
    NSMenuItem *newGroupItem;
    NSMenuItem *newRealGroupItem;
    NSInteger   newGroupItemIndex = 0;
    
    for (int i = 0; i < menu.itemArray.count; i++)
    {
        NSMenuItem *item = menu.itemArray[i];
        if ([item.title isKindOfClass:NSClassFromString(@"DVTPlugInLocalizedString")] &&
            [[item.title valueForKeyPath:@"_key"] isEqualToString:@"Xcode.IDEKit.CmdDefinition.NewGroupContextual"])
        {
            newGroupItem = item;
            newGroupItemIndex = i;
            continue;
        }
        
        if (![item.title isKindOfClass:NSClassFromString(@"DVTPlugInLocalizedString")] &&
            [item.title isEqualToString:@"New Real Group"])
        {
            newRealGroupItem = item;
            continue;
        }
    }
    
    if (self.menuState == NSOnState)
    {
        if (!newRealGroupItem)
        {
            //添加一个New Real Group
            newRealGroupItem =
            [[NSMenuItem alloc] initWithTitle:@"New Real Group"
                                       action:@selector(fk_contextMenu_newRealGroupFolderOrPage:)
                                keyEquivalent:@""];
            newRealGroupItem.enabled = YES;
            [menu insertItem:newRealGroupItem atIndex:newGroupItemIndex+1];
        }
        newRealGroupItem.hidden = NO;
    }
    else
    {
        if (newRealGroupItem)
        {
            newRealGroupItem.hidden = YES;
        }
    }
}
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    //修改前的文件名称  control->_stringValueBeforeEditing
    //修改后的文件名称  ((NSTextField *)control).stringValue
    //是否为文件夹
    NSLog(@"修改前：%@\n修改后:%@",
          [((NSTextField *)control) valueForKeyPath:@"_stringValueBeforeEditing"],
          ((NSTextField *)control).stringValue);
    //修改文件夹名称
    NSString *dictPath = [NSString stringWithFormat:@"%@/%@", self.pathString, self.dictName];
    NSString *newDictPath = [NSString stringWithFormat:@"%@/%@", self.pathString, ((NSTextField *)control).stringValue];
    
    BOOL isDict;
    BOOL isExistNewDict = [[NSFileManager defaultManager] fileExistsAtPath:newDictPath
                                                               isDirectory:&isDict];
    if (!isExistNewDict)
    {
        BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:dictPath
                                                            isDirectory:&isDict];
        if (isExist && isDict)
        {
            //修改名称
            NSError *error;
            BOOL isSuccess = [[NSFileManager defaultManager] moveItemAtPath:dictPath
                                                                     toPath:newDictPath
                                                                      error:&error];
            NSLog(@"%@ %@", newDictPath, isSuccess?@"修改文件夹成功":@"修改文件夹失败");
            //修改失败的话 删除原文件夹
            if (!isSuccess)
            {
                BOOL isDelete = [[NSFileManager defaultManager] removeItemAtPath:dictPath error:&error];
                NSLog(@"%@", isDelete?@"删除成功":@"删除失败");
            }
        }
        else
        {
            //创建
            NSError *error;
            BOOL isSuccess = [[NSFileManager defaultManager] createDirectoryAtPath:newDictPath
                                                       withIntermediateDirectories:YES
                                                                        attributes:nil
                                                                             error:&error];
            
            NSLog(@"%@ %@",newDictPath, isSuccess?@"创建成功":@"创建失败");
        }
        
        return YES;
    }
    else
    {
        NSAlert *alert = [NSAlert alertWithError:[NSError errorWithDomain:@"已经存在同名文件夹" code:500 userInfo:nil]];
        [alert runModal];
        return NO;
    }
#warning TODO:修改文件夹的引用
#warning PBXVariantGroup Xcode3VariantGroup
}

#pragma mark -- hook method
- (void)fk_contextMenu_newGroupFolderOrPage:(id)arg1
{
    [self fk_contextMenu_newGroupFolderOrPage:arg1];
}

- (void)fk_contextMenu_newRealGroupFolderOrPage:(id)arg1
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kFKRealGroupRealCreateNotificationKey
                                                        object:self];
    
    [self fk_contextMenu_newGroupFolderOrPage:arg1];
}

- (BOOL)fk_addNewSubgroupAtIndex:(unsigned long long)arg1 newGroupBlock:(id)arg2
{
    NSLog(@"文件位置:%@", [((IDEContainerItemStructureEditingTarget *)self) valueForKeyPath:@"_targetGroup._resolvedFilePath._pathString"]);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kFKRealGroupCreateNotificationKey
                                                        object:self
                                                      userInfo:@{@"pathString":[((IDEContainerItemStructureEditingTarget *)self) valueForKeyPath:@"_targetGroup._resolvedFilePath._pathString"]?:@""}];
    
    //在设置完成之后，可能要先删除文件夹引用 之后alloc一个新的 再插入进去 或者replace掉
//    IDEContainerItemStructureEditingTarget->_targetGroup->_subitems->_backingArray
//    Xcode3VariantGroup->_defaultReference->_filReference
//    Xcode3VariantFileReference PBXFileReference
    return [self fk_addNewSubgroupAtIndex:arg1 newGroupBlock:arg2];
}

#pragma mark -- method
- (void)addMenu
{
    NSMenu *mainMenu = [NSApp mainMenu];
    if (!mainMenu)
    {
        return;
    }
    
    NSMenuItem *pluginsMenuItem = [mainMenu itemWithTitle:@"Plugins"];
    if (!pluginsMenuItem)
    {
        pluginsMenuItem = [[NSMenuItem alloc] init];
        pluginsMenuItem.title = @"Plugins";
        pluginsMenuItem.submenu = [[NSMenu alloc] initWithTitle:pluginsMenuItem.title];
        NSInteger windowIndex = [mainMenu indexOfItemWithTitle:@"Window"];
        [mainMenu insertItem:pluginsMenuItem atIndex:windowIndex];
    }
    
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:kFKRealGroupKey];
    if (!value)
    {
        value = @(1);
    }
    
    NSMenuItem *subMenuItem = [[NSMenuItem alloc] init];
    subMenuItem.title = @"FKRealGroup";
    subMenuItem.target = self;
    subMenuItem.action = @selector(toggleMenu:);
    subMenuItem.state = value.boolValue?NSOnState:NSOffState;
    [pluginsMenuItem.submenu addItem:subMenuItem];
    
    self.menuState = subMenuItem.state;
}

- (void)toggleMenu:(NSMenuItem *)menuItem
{
    menuItem.state = !menuItem.state;
    
    self.menuState = menuItem.state;
    
    [[NSUserDefaults standardUserDefaults] setValue:@(menuItem.state)
                                             forKey:kFKRealGroupKey];
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
