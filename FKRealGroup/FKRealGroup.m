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
#import "Xcode3Group.h"
#import "PBXGroup.h"
#import <Carbon/Carbon.h>

static NSString * const kFKRealGroupKey = @"FKRealGroup";
static NSString * const kPathStringKey = @"pathString";
static NSString * const kGroupNameBeforeEditingKey = @"groupNameBeforeEditing";
static NSString * const kNewSubgroupIndexStringKey = @"newSubgroupIndex";
static NSString * const kDVTPlugInLocalizedString = @"DVTPlugInLocalizedString";
static NSString * const kIsDeleteRealGroupKey = @"isDeleteRealGroup";
//------Key Path ---------
static NSString * const kPathStringKeyPath = @"_targetGroup._resolvedFilePath._pathString";
static NSString * const kStringValueBeforeEditingKeyPath = @"_stringValueBeforeEditing";
static NSString * const kNewGroupNameBeforeEditingKeyPath = @"";
//------Title ------------
static NSString * const kNewRealGroupItemTitle = @"New Real Group";
static NSString * const kDeleteRealGroupItemTitle = @"Delete Real Group";
static NSString * const kMoveToTrashButtonTitle = @"Move to Trash";
//------Context Key ------
static NSString * const kIDEStructureNavigatorKey = @"Xcode.IDEStructureNavigator.MenuDefinition.ContextualMenu";
static NSString * const kNewGroupContextKey = @"Xcode.IDEKit.CmdDefinition.NewGroupContextual";
static NSString * const kDeleteContextKey = @"Xcode.IDEKit.CmdDefinition.Delete";
static NSString * const kDeleteRealGroupContextKey = @"Xcode.IDEKit.CmdDefinition.DeleteRealGroup";
//------Notification------
static NSString * const kFKRealGroupCreateNotificationKey = @"FKRealGroupCreateNotification";
static NSString * const kFKRealGroupRealCreateNotificationKey = @"FKRealGroupRealCreateNotification";
static NSString * const kFKRealGroupDeleteRealGroupFlagNotificationKey = @"FKRealGroupDeleteRealGroupFlagNotification";
static NSString * const kFKRealGroupDeleteRealGroupNotificationKey = @"FKRealGroupDeleteRealGroupNotification";
static NSString * const kFKRealGroupMoveToTrashNotificationKey = @"FKRealGroupMoveToTrashNotification";

@interface FKRealGroup()
<NSMenuDelegate, NSControlTextEditingDelegate, NSTextFieldDelegate>
@property (nonatomic, strong, readwrite) NSBundle *bundle;

@property (nonatomic, assign) NSCellStateValue menuState;

@property (nonatomic, copy)   NSString *pathString;

@property (nonatomic, copy)   NSString *groupNameBeforeEditing;

@property (nonatomic, assign) BOOL isRealCreate;

@property (nonatomic, assign) BOOL isDeleteRealGroup;

@property (nonatomic, assign) BOOL isMoveToTrash;

@property (nonatomic, strong) IDEContainerItemStructureEditingTarget *ideTarget;

@property (nonatomic, assign) NSInteger newSubgroupIndex;

@property (nonatomic, strong) id eventMonitor;

@property (nonatomic, strong) NSTextField *textField;
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
        self.isMoveToTrash = YES;
        
        [self addMethod];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didApplicationFinishLaunchingNotification:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
    }
    return self;
}

- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fkRealGroupCreateNotification:)
                                                 name:kFKRealGroupCreateNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fkRealGroupRealCreateNotification:)
                                                 name:kFKRealGroupRealCreateNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fkRealGroupDeleteRealGroupNotification:)
                                                 name:kFKRealGroupDeleteRealGroupNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fkRealGroupDeleteRealGroupFlagNotification:)
                                                 name:kFKRealGroupDeleteRealGroupFlagNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fkRealGroupMoveToTrashNotification:)
                                                 name:kFKRealGroupMoveToTrashNotificationKey
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
                                             selector:@selector(controlTextDidBeginEditingNotification:)
                                                 name:NSControlTextDidBeginEditingNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(controlTextDidEndEditingNotification:)
                                                 name:NSControlTextDidEndEditingNotification
                                               object:nil];    
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kFKRealGroupCreateNotificationKey
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kFKRealGroupRealCreateNotificationKey
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kFKRealGroupDeleteRealGroupNotificationKey
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kFKRealGroupDeleteRealGroupFlagNotificationKey
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kFKRealGroupMoveToTrashNotificationKey
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSMenuDidAddItemNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSMenuDidChangeItemNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSControlTextDidEndEditingNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSControlTextDidBeginEditingNotification
                                                  object:nil];
}

