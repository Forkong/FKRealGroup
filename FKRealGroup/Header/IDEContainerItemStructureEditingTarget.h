/*
 *     Generated by class-dump 3.3.4 (64 bit).
 *
 *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2011 by Steve Nygard.
 */

//#import "NSObject.h"

//#import "IDEStructureEditingDropTarget-Protocol.h"
//#import "IDEStructureEditingGroupingTarget-Protocol.h"
//#import "IDEStructureEditingRemoveSubitemsTarget-Protocol.h"

@class DVTObservingToken, IDEGroup, IDENavigableItem;

@interface IDEContainerItemStructureEditingTarget : NSObject
//<IDEStructureEditingDropTarget, IDEStructureEditingGroupingTarget, IDEStructureEditingRemoveSubitemsTarget>
//{
//    IDEGroup *_targetGroup;
//    DVTObservingToken *_targetGroupValidObservationToken;
//    IDENavigableItem *_targetNavigableItem;
//    long long _targetIndex;
//}

+ (void)_addFileURLsForContainerItem:(id)arg1 to:(id)arg2;
+ (BOOL)_structureEditingAcceptDropWithContext:(id)arg1 index:(long long)arg2;
+ (id)_containerAddingItemsAssistantExtensionForContainer:(id)arg1;
+ (BOOL)_acceptDropAtIndex:(long long)arg1 withContext:(id)arg2;
+ (BOOL)_acceptDropAtIndex:(long long)arg1 withContext:(id)arg2 fileURLs:(id)arg3;
+ (BOOL)_acceptDropAtIndex:(long long)arg1 withContext:(id)arg2 containerItems:(id)arg3;
+ (id)_targetForStructureEditingOperation:(int)arg1 proposedNavigableItem:(id)arg2 proposedChildIndex:(long long)arg3;
//- (void).cxx_destruct;
- (BOOL)structureEditingRemoveSubitemsAtIndexes:(id)arg1 error:(id *)arg2;
- (id)structureEditingFileURLsForSubitemsAtIndexes:(id)arg1;
- (BOOL)structureEditingCanRemoveSubitemsAtIndexes:(id)arg1;
- (BOOL)structureEditingGroupSubitemsAtIndexes:(id)arg1 groupIndex:(long long *)arg2;
- (BOOL)structureEditingCanGroupSubitemsAtIndexes:(id)arg1;
- (BOOL)_canGroupSubitemsAtIndexes:(id)arg1 groupIndex:(long long *)arg2 shouldGroup:(BOOL)arg3;
- (BOOL)structureEditingAddNewSubgroup;
- (BOOL)structureEditingCanAddNewSubgroup;
- (BOOL)_testOrAddNewGroupAtChildIndex:(long long)arg1 shouldAdd:(BOOL)arg2;
- (BOOL)_addNewSubgroupAtIndex:(unsigned long long)arg1 newGroupBlock:(id)arg2;
- (BOOL)structureEditingAcceptInsertionOfSubitemsForContext:(id)arg1;
- (BOOL)structureEditingValidateInsertionOfSubitemsForContext:(id)arg1;
- (unsigned long long)_targetIndexForInsertion;
- (id)insertSubitemsAssistantContext;
- (BOOL)_structureEditingValidateDropWithContext:(id)arg1 atIndex:(long long)arg2;
- (BOOL)_acceptTemplateDropWithContext:(id)arg1 atIndex:(long long)arg2;
- (unsigned long long)_validateTemplateDropWithContext:(id)arg1 atIndex:(long long)arg2;
- (id)structureEditingNaturalFilePathForDropTarget;
- (BOOL)isEqual:(id)arg1;
- (unsigned long long)hash;
- (id)actualNavigableItem;
- (long long)actualChildIndex;
- (void)dealloc;
- (id)_initWithTargetGroup:(id)arg1 targetNavigableItem:(id)arg2 targetIndex:(long long)arg3;
- (id)init;

@end

