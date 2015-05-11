//
//  Utility.m
//  YSRealmExample
//
//  Created by Yu Sugawara on 2014/11/18.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "TwitterRealmStore.h"
#import "NSData+YSRealmStore.h"

@implementation TwitterRealmStore

+ (instancetype)sharedStore
{
    static TwitterRealmStore *__instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __instance =  [[self alloc] initWithRealmName:@"twitter"];
        DDLogInfo(@"class = %@; path = %@", NSStringFromClass([self class]), [__instance realm].path);
    });
    return __instance;
}

+ (instancetype)sharedStoreInMemory
{
    static TwitterRealmStore *__instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __instance = [[self alloc] initWithRealmName:@"twitter-in-memory"
                                            inMemory:YES];
        DDLogInfo(@"class = %@; path = %@", NSStringFromClass([self class]), [__instance realm].path);
    });
    return __instance;
}

+ (instancetype)sharedEncryptionStore
{
    static TwitterRealmStore *__instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __instance = [[self alloc] initEncryptionWithRealmName:@"twitter-encryption"];
        DDLogInfo(@"class = %@; path = %@", NSStringFromClass([self class]), [__instance realm].path);
    });
    return __instance;
}

- (void)addTweetWithTweetJsonObject:(NSDictionary*)tweetJsonObject
{
    [self writeObjectsWithObjectsBlock:^id(YSRealmOperation *operation, RLMRealm *realm) {
        return [[Tweet alloc] initWithValue:tweetJsonObject];
    }];
    
    RLMRealm *realm = [self realm];
    NSNumber *twID = tweetJsonObject[@"id"];
    if ([twID isKindOfClass:[NSNumber class]] && twID) {
        NSAssert2([Tweet objectInRealm:realm forPrimaryKey:twID].id == [twID longLongValue], @"%zd - %zd", [Tweet objectInRealm:realm forPrimaryKey:twID].id, [twID longLongValue]);
    }
}

- (void)addTweetsWithTweetJsonObjects:(NSArray *)tweetJsonObjects
{
    [self writeTransactionWithWriteBlock:^(YSRealmWriteTransaction *transaction, RLMRealm *realm) {
        for (NSDictionary *tweetObj in tweetJsonObjects) {
            if (transaction.isInterrupted) return ;
            [realm addOrUpdateObject:[[Tweet alloc] initWithValue:tweetObj]];
        }
    }];
}

- (YSRealmWriteTransaction*)addTweetsWithTweetJsonObjects:(NSArray *)tweetJsonObjects
                                               completion:(YSRealmStoreWriteTransactionCompletion)completion
{
    return [self writeTransactionWithWriteBlock:^(YSRealmWriteTransaction *transaction, RLMRealm *realm) {
        for (NSDictionary *tweetObj in tweetJsonObjects) {
            if (transaction.isInterrupted) return ;
            [realm addOrUpdateObject:[[Tweet alloc] initWithValue:tweetObj]];
        }
    } completion:completion];
}

- (void)addTweetsWithCount:(NSUInteger)count
{
    [self writeObjectsWithObjectsBlock:^id(YSRealmOperation *operation, RLMRealm *realm) {
        NSMutableArray *tweets = [NSMutableArray arrayWithCapacity:count];
        for (NSUInteger twID = 0; twID < count; twID++) {
            [tweets addObject:[[Tweet alloc] initWithValue:[JsonGenerator tweetWithID:twID]]];
        }
        return tweets;
    }];
    
    for (NSUInteger twID = 0; twID < count; twID++) {
        NSAssert([Tweet objectInRealm:self.realm forPrimaryKey:@(twID)] != nil, nil);
    }
}

- (RLMResults *)fetchAllTweets
{
    return [[Tweet allObjectsInRealm:[self realm]] sortedResultsUsingProperty:@"id" ascending:NO];
}

#pragma mark - YSRealmStoreProtocol

- (void)migrationWithMigration:(RLMMigration *)migration oldSchemaVersion:(NSUInteger)oldSchemaVersion
{
    DDLogDebug(@"oldSchemaVersion: %zd", oldSchemaVersion);
    if (oldSchemaVersion < 2) {
        /**
         *  あとからUserのIDをPrimaryKeyに変更した。マイグレーションのメモ。 (Realm 0.87.4)
         *  IDがない場合そのままだと例外が発生するが、すでにIDがある場合にPrimaryKeyなので変更不可で変更しようとすると例外が発生する。
         *  IDがない物に対してIDを設定する。(以下は本来であればIDが重複しないようにする必要があるので重複IDのUserは削除するようにしなければいけない。)
         */
        [migration enumerateObjects:[User className] block:^(RLMObject *oldObject, RLMObject *newObject) {
            static int64_t userID = 0;
            if (((User*)newObject).id == 0) {
                NSLog(@"user %@", newObject);
                ((User*)newObject).id = userID++;
            }
        }];
    }
    if (oldSchemaVersion < 8) {
        /**
         *  NSData *color を追加
         */
        [migration enumerateObjects:[User className] block:^(RLMObject *oldObject, RLMObject *newObject) {
            User *user = (id)newObject;
            user.color = [NSData ys_realmDefaultData];
        }];
    }
    
    if (oldSchemaVersion < 12) {
        /**
         *  indexedPropertiesを試すのにidStringを追加
         */
        [migration enumerateObjects:[Tweet className] block:^(RLMObject *oldObject, RLMObject *newObject) {
            newObject[@"idString"] = [newObject[@"id"] stringValue];
        }];
    }
}

- (NSUInteger)schemaVersion
{
    return 12;
}

@end