- (void)addMethod
{
    [self addMethodWithClass:NSClassFromString(@"IDEStructureNavigator")
                   newMethod:@selector(fk_contextMenu_newGroupFolderOrPage:)
                originMethod:@selector(contextMenu_newGroupFolderOrPage:)];
    
    [self addMethodWithClass:NSClassFromString(@"IDEStructureNavigator")
                   newMethod:@selector(fk_contextMenu_delete:)
                originMethod:@selector(contextMenu_delete:)];
    
    [self addMethodWithClass:NSClassFromString(@"IDEStructureNavigator")
                   newMethod:@selector(fk_contextMenu_deleteRealGroup:)
                originMethod:nil];

    [self addMethodWithClass:NSClassFromString(@"IDEStructureNavigator")
                   newMethod:@selector(fk_contextMenu_newRealGroupFolderOrPage:)
                originMethod:nil];
    
    [self addMethodWithClass:NSClassFromString(@"IDEContainerItemStructureEditingTarget")
                   newMethod:@selector(fk_addNewSubgroupAtIndex:newGroupBlock:)
                originMethod:@selector(_addNewSubgroupAtIndex:newGroupBlock:)];
    
    [self addMethodWithClass:NSClassFromString(@"IDEContainerItemStructureEditingTarget")
                   newMethod:@selector(fk_structureEditingRemoveSubitemsAtIndexes:error:)
                originMethod:@selector(structureEditingRemoveSubitemsAtIndexes:error:)];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [self addMethodWithClass:[NSAlert class]
                   newMethod:@selector(fk_buttonPressed:)
                originMethod:@selector(buttonPressed:)];
#pragma clang diagnostic pop
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
            BOOL isSuccess = [className jr_swizzleMethod:newMethod withMethod:originMethod error:&error];
#ifdef DEBUG
            if (!isSuccess)
            {
                NSLog(@"error = %@", error);
            }
#endif
        }
    }
}

/**
 *  键盘监控 检测ESC按键
 */
- (void)addKeyboardEventMonitor
{
    self.eventMonitor =
    [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:^NSEvent *(NSEvent *incomingEvent) {
        if (self.isRealCreate &&
            [incomingEvent keyCode] == kVK_Escape)
        {
            //在编辑状态下 创建此文件夹 此文件夹名称为原始名称
            if (self.pathString &&
                self.groupNameBeforeEditing)
            {
                [self control:self.textField groupName:self.groupNameBeforeEditing];
            }
            
            [self controlTextDidEndEditingNotification:nil];
        }
        return incomingEvent;
    }];
}

- (void)removeKeyboardEventMonitor
{
    [NSEvent removeMonitor:self.eventMonitor];
    self.eventMonitor = nil;
}
#pragma mark - notification
- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSApplicationDidFinishLaunchingNotification
                                                  object:nil];
    
    if ([self fkRealGroupState] == NSOnState)
    {
        [self addObservers];
        [self addKeyboardEventMonitor];
    }
    
    [self addMenu];
}

- (void)menuDidChangeItemNotification:(NSNotification *)noti
{
    if (self.menuState != NSOnState)
    {
        return;
    }
    
    NSMenu *menu = noti.object;
    if ([menu.title isKindOfClass:NSClassFromString(kDVTPlugInLocalizedString)] &&
        [[menu.title valueForKeyPath:@"_key"] isEqualToString:kIDEStructureNavigatorKey])
    {
        NSInteger index = [noti.userInfo[@"NSMenuItemIndex"] integerValue];
        NSMenuItem *item = menu.itemArray[index];
        
        if (![item.title isKindOfClass:NSClassFromString(kDVTPlugInLocalizedString)])
        {
            if ([item.title isEqualToString:kNewRealGroupItemTitle])
            {
                //与New Group保持一致
                NSMenuItem *newGroupItem = menu.itemArray[index-1];
                item.enabled = newGroupItem.enabled;
            }
            else if ([item.title isEqualToString:kDeleteRealGroupItemTitle])
            {
                //与Delete保持一致
                NSMenuItem *deleteItem = menu.itemArray[index-1];
                item.enabled = deleteItem.enabled;
            }
        }
        else
        {
            if ([[item.title valueForKeyPath:@"_key"] isEqualToString:kNewGroupContextKey])
            {
                NSMenuItem *newRealGroupItem = menu.itemArray[index+1];
                newRealGroupItem.enabled = item.enabled;
            }
            else if ([[item.title valueForKeyPath:@"_key"] isEqualToString:kDeleteContextKey])
            {
                NSMenuItem *deleteRealGroupItem = menu.itemArray[index+1];
                deleteRealGroupItem.enabled = item.enabled;
            }
        }
    }
}

- (void)menuDidAddItemNotification:(NSNotification *)noti
{
    if (self.menuState != NSOnState)
    {
        return;
    }
    
    NSMenu *menu = noti.object;
    if ([menu.title isKindOfClass:NSClassFromString(kDVTPlugInLocalizedString)] &&
        [[menu.title valueForKeyPath:@"_key"] isEqualToString:kIDEStructureNavigatorKey] &&
        menu.delegate != self)
    {
        menu.delegate = self;
    }
}

- (void)controlTextDidEndEditingNotification:(NSNotification *)noti
{
    if (self.menuState != NSOnState ||
        !self.isRealCreate)
    {
        return;
    }
    
    //真实修改文件名称
    self.pathString = nil;
    self.groupNameBeforeEditing = nil;
    self.textField = nil;
    self.isRealCreate = NO;
    self.ideTarget = nil;
    self.newSubgroupIndex = NSNotFound;
    
    NSTextField *textField = noti.object;
    if (textField.delegate == self)
    {
        textField.delegate = nil;
    }
}
- (void)controlTextDidBeginEditingNotification:(NSNotification *)noti
{
    if (self.menuState != NSOnState ||
        !self.isRealCreate)
    {
        return;
    }
    
    self.groupNameBeforeEditing = [noti.object valueForKeyPath:kStringValueBeforeEditingKeyPath];
    
    self.textField = noti.object;
    self.textField.delegate = self;
}

- (void)fkRealGroupRealCreateNotification:(NSNotification *)noti
{
    self.isRealCreate = YES;
}

- (void)fkRealGroupCreateNotification:(NSNotification *)noti
{
    if (self.menuState != NSOnState ||
        !self.isRealCreate)
    {
        return;
    }
    
    NSDictionary *userInfo = noti.userInfo;
    
    self.ideTarget = noti.object;
    
    self.pathString = userInfo[kPathStringKey];
    self.newSubgroupIndex = [userInfo[kNewSubgroupIndexStringKey] integerValue];
}
/**
 *  设置标识
 */
- (void)fkRealGroupDeleteRealGroupFlagNotification:(NSNotification *)noti
{
    self.isDeleteRealGroup = YES;
}
/**
 *  删除文件夹
 */
- (void)fkRealGroupDeleteRealGroupNotification:(NSNotification *)noti
{
    if (!self.isDeleteRealGroup || !self.isMoveToTrash)
    {
        self.isMoveToTrash = YES;
        
        return;
    }
    
    self.isDeleteRealGroup = NO;
    
    for (NSString *groupPath in noti.object)
    {
        [self moveToTrashWithGroupPath:groupPath];
    }
}

- (void)fkRealGroupMoveToTrashNotification:(NSNotification *)noti
{
    if (self.menuState != NSOnState)
    {
        return;
    }
    
    self.isMoveToTrash = ((NSNumber *)noti.object).boolValue;
}

#pragma mark - button pressed
- (void)fk_buttonPressed:(id)arg1
{
    //Move To Trash
    BOOL isMoveToTrash = YES;
    NSString *buttonTitle = [NSString stringWithString:((NSButton *)arg1).title];
    if (![buttonTitle isEqualToString:kMoveToTrashButtonTitle])
    {
        //移动到垃圾箱
        isMoveToTrash = NO;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kFKRealGroupMoveToTrashNotificationKey
                                                        object:@(isMoveToTrash)];
    
    [self fk_buttonPressed:arg1];
}
#pragma mark - delegate
- (void)menuWillOpen:(NSMenu *)menu
{
    NSMenuItem *newGroupItem;
    NSMenuItem *newRealGroupItem;
    NSMenuItem *deleteItem;
    NSMenuItem *deleteRealGroupItem;
    
    NSInteger   newGroupItemIndex = NSNotFound;
    NSInteger   deleteItemIndex = NSNotFound;
    
    for (int i = 0; i < menu.itemArray.count; i++)
    {
        NSMenuItem *item = menu.itemArray[i];
        
        if ([item.title isKindOfClass:NSClassFromString(kDVTPlugInLocalizedString)])
        {
            if ([[item.title valueForKeyPath:@"_key"] isEqualToString:kNewGroupContextKey])
            {
                newGroupItem = item;
                newGroupItemIndex = i;
            }
            else if ([[item.title valueForKeyPath:@"_key"] isEqualToString:kDeleteContextKey])
            {
                deleteItem = item;
                deleteItemIndex = i;
            }
            continue;
        }
        else
        {
            if ([item.title isEqualToString:kNewRealGroupItemTitle])
            {
                newRealGroupItem = item;
            }
            else if ([item.title isEqualToString:kDeleteRealGroupItemTitle])
            {
                deleteRealGroupItem = item;
            }
            continue;
        }
    }
    
    if (self.menuState == NSOnState &&
        menu.itemArray.count > 0)
    {
        if (!newRealGroupItem &&
            newGroupItemIndex != NSNotFound)
        {
            //添加 New Real Group
            newRealGroupItem =
            [[NSMenuItem alloc] initWithTitle:kNewRealGroupItemTitle
                                       action:@selector(fk_contextMenu_newRealGroupFolderOrPage:)
                                keyEquivalent:@""];
            newRealGroupItem.enabled = YES;
            [menu insertItem:newRealGroupItem atIndex:newGroupItemIndex+1];
        }
        newRealGroupItem.hidden = NO;
        
        if (!deleteRealGroupItem &&
            deleteItemIndex != NSNotFound)
        {
            //添加 Delete Real Group
            deleteRealGroupItem =
            [[NSMenuItem alloc] initWithTitle:kDeleteRealGroupItemTitle
                                       action:@selector(fk_contextMenu_deleteRealGroup:)
                                keyEquivalent:@""];
            deleteRealGroupItem.enabled = YES;
            [menu insertItem:deleteRealGroupItem atIndex:deleteItemIndex+1];
        }
        deleteRealGroupItem.hidden = NO;
    }
    else
    {
        if (newRealGroupItem)
        {
            newRealGroupItem.hidden = YES;
        }
        
        if (deleteRealGroupItem)
        {
            deleteRealGroupItem.hidden = YES;
        }
    }
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    if (self.isDeleteRealGroup)
    {
        return YES;
    }
    
    if ([((NSTextField *)control).stringValue isEqualToString:@""])
    {
        [self alertWithMessageText:@"The folder name can not be empty."];
        return NO;
    }
    
    return [self control:control groupName:((NSTextField *)control).stringValue];
}

- (BOOL)control:(NSControl *)control groupName:(NSString *)groupName
{
    if (self.pathString == nil ||
        [self.pathString isEqualToString:@""])
    {
        //此情况下为没有正确获取到路径 那么允许直接命名 但并不创建真实文件夹
        [self alertWithMessageText:@"Could not create folder, please delete and try anain."];
        
        return YES;
    }
    
    Xcode3Group *targetGroup = [self.ideTarget valueForKeyPath:@"_targetGroup"];
    
    if (![targetGroup isKindOfClass:NSClassFromString(@"Xcode3Group")])
    {
        return YES;
    }
    
    PBXGroup *targetPBXGroup = [targetGroup valueForKeyPath:@"_group"];
    
    NSArray *subitems = targetPBXGroup.children;
    
    BOOL isContainInItems = [self isContainSameNameGroup:groupName
                                              inSubitems:subitems];
    
    BOOL isContainInPath  = [self isContainSameNameGroup:groupName
                                                  inPath:self.pathString];
    
    if ([[control valueForKeyPath:kStringValueBeforeEditingKeyPath]
         isEqualToString:groupName])
    {
        //如果文件名称和编辑前一致，则认为工程中不包含此文件夹
        isContainInItems = NO;
    }
    
    NSString *newDictPath = [NSString stringWithFormat:@"%@/%@",
                             self.pathString,
                             groupName];
    
    if (!isContainInItems && !isContainInPath)
    {
        //目录中无，本地无的文件夹，直接创建
        NSError *error;
        BOOL isSuccess = [[NSFileManager defaultManager] createDirectoryAtPath:newDictPath
                                                   withIntermediateDirectories:YES
                                                                    attributes:nil
                                                                         error:&error];
        
        if (isSuccess)
        {
            //修改链接路径
            if (self.newSubgroupIndex < subitems.count)
            {
                PBXGroup *newGroup = subitems[self.newSubgroupIndex];
                [newGroup setValue:groupName forKeyPath:@"_name"];
                [newGroup setValue:groupName forKeyPath:@"_path"];
                return YES;
            }
            else
            {
                [self alertWithMessageText:@"Path modification failed, please try again."];
                return NO;
            }
        }
        else
        {
            //警告 - 文件夹创建失败
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
        }
    }
    else if (isContainInItems && isContainInPath)
    {
        //目录中有，本地有的文件夹，直接警告，不创建；
        [self alertWithMessageText:[NSString stringWithFormat:@"%@\"%@\"%@",@"The folder name is ",groupName,@" has been occupied on the disk directory, and has been added to the project, please select another name."]];
    }
    else if (!isContainInItems && isContainInPath)
    {
        //目录中无，本地有的文件夹，直接警告
        [self alertWithMessageText:[NSString stringWithFormat:@"%@\"%@\"%@",@"The folder name is ",groupName,@" has been occupied on the project，but did not add to the project, please add or select another name."]];
    }
    else
    {
        //目录中有，本地无的文件夹，警告，不创建
        [self alertWithMessageText:[NSString stringWithFormat:@"%@\"%@\"%@",@"The folder name is ",groupName,@" has been occupied in the project, please select another name."]];
    }
    return NO;
}
#pragma mark - hook method
#pragma mark - new group
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
    [[NSNotificationCenter defaultCenter] postNotificationName:kFKRealGroupCreateNotificationKey
                                                        object:self
                                                      userInfo:@{kPathStringKey:[((IDEContainerItemStructureEditingTarget *)self) valueForKeyPath:kPathStringKeyPath]?:@"",
                                                                 kNewSubgroupIndexStringKey:@(arg1)}];
    
    return [self fk_addNewSubgroupAtIndex:arg1 newGroupBlock:arg2];
}

#pragma mark - delete group
- (void)fk_contextMenu_delete:(id)arg1
{
    [self fk_contextMenu_delete:arg1];
}

- (void)fk_contextMenu_deleteRealGroup:(id)arg1
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kFKRealGroupDeleteRealGroupFlagNotificationKey
                                                        object:@(1)];
    
    [self fk_contextMenu_delete:arg1];
}

- (BOOL)fk_structureEditingRemoveSubitemsAtIndexes:(id)arg1 error:(id *)arg2
{
    Xcode3Group *targetGroup = [self valueForKeyPath:@"_targetGroup"];
    
    if (![targetGroup isKindOfClass:NSClassFromString(@"Xcode3Group")])
    {
        return YES;
    }
    
    PBXGroup *targetPBXGroup = [targetGroup valueForKeyPath:@"_group"];
    
    NSArray *subitems = targetPBXGroup.children;
    
    NSMutableArray *pathArray = [NSMutableArray array];
    
    NSIndexSet *indexSet = arg1;
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        id item = subitems[idx];
        if ([item isKindOfClass:NSClassFromString(@"PBXGroup")])
        {
            PBXGroup *group = item;
            if ([group valueForKeyPath:@"_path"])
            {
                //文件夹路径
                NSString *parentGroupPath = [targetGroup valueForKeyPath:@"_resolvedFilePath._pathString"];
                NSString *groupPath = [NSString stringWithFormat:@"%@/%@", parentGroupPath, [group valueForKeyPath:@"_path"]];
                [pathArray addObject:groupPath];
            }
        }
    }];
    
    BOOL isRemoved = [self fk_structureEditingRemoveSubitemsAtIndexes:arg1 error:arg2];
    
    if (isRemoved)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kFKRealGroupDeleteRealGroupNotificationKey
                                                            object:pathArray];
    }
    return isRemoved;
}

#pragma mark - method
/**
 *  是否包含同名文件夹在父文件夹数组内
 *
 *  @param groupName 文件夹名称
 *  @param subitems  父文件夹数组
 *
 *  @return 是否包含
 */
- (BOOL)isContainSameNameGroup:(NSString *)groupName inSubitems:(NSArray *)subitems
{
    for (id item in subitems)
    {
        if ([item isKindOfClass:NSClassFromString(@"PBXGroup")] &&
            [((PBXGroup *)item).name isEqualToString:groupName])
        {
            return YES;
        }
    }
    return NO;
}

/**
 *  是否包含同名文件夹在路径上
 *
 *  @param groupName 文件夹名称
 *  @param path      文件夹路径
 *
 *  @return 是否包含
 */
- (BOOL)isContainSameNameGroup:(NSString *)groupName inPath:(NSString *)path
{
    NSString *dictPath = [NSString stringWithFormat:@"%@/%@", path, groupName];
    
    BOOL isDict;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:dictPath
                                                         isDirectory:&isDict];
    if (isExists && isDict)
    {
        return YES;
    }
    return NO;
}

/**
 *  FKRealGroup开关状态
 *
 *  @return 是否开启
 */
- (NSCellStateValue)fkRealGroupState
{
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:kFKRealGroupKey];
    if (!value)
    {
        value = @(1);
    }
    return value.integerValue;
}
/**
 *  保存FKRealGroup开关状态
 */
- (void)saveFKRealGroupOpenState
{
    [[NSUserDefaults standardUserDefaults] setValue:@(self.menuState)
                                             forKey:kFKRealGroupKey];
}

/**
 *  移动文件夹到废纸篓
 *
 *  @param groupPath 待删除的文件夹路径
 */
- (void)moveToTrashWithGroupPath:(NSString *)groupPath
{
    BOOL isDict;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:groupPath
                                                         isDirectory:&isDict];
    if (isExists && isDict)
    {
        NSError *error;
        //将文件夹移动到废纸篓中
        NSURL *trashItemUrl = [NSURL fileURLWithPath:groupPath isDirectory:YES];
        
        BOOL isSuccess = [[NSFileManager defaultManager] trashItemAtURL:trashItemUrl
                                                       resultingItemURL:nil
                                                                  error:&error];
#ifdef DEBUG
        if (!isSuccess)
        {
            NSLog(@"delete failed --%@ -- %@", trashItemUrl, error);
        }
#endif
    }
}

- (void)alertWithMessageText:(NSString *)messageText
{
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = messageText;
    [alert runModal];
}

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
    
    NSMenuItem *subMenuItem = [[NSMenuItem alloc] init];
    subMenuItem.title = @"FKRealGroup";
    subMenuItem.target = self;
    subMenuItem.action = @selector(toggleMenu:);
    subMenuItem.state = [self fkRealGroupState];
    [pluginsMenuItem.submenu addItem:subMenuItem];
    
    self.menuState = subMenuItem.state;
}

- (void)toggleMenu:(NSMenuItem *)menuItem
{
    menuItem.state = !menuItem.state;
    self.menuState = menuItem.state;
    
    if (menuItem.state == NSOnState)
    {
        [self addObservers];
        [self addKeyboardEventMonitor];
    }
    else
    {
        [self removeObservers];
        [self removeKeyboardEventMonitor];
    }
    
    [self saveFKRealGroupOpenState];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
