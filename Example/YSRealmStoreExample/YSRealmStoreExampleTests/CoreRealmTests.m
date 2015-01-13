//
//  CoreRealmTests.m
//  YSRealmExample
//
//  Created by Yu Sugawara on 2014/10/27.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "TwitterRealmStore.h"

@interface CoreRealmTests : XCTestCase

@end

@implementation CoreRealmTests

- (void)setUp
{
    [super setUp];
    
    [[TwitterRealmStore sharedStore] deleteAllObjects];
}

#pragma mark - Init

- (void)testInit
{
    NSString *name = @"database";
    
    YSRealmStore *store = [[YSRealmStore alloc] initWithRealmName:name];
    
    NSString *path = [store realm].path;
    DDLogDebug(@"%s; path = %@;", __func__, path);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    XCTAssertTrue([fileManager fileExistsAtPath:path]);
    
    NSError *error = nil;
    XCTAssertTrue([fileManager removeItemAtPath:path error:&error]);
    XCTAssertNil(error);
}

#pragma mark - Insert

- (void)testInsertTweet
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    
    [store addTweetWithTweetJsonObject:[JsonGenerator tweet]];
    
    Tweet *addedTweet = [[Tweet allObjectsInRealm:[store realm]] firstObject];
    XCTAssertNotNil(addedTweet);
    
    XCTAssertEqual(addedTweet.id, INT64_MAX);
    XCTAssertGreaterThan(addedTweet.text.length, 0);
    
    User *user = addedTweet.user;
    XCTAssertNotNil(user);
    XCTAssertEqual(user.id, INT64_MAX);
    XCTAssertGreaterThan(user.name.length, 0);
    
    Entities *entities = addedTweet.entities;
    XCTAssertNotNil(entities);
    XCTAssertEqual([entities.urls count], 1);
    for (Url *url in entities.urls) {
        XCTAssertNotNil(url);
        XCTAssertGreaterThan(url.url.length, 0);
    }
}

- (void)testInsertTweets
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    
    NSUInteger count = 10;
    [store addTweetsWithCount:count];
    
    XCTAssertEqual([[Tweet allObjectsInRealm:[store realm]] count], count);
    XCTAssertEqual([[User allObjectsInRealm:[store realm]] count], count);
    
    RLMResults *tweets = [[Tweet allObjectsInRealm:[store realm]] sortedResultsUsingProperty:@"id" ascending:YES];
    for (NSUInteger i = 0; i < [tweets count]; i++) {
        Tweet *tweet = tweets[i];
        XCTAssertEqual(tweet.id, i);
        XCTAssertEqual(tweet.user.id, i);
    }
}

- (void)testInsertTweetOfEmptyArray
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    
    [store addTweetWithTweetJsonObject:[JsonGenerator tweetOfContainEmptyArray]];
    
    Tweet *addedTweet = [[Tweet allObjectsInRealm:[store realm]] firstObject];
    XCTAssertNotNil(addedTweet);
    
    XCTAssertEqual(addedTweet.id, INT64_MAX);
    XCTAssertGreaterThan(addedTweet.text.length, 0);
    
    User *user = addedTweet.user;
    XCTAssertNotNil(user);
    XCTAssertEqual(user.id, INT64_MAX);
    XCTAssertGreaterThan(user.name.length, 0);
    
    Entities *entities = addedTweet.entities;
    XCTAssertNil(entities);
}

- (void)testInsertTweetOfConstainNSNull
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    
    [store addTweetWithTweetJsonObject:[JsonGenerator tweetOfContainNSNull]];
    
    Tweet *addedTweet = [[Tweet allObjectsInRealm:[store realm]] firstObject];
    XCTAssertNotNil(addedTweet);
    
    XCTAssertEqual(addedTweet.id, 0);
    XCTAssertEqual(addedTweet.text.length, 0);
    
    User *user = addedTweet.user;
    XCTAssertNil(user);
    XCTAssertEqual(user.id, 0);
    XCTAssertEqual(user.name.length, 0);
    
    Entities *entities = addedTweet.entities;
    XCTAssertNil(entities);
}

- (void)testInsetTweetOfKeyIsNotEnough
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    
    [store addTweetWithTweetJsonObject:[JsonGenerator tweetOfKeyIsNotEnough]];
    
    Tweet *addedTweet = [[Tweet allObjectsInRealm:[store realm]] firstObject];
    XCTAssertNotNil(addedTweet);
    
    XCTAssertEqual(addedTweet.id, 0);
    XCTAssertEqual(addedTweet.text.length, 0);
    
    User *user = addedTweet.user;
    XCTAssertNil(user);
    XCTAssertEqual(user.id, 0);
    XCTAssertEqual(user.name.length, 0);
    
    Entities *entities = addedTweet.entities;
    XCTAssertNil(entities);
}

- (void)testUniqueInsert
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    
    [store addTweetWithTweetJsonObject:[JsonGenerator tweet]];
    
    Tweet *addedTweet = [[Tweet allObjectsInRealm:[store realm]] firstObject];
    XCTAssertNotNil(addedTweet);
    
    Tweet *tweet = [[Tweet alloc] initWithObject:[JsonGenerator tweet]];
    tweet.text = @"";
    tweet.user = nil;
    tweet.entities = nil;
    [self addOrUpdateTweet:tweet];
    
    XCTAssertEqual([[Tweet allObjectsInRealm:[store realm]] count], 1);
    addedTweet = [[Tweet allObjectsInRealm:[store realm]] firstObject];
    XCTAssertEqualObjects(addedTweet.text, @"");
    XCTAssertNil(tweet.user);
    XCTAssertNil(tweet.entities);
}

- (void)testInsertNestedObject
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    int64_t tweetID = 0;
    int64_t userID = 0;
    NSDictionary *tweetObj = [JsonGenerator tweetWithTweetID:tweetID userID:userID];
    
    [store addTweetWithTweetJsonObject:tweetObj];
    
    XCTAssertNotNil([User objectInRealm:[store realm] forPrimaryKey:@(userID)]);
    
    int64_t tweetID2 = 1;
    [[TwitterRealmStore sharedStore] addTweetWithTweetJsonObject:[JsonGenerator tweetWithTweetID:tweetID2 userID:userID]];
    
    XCTAssertNotNil([Tweet objectInRealm:[store realm] forPrimaryKey:@(tweetID)]);
    XCTAssertNotNil([Tweet objectInRealm:[store realm] forPrimaryKey:@(tweetID)].user);
    XCTAssertEqual([Tweet objectInRealm:[store realm] forPrimaryKey:@(tweetID)].user.id, userID);
    XCTAssertNotNil([Tweet objectInRealm:[store realm] forPrimaryKey:@(tweetID2)]);
    XCTAssertNotNil([Tweet objectInRealm:[store realm] forPrimaryKey:@(tweetID2)].user);
    XCTAssertEqual([Tweet objectInRealm:[store realm] forPrimaryKey:@(tweetID2)].user.id, userID);
    
    XCTAssertEqual([[Tweet allObjectsInRealm:[store realm]] count], 2);
    XCTAssertEqual([[User allObjectsInRealm:[store realm]] count], 1);
}

#pragma mark - Equal

- (void)testEqual
{
    Tweet *tweet = [[Tweet alloc] initWithObject:[JsonGenerator tweet]];
    [self addOrUpdateTweet:tweet];
    
    Tweet *addedTweet = [[Tweet allObjectsInRealm:[[TwitterRealmStore sharedStore] realm]]  firstObject];
    
    XCTAssertEqualObjects(tweet, addedTweet);
}

#pragma mark - Update

- (void)testUpdate
{
    Tweet *tweet = [[Tweet alloc] initWithObject:[JsonGenerator tweet]];
    [self addOrUpdateTweet:tweet];
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        tweet.text = @"";
        tweet.user = nil;
        tweet.entities = nil;
    }];
    
    RLMRealm *realm = [[TwitterRealmStore sharedStore] realm];
    XCTAssertEqual([[Tweet allObjectsInRealm:realm] count], 1);
    Tweet *addedTweet = [[Tweet allObjectsInRealm:realm] firstObject];
    XCTAssertEqualObjects(tweet, addedTweet);
    XCTAssertEqual(addedTweet.id, INT64_MAX);
    XCTAssertEqualObjects(addedTweet.text, @"");
    XCTAssertNil(addedTweet.user);
    XCTAssertNil(addedTweet.entities);
}

#pragma mark - Delete

- (void)testDeleteRelationObject
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    
    [store addTweetWithTweetJsonObject:[JsonGenerator tweet]];
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        [realm deleteObjects:[User allObjectsInRealm:realm]];
    }];
    
    Tweet *tweet = [[Tweet allObjectsInRealm:[store realm]] firstObject];
    XCTAssertNil(tweet.user);
}

- (void)testDeleteRelationObjects
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    
    int64_t count = 10;
    for (int64_t twID = 0; twID < count; twID++) {
        [store addTweetWithTweetJsonObject:[JsonGenerator tweetWithTweetID:twID userID:0]];
    }
    XCTAssertEqual([[Tweet allObjectsInRealm:[store realm]] count], count);
    XCTAssertEqual([[User allObjectsInRealm:[store realm]] count], 1);
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        [realm deleteObjects:[User allObjectsInRealm:realm]];
    }];
    
    for (Tweet *tweet in [Tweet allObjectsInRealm:[store realm]]) {
        XCTAssertNil(tweet.user);
    }
}

- (void)testDeleteToManyRelationObjects
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    
    [store addTweetWithTweetJsonObject:[JsonGenerator tweetWithTweetID:0 userID:0 urlCount:5]];
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        [realm deleteObjects:[Url allObjectsInRealm:realm]];
    }];
    
    /* RLMArray は空配列になるだけでオブジェクトは削除されない */
    XCTAssertEqual([[Entities allObjectsInRealm:[store realm]] count], 1);
    Entities *entities = [[Entities allObjectsInRealm:[store realm]] firstObject];
    XCTAssertEqual([entities.urls count], 0);
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        for (Entities *entities in [Entities allObjectsInRealm:realm]) {
            if ([entities.urls count] == 0) {
                [realm deleteObject:entities];
            }
        }
    }];
    
    XCTAssertEqual([[Entities allObjectsInRealm:[store realm]] count], 0);
    Tweet *tweet = [[Tweet allObjectsInRealm:[store realm]] firstObject];
    XCTAssertNil(tweet.entities);
}

- (void)testDeleteNestedRelationObjects
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    
    [store addTweetWithTweetJsonObject:[JsonGenerator tweetWithTweetID:0 userID:0 urlCount:5]];
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        Tweet *tweet = [[Tweet allObjectsInRealm:realm] firstObject];
        for (Url *url in tweet.entities.urls) {
            [realm deleteObject:url];
        }
        [realm deleteObject:tweet.entities];
        [realm deleteObject:tweet];
    }];
    
    XCTAssertEqual([[Tweet allObjectsInRealm:[store realm]] count], 0);
    XCTAssertEqual([[Entities allObjectsInRealm:[store realm]] count], 0);
    XCTAssertEqual([[Url allObjectsInRealm:[store realm]] count], 0);
}

- (void)testDeleteMultipleToManyRelationObjects
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    
    [store addTweetsWithCount:10];
    
    NSUInteger watchersCount = 3;
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        for (Tweet *tweet in [Tweet allObjectsInRealm:realm]) {
            for (NSUInteger userID = 0; userID < watchersCount; userID++) {
                User *user = [User objectInRealm:realm forPrimaryKey:@(userID)];
                if (user == nil) {
                    user = [[User alloc] initWithObject:[JsonGenerator userWithID:userID]];
                }
                [tweet.watchers addObject:user];
            }
        }
    }];
    
    for (Tweet *tweet in [Tweet allObjectsInRealm:[store realm]]) {
        XCTAssertEqual([tweet.watchers count], watchersCount);
    }
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        [realm deleteObjects:[User allObjectsInRealm:realm]];
    }];
    
    for (Tweet *tweet in [Tweet allObjectsInRealm:[store realm]]) {
        XCTAssertEqual([tweet.watchers count], 0);
    }
}

#pragma mark - Cancel

- (void)testCancelAddObject
{
    Tweet *tweet = [[Tweet alloc] initWithObject:[JsonGenerator tweet]];
    
    RLMRealm *realm = [[TwitterRealmStore sharedStore] realm];
    [realm beginWriteTransaction];
    [realm addOrUpdateObject:tweet];
    [realm cancelWriteTransaction];
    
    XCTAssertEqual([[Tweet allObjectsInRealm:realm] count], 0);
}

- (void)testCancelUpdateObject
{
    RLMRealm *realm = [[TwitterRealmStore sharedStore] realm];
    
    NSDictionary *tweetJsonObj = [JsonGenerator tweet];
    [self addOrUpdateTweet:[[Tweet alloc] initWithObject:tweetJsonObj]];
    
    Tweet *addedTweet = [[Tweet allObjectsInRealm:realm] firstObject];
    
    [realm beginWriteTransaction];
    
    addedTweet.text = @"";
    addedTweet.user = nil;
    addedTweet.entities = nil;
    
    XCTAssertEqualObjects(addedTweet.text, @"");
    XCTAssertNil(addedTweet.user);
    XCTAssertNil(addedTweet.entities);
    
    [realm cancelWriteTransaction];
    
    XCTAssertEqual(addedTweet.id, [tweetJsonObj[@"id"] longLongValue]);
    XCTAssertEqualObjects(addedTweet.text, tweetJsonObj[@"text"]);
    XCTAssertNotNil(addedTweet.user);
    XCTAssertNotNil(addedTweet.entities);
}

- (void)testCancelDeleteObject
{
    RLMRealm *realm = [[TwitterRealmStore sharedStore] realm];
    
    [self addOrUpdateTweet:[[Tweet alloc] initWithObject:[JsonGenerator tweet]]];
    
    XCTAssertGreaterThan([[Tweet allObjectsInRealm:realm] count], 0);
    XCTAssertGreaterThan([[User allObjectsInRealm:realm] count], 0);
    XCTAssertGreaterThan([[Entities allObjectsInRealm:realm] count], 0);
    XCTAssertGreaterThan([[Url allObjectsInRealm:realm] count], 0);
    
    
    [realm beginWriteTransaction];
    
    [realm deleteAllObjects];
    XCTAssertEqual([[Tweet allObjectsInRealm:realm] count], 0);
    XCTAssertEqual([[User allObjectsInRealm:realm] count], 0);
    XCTAssertEqual([[Entities allObjectsInRealm:realm] count], 0);
    XCTAssertEqual([[Url allObjectsInRealm:realm] count], 0);
    
    [realm cancelWriteTransaction];

    XCTAssertGreaterThan([[Tweet allObjectsInRealm:realm] count], 0);
    XCTAssertGreaterThan([[User allObjectsInRealm:realm] count], 0);
    XCTAssertGreaterThan([[Entities allObjectsInRealm:realm] count], 0);
    XCTAssertGreaterThan([[Url allObjectsInRealm:realm] count], 0);
}

#pragma mark - Query

- (void)testPredicateWithInt64Max
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    
    [store addTweetsWithCount:10];
    [self addOrUpdateTweet:[[Tweet alloc] initWithObject:[JsonGenerator tweetWithID:INT64_MAX]]];
    
    RLMResults *results = [Tweet objectsInRealm:[store realm] withPredicate:[NSPredicate predicateWithFormat:@"id = %lld", INT64_MAX]];
    XCTAssertEqual([results count], 1);
    Tweet *tweet = [results firstObject];
    XCTAssertEqual(tweet.id, INT64_MAX);
}

- (void)testPredicateWithUint64Max
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    
    [store addTweetsWithCount:10];
    [self addOrUpdateTweet:[[Tweet alloc] initWithObject:[JsonGenerator tweetWithID:UINT64_MAX]]];
    
    RLMResults *results = [Tweet objectsInRealm:[store realm] withPredicate:[NSPredicate predicateWithFormat:@"id = %llu", UINT64_MAX]];
    XCTAssertEqual([results count], 1);
    Tweet *tweet = [results firstObject];
    XCTAssertEqual(tweet.id, UINT64_MAX);
}

- (void)testFetchTweetWithUserID
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    
    [store addTweetsWithCount:10];
    
    int64_t id = 5;
    
    RLMResults *results = [Tweet objectsInRealm:[store realm] withPredicate:[NSPredicate predicateWithFormat:@"user.id = %@", @(id)]];
    XCTAssertEqual([results count], 1);
    Tweet *tweet = [results firstObject];
    XCTAssertEqual(tweet.id, id);
    XCTAssertEqual(tweet.user.id, id);
}

- (void)testFetchTweetWithUser
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    
    [store addTweetsWithCount:10];
    
    int64_t id = 5;
    
    RLMResults *results = [Tweet objectsInRealm:[store realm] withPredicate:[NSPredicate predicateWithFormat:@"user = %@", [User objectInRealm:[store realm] forPrimaryKey:@(id)]]];
    XCTAssertEqual([results count], 1);
    Tweet *tweet = [results firstObject];
    XCTAssertEqual(tweet.id, id);
    XCTAssertEqual(tweet.user.id, id);
}

- (void)testNil
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    
    NSMutableDictionary *tweetObj = [JsonGenerator tweetWithTweetID:0 userID:0].mutableCopy;
    [tweetObj removeObjectForKey:@"entities"];
    
    [store addTweetWithTweetJsonObject:tweetObj];
    [store addTweetWithTweetJsonObject:[JsonGenerator tweetWithTweetID:1 userID:1]];
    
    XCTAssertEqual([[Tweet allObjectsInRealm:[store realm]] count], 2);
    
    RLMResults *results = [Tweet objectsInRealm:[store realm] withPredicate:[NSPredicate predicateWithFormat:@"entities = nil"]];
    XCTAssertEqual([results count], 1);
    Tweet *tweet = [results firstObject];
    XCTAssertEqual(tweet.id, 0);
    XCTAssertNil(tweet.entities);
    
    results = [Tweet objectsInRealm:[store realm] withPredicate:[NSPredicate predicateWithFormat:@"entities != nil"]];
    XCTAssertEqual([results count], 1);
    tweet = [results firstObject];
    XCTAssertEqual(tweet.id, 1);
    XCTAssertNotNil(tweet.entities);
}

- (void)testANYWithPrimitiveValue
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    NSUInteger count = 10;
    
    [store addTweetsWithCount:count];
    XCTAssertEqual([[Tweet allObjectsInRealm:[store realm]] count], count);
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        for (Tweet *tweet in [[Tweet allObjectsInRealm:realm] sortedResultsUsingProperty:@"id" ascending:YES]) {
            for (NSUInteger userID = 0; userID <= tweet.id; userID++) {
                User *user = [User objectInRealm:realm forPrimaryKey:@(userID)];
                if (user == nil) {
                    user = [[User alloc] initWithObject:[JsonGenerator userWithID:userID]];
                }
                [tweet.watchers addObject:user];
            }
        }
    }];
    
    XCTAssertEqual([[User allObjectsInRealm:[store realm]] count], count);
    
    for (NSUInteger i = 0; i < count; i++) {
        RLMResults *tweets = [Tweet objectsInRealm:[store realm] where:@"ANY watchers.id = %d", i];
        XCTAssertEqual([tweets count], count - i);
    }
}

- (void)testANYWithPrimitiveValues
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    NSUInteger count = 10;
    
    [store addTweetsWithCount:count];
    XCTAssertEqual([[Tweet allObjectsInRealm:[store realm]] count], count);
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        for (Tweet *tweet in [[Tweet allObjectsInRealm:realm] sortedResultsUsingProperty:@"id" ascending:YES]) {
            for (NSUInteger userID = 0; userID <= tweet.id; userID++) {
                User *user = [User objectInRealm:realm forPrimaryKey:@(userID)];
                if (user == nil) {
                    user = [[User alloc] initWithObject:[JsonGenerator userWithID:userID]];
                }
                [tweet.watchers addObject:user];
            }
        }
    }];
    
    XCTAssertEqual([[User allObjectsInRealm:[store realm]] count], count);
    
    NSMutableArray *ids = @[].mutableCopy;
    for (NSUInteger i = 0; i < count; i++) {
        [ids addObject:@(i)];
    }
    XCTAssertEqual([ids count], count);
    
    RLMResults *tweets = [Tweet objectsInRealm:[store realm] where:@"ANY watchers.id IN %@", ids];
    XCTAssertEqual([tweets count], count);
}

- (void)testANYWithObject
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    NSUInteger count = 10;
    
    [store addTweetsWithCount:count];
    XCTAssertEqual([[Tweet allObjectsInRealm:[store realm]] count], count);
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        for (Tweet *tweet in [[Tweet allObjectsInRealm:realm] sortedResultsUsingProperty:@"id" ascending:YES]) {
            for (NSUInteger userID = 0; userID <= tweet.id; userID++) {
                User *user = [User objectInRealm:realm forPrimaryKey:@(userID)];
                if (user == nil) {
                    user = [[User alloc] initWithObject:[JsonGenerator userWithID:userID]];
                }
                [tweet.watchers addObject:user];
            }
        }
    }];
    
    XCTAssertEqual([[User allObjectsInRealm:[store realm]] count], count);
    
    for (NSUInteger i = 0; i < count; i++) {
        RLMResults *tweets = [Tweet objectsInRealm:[store realm] where:@"ANY watchers = %@", [User objectInRealm:[store realm] forPrimaryKey:@(i)]];
        XCTAssertEqual([tweets count], count - i);
    }
}

- (void)testANYWithObjects
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    NSUInteger count = 10;
    
    [store addTweetsWithCount:count];
    XCTAssertEqual([[Tweet allObjectsInRealm:[store realm]] count], count);
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        for (Tweet *tweet in [[Tweet allObjectsInRealm:realm] sortedResultsUsingProperty:@"id" ascending:YES]) {
            for (NSUInteger userID = 0; userID <= tweet.id; userID++) {
                User *user = [User objectInRealm:realm forPrimaryKey:@(userID)];
                if (user == nil) {
                    user = [[User alloc] initWithObject:[JsonGenerator userWithID:userID]];
                }
                [tweet.watchers addObject:user];
            }
        }
    }];
    
    XCTAssertEqual([[User allObjectsInRealm:[store realm]] count], count);
    
    NSMutableArray *users = @[].mutableCopy;
    for (NSUInteger i = 0; i < count; i++) {
        [users addObject:[User objectInRealm:[store realm] forPrimaryKey:@(i)]];
    }
    XCTAssertEqual([users count], count);
    
    RLMResults *tweets = [Tweet objectsInRealm:[store realm] where:@"ANY watchers IN %@", users];
    XCTAssertEqual([tweets count], count);
}

- (void)testAlternativeMethodOfCountFunction
{
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    NSUInteger count = 10;
    
    [store addTweetsWithCount:count];
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        for (int64_t tweetID = 0; tweetID < count; tweetID++) {
            if (tweetID < count/2) {
                Tweet *tweet = [Tweet objectInRealm:realm forPrimaryKey:@(tweetID)];
                
                NSUInteger watchersCount = arc4random_uniform(5) + 1;
                for (NSUInteger userID = 0; userID < watchersCount; userID++) {
                    User *user = [User objectInRealm:realm forPrimaryKey:@(userID)];
                    if (user == nil) {
                        user = [[User alloc] initWithObject:[JsonGenerator userWithID:userID]];
                    }
                    [tweet.watchers addObject:user];
                }
            }
        }
    }];
    XCTAssertEqual([[Tweet allObjectsInRealm:[store realm]] count], count);
    
    RLMResults *results = [Tweet objectsInRealm:[store realm] withPredicate:[NSPredicate predicateWithFormat:@"ANY watchers.id >= 0"]];
    XCTAssertEqual([results count], count/2);
    for (Tweet *tweet in results) {
        XCTAssertGreaterThan([tweet.watchers count], 0);
    }
    
    results = [Tweet objectsInRealm:[store realm] withPredicate:[NSPredicate predicateWithFormat:@"!(ANY watchers.id >= 0)"]];
    XCTAssertEqual([results count], count/2);
    for (Tweet *tweet in results) {
        XCTAssertEqual([tweet.watchers count], 0);
    }
}

- (void)testCount
{
#warning Unsupported (Realm 0.88.0)
#if 0
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    
    [store addTweetsWithCount:1];
    XCTAssertEqual([[Tweet allObjectsInRealm:[store realm]] count], 1);
    
    NSUInteger watchersCount = 3;
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        Tweet *tweet = [[Tweet allObjectsInRealm:realm] firstObject];
        for (NSUInteger userID = 0; userID < watchersCount; userID++) {
            User *user = [User objectInRealm:realm forPrimaryKey:@(userID)];
            if (user == nil) {
                user = [[User alloc] initWithObject:[JsonGenerator userWithID:userID]];
            }
            [tweet.watchers addObject:user];
        }
    }];
    
    XCTAssertEqual([[User allObjectsInRealm:[store realm]] count], watchersCount);
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"watchers.@count = %d", watchersCount];
    XCTAssertTrue([[Tweet objectsInRealm:[store realm] withPredicate:predicate] count]);
#endif
}

- (void)testCount2
{
#warning Unsupported (Realm 0.88.0)
#if 0
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    
    for (NSUInteger i = 0; i < 10; i++) {
        [store addTweetWithTweetJsonObject:[JsonGenerator tweetWithTweetID:i userID:i urlCount:0]];
    }
    
    int64_t id = INT64_MAX;
    NSUInteger urlCount = 3;
    [store addTweetWithTweetJsonObject:[JsonGenerator tweetWithTweetID:id userID:id urlCount:urlCount]];
    
#if 1
    NSArray *predicates = @[[NSPredicate predicateWithFormat:@"entities.urls.@count = %@", @(urlCount)]];
#else
    NSArray *predicates = @[[NSPredicate predicateWithFormat:@"entities.urls.@count = %@", @(urlCount)],
                            [NSPredicate predicateWithFormat:@"entities.urls.@count = 3"]];
#endif
    
    for (NSPredicate *predicate in predicates) {
        RLMResults *results = [Tweet objectsInRealm:[store realm] withPredicate:predicate];
        XCTAssertEqual([results count], 1);
        Tweet *tweet = [results firstObject];
        XCTAssertEqual(tweet.id, id);
        XCTAssertEqual(tweet.user.id, id);
        XCTAssertEqual([tweet.entities.urls count], urlCount);
    }
#endif
}

- (void)testToManyWithBEGINSWITH
{
#warning Unsupported (Realm 0.87.1)
#if 0
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    
    for (NSUInteger i = 0; i < 10; i++) {
        [store addTweetWithTweetJsonObject:[JsonGenerator tweetWithTweetID:i userID:i urlCount:0]];
    }
    
    int64_t id = INT64_MAX;
    NSUInteger urlCount = 3;
    [store addTweetWithTweetJsonObject:[JsonGenerator tweetWithTweetID:id userID:id urlCount:urlCount]];
    
#if 1
    NSArray *predicates = @[[NSPredicate predicateWithFormat:@"entities.urls.url BEGINSWITH %@", @"h"]];
#else
    NSArray *predicates = @[[NSPredicate predicateWithFormat:@"entities.urls.url BEGINSWITH %@", @"h"],
                            [NSPredicate predicateWithFormat:@"entities.urls.url BEGINSWITH 'h'"]];
#endif
    for (NSPredicate *predicate in predicates) {
        RLMResults *results = [Tweet objectsInRealm:[store realm] withPredicate:predicate];
        XCTAssertEqual([results count], 1);
        Tweet *tweet = [results firstObject];
        XCTAssertEqual(tweet.id, id);
        XCTAssertEqual(tweet.user.id, id);
        XCTAssertEqual([tweet.entities.urls count], urlCount);
    }
#endif
}

#pragma mark - RLMResults

- (void)testRLMResultsWithEqualBool
{
    RLMRealm *realm = [[TwitterRealmStore sharedStore] realm];
    
    int64_t tweetID = 0;
    int64_t userID = 0;
    NSMutableDictionary *tweetObj = [JsonGenerator tweetWithTweetID:tweetID userID:userID].mutableCopy;
    [tweetObj setObject:@YES forKey:@"retweeted"];
    
    RLMResults *results = [Tweet objectsInRealm:realm where:@"retweeted = 1"];
    XCTAssertEqual([results count], 0);
    NSLog(@"%@", results);
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        [realm addObject:[[Tweet alloc] initWithObject:tweetObj]];
    }];
    
    XCTAssertEqual([[Tweet allObjectsInRealm:realm] count], 1);
    XCTAssertEqual([results count], 1);
}

- (void)testRLMResultsWithEqualInteger
{
    RLMRealm *realm = [[TwitterRealmStore sharedStore] realm];
    NSUInteger count = 10;
    
    RLMResults *results = [Tweet objectsInRealm:realm where:@"id = 5"];
    XCTAssertEqual([results count], 0);
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        for (int64_t i = 0; i < count; i++) {
            [realm addObject:[[Tweet alloc] initWithObject:[JsonGenerator tweetWithTweetID:i userID:i]]];
        }
    }];
    
    XCTAssertEqual([[Tweet allObjectsInRealm:realm] count], count);
    XCTAssertEqual([[User allObjectsInRealm:realm] count], count);
    XCTAssertEqual([results count], 1);
}

- (void)testRLMResultsWithEqualIntegerAndEqualBool
{
    RLMRealm *realm = [[TwitterRealmStore sharedStore] realm];
    NSUInteger count = 10;
    
    RLMResults *results = [Tweet objectsInRealm:realm where:@"id = 5 AND retweeted = 1"];
    XCTAssertEqual([results count], 0);
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        for (int64_t i = 0; i < count; i++) {
            NSMutableDictionary *tweetObj = [JsonGenerator tweetWithTweetID:i userID:i].mutableCopy;
            [tweetObj setObject:@YES forKey:@"retweeted"];
            [realm addObject:[[Tweet alloc] initWithObject:tweetObj]];
        }
    }];
    
    XCTAssertEqual([[Tweet allObjectsInRealm:realm] count], count);
    XCTAssertEqual([[User allObjectsInRealm:realm] count], count);
    XCTAssertEqual([results count], 1);
}

- (void)testRLMResultsWithGreaterThanOrEqual
{
    RLMRealm *realm = [[TwitterRealmStore sharedStore] realm];
    NSUInteger count = 10;
    
    RLMResults *results = [Tweet objectsInRealm:realm where:@"id >= %d", count/2];
    XCTAssertEqual([results count], 0);
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        for (int64_t i = 0; i < count; i++) {
            [realm addObject:[[Tweet alloc] initWithObject:[JsonGenerator tweetWithTweetID:i userID:i]]];
        }
    }];
    
    XCTAssertEqual([[Tweet allObjectsInRealm:realm] count], count);
    XCTAssertEqual([[User allObjectsInRealm:realm] count], count);
    XCTAssertEqual([results count], count/2);
}

- (void)testRLMResultsWithIntegerInObject
{
    RLMRealm *realm = [[TwitterRealmStore sharedStore] realm];
    NSUInteger count = 10;
    
    RLMResults *results = [Tweet objectsInRealm:realm where:@"user.id = 5"];
    XCTAssertEqual([results count], 0);
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        for (int64_t i = 0; i < count; i++) {
            [realm addObject:[[Tweet alloc] initWithObject:[JsonGenerator tweetWithTweetID:i userID:i]]];
        }
    }];
    
    XCTAssertEqual([[Tweet allObjectsInRealm:realm] count], count);
    XCTAssertEqual([[User allObjectsInRealm:realm] count], count);
    XCTAssertEqual([results count], 1);
}

- (void)testRLMResultsWithLessThanIntegerInObject
{
    RLMRealm *realm = [[TwitterRealmStore sharedStore] realm];
    NSUInteger count = 10;
    
    RLMResults *results = [Tweet objectsInRealm:realm where:@"user.id < %d", count/2];
    XCTAssertEqual([results count], 0);
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        for (int64_t i = 0; i < count; i++) {
            [realm addObject:[[Tweet alloc] initWithObject:[JsonGenerator tweetWithTweetID:i userID:i]]];
        }
    }];
    
    XCTAssertEqual([[Tweet allObjectsInRealm:realm] count], count);
    XCTAssertEqual([[User allObjectsInRealm:realm] count], count);
    XCTAssertEqual([results count], count/2);
}

- (void)testRLMResultsWithObject
{
    RLMRealm *realm = [[TwitterRealmStore sharedStore] realm];
    int64_t userID = 5;
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        [realm addObject:[[User alloc] initWithObject:[JsonGenerator userWithID:userID]]];
    }];
    
    User *user = [User objectInRealm:realm forPrimaryKey:@(userID)];
    XCTAssertNotNil(user);
    
    NSUInteger count = 10;
    RLMResults *results = [Tweet objectsInRealm:realm where:@"user = %@", user];
    XCTAssertEqual([results count], 0);
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        for (int64_t i = 0; i < count; i++) {
            [realm addOrUpdateObject:[[Tweet alloc] initWithObject:[JsonGenerator tweetWithTweetID:i userID:i]]];
        }
    }];
    
    XCTAssertEqual([[Tweet allObjectsInRealm:realm] count], count);
    XCTAssertEqual([[User allObjectsInRealm:realm] count], count);
    XCTAssertEqual([results count], 1);
}

- (void)testRLMResultsWithObjects
{
    RLMRealm *realm = [[TwitterRealmStore sharedStore] realm];
    NSUInteger userCount = 5;
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        for (int64_t i = 0; i < userCount; i++) {
            [realm addObject:[[User alloc] initWithObject:[JsonGenerator userWithID:i]]];
        }
    }];
    XCTAssertEqual([[User allObjectsInRealm:realm] count], userCount);
    
    RLMResults *users = [User allObjectsInRealm:realm];
    
    NSUInteger count = 10;
    RLMResults *results = [Tweet objectsInRealm:realm where:@"user IN %@", users];
    XCTAssertEqual([results count], 0);
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        for (int64_t i = 0; i < count; i++) {
            [realm addOrUpdateObject:[[Tweet alloc] initWithObject:[JsonGenerator tweetWithTweetID:i userID:i]]];
        }
    }];
    
    XCTAssertEqual([[Tweet allObjectsInRealm:realm] count], count);
    XCTAssertEqual([[User allObjectsInRealm:realm] count], count);
    XCTAssertEqual([results count], userCount);
}

- (void)testRLMResultsWithANYObject
{
    RLMRealm *realm = [[TwitterRealmStore sharedStore] realm];
    int64_t userID = 5;
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        [realm addObject:[[User alloc] initWithObject:[JsonGenerator userWithID:userID]]];
    }];
    
    User *user = [User objectInRealm:realm forPrimaryKey:@(userID)];
    XCTAssertNotNil(user);
    
    NSUInteger count = 10;
    RLMResults *results = [Tweet objectsInRealm:realm where:@"ANY watchers = %@", user];
    XCTAssertEqual([results count], 0);
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        for (int64_t i = 0; i < count; i++) {
            Tweet *tweet = [[Tweet alloc] initWithObject:[JsonGenerator tweetWithTweetID:i userID:i]];
            if (i == userID) {
                User *user = [User objectInRealm:realm forPrimaryKey:@(userID)];
                XCTAssertNotNil(user);
                [tweet.watchers addObject:user];
            }
            [realm addOrUpdateObject:tweet];
        }
    }];
    
    XCTAssertEqual([[Tweet allObjectsInRealm:realm] count], count);
    XCTAssertEqual([[User allObjectsInRealm:realm] count], count);
    XCTAssertEqual([results count], 1);
}

- (void)testRLMResultsWithANYObjects
{
    RLMRealm *realm = [[TwitterRealmStore sharedStore] realm];
    NSUInteger userCount = 5;
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        for (int64_t i = 0; i < userCount; i++) {
            [realm addObject:[[User alloc] initWithObject:[JsonGenerator userWithID:i]]];
        }
    }];
    XCTAssertEqual([[User allObjectsInRealm:realm] count], userCount);
    
    RLMResults *users = [User allObjectsInRealm:realm];
    
    NSUInteger count = 100;
    RLMResults *results = [Tweet objectsInRealm:realm where:@"ANY watchers IN %@", users];
    XCTAssertEqual([results count], 0);
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        for (int64_t i = 0; i < count; i++) {
            Tweet *tweet = [[Tweet alloc] initWithObject:[JsonGenerator tweetWithTweetID:i userID:i]];
            
            for (int64_t userID = 0; userID < arc4random_uniform(userCount) + 1; userID++) {
                User *user = [User objectInRealm:realm forPrimaryKey:@(userID)];
                XCTAssertNotNil(user);
                [tweet.watchers addObject:user];
            }
            
            [realm addOrUpdateObject:tweet];
        }
    }];
    
    XCTAssertEqual([[Tweet allObjectsInRealm:realm] count], count);
    XCTAssertEqual([[User allObjectsInRealm:realm] count], count);
    XCTAssertEqual([results count], count);
}

- (void)testRLMResultsWithDeleteObject
{
    RLMRealm *realm = [[TwitterRealmStore sharedStore] realm];
    NSUInteger count = 10;
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        for (int64_t i = 0; i < count; i++) {
            [realm addObject:[[Tweet alloc] initWithObject:[JsonGenerator tweetWithTweetID:i userID:i]]];
        }
    }];
    
    RLMResults *results = [Tweet objectsInRealm:realm where:@"user.id >= 0"];
    XCTAssertEqual([results count], count);
    
    [self realmWriteTransaction:^(RLMRealm *realm) {
        [realm deleteObjects:[User allObjectsInRealm:realm]];
    }];
    
    XCTAssertEqual([results count], 0);
}

#pragma mark - Thread

- (void)testRLMObjectCanBeAccessedFromTheOtherThread
{
    Tweet *tweet = [[Tweet alloc] initWithObject:[JsonGenerator tweet]];
    XCTAssertNotNil(tweet);
    
    NSString *text = @"UPDATE TEXT";
    
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssertNotNil(tweet);
        XCTAssertNil(tweet.realm);
        tweet.text = text;
        dispatch_async(dispatch_get_main_queue(), ^{
            [expectation fulfill];
        });
    });
    [self waitForExpectationsWithTimeout:10. handler:^(NSError *error) {
        XCTAssertNil(error, @"error: %@", error);
    }];
    
    XCTAssertEqualObjects(tweet.text, text);
}

- (void)testRLMObjectCanNotBeAccessedFromTheOtherThread
{
    int64_t tweetID = 1;
    NSDictionary *tweetObj = [JsonGenerator tweetWithID:tweetID];
    
    TwitterRealmStore *store = [TwitterRealmStore sharedStore];
    [store addTweetWithTweetJsonObject:tweetObj];
    
    Tweet *tweet = [Tweet objectInRealm:[store realm]
                          forPrimaryKey:@(tweetID)];
    XCTAssertNotNil(tweet);
    
    NSString *text = @"UPDATE TEXT";
    
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            XCTAssertNotNil(tweet.realm);
            tweet.text = text;
        }
        @catch (NSException *exception) {
            DDLogInfo(@"%s; exception = %@;", __func__, exception);
            [expectation fulfill];
        }
        @finally {
        }
    });
    [self waitForExpectationsWithTimeout:5. handler:^(NSError *error) {
        XCTAssertNil(error, @"error: %@", error);
    }];
    
    XCTAssertNotEqualObjects(tweet.text, text);
}

#pragma mark - Test JsonGenerator

- (void)testURLCount
{
    RLMRealm *realm = [[TwitterRealmStore sharedStore] realm];
    
    NSUInteger count = 5;
    [self addOrUpdateTweet:[[Tweet alloc] initWithObject:[JsonGenerator tweetWithTweetID:INT64_MAX
                                                                                  userID:INT64_MAX
                                                                                urlCount:count]]];
    RLMResults *result = [Tweet allObjectsInRealm:realm];
    XCTAssertEqual([result count], 1);
    Tweet *tweet = [result firstObject];
    XCTAssertEqual([tweet.entities.urls count], count);
}

#pragma mark - Utility

- (void)addOrUpdateTweet:(Tweet *)tweet
{
    XCTAssertNotNil(tweet);
    
    RLMRealm *realm = [[TwitterRealmStore sharedStore] realm];
    [realm beginWriteTransaction];
    [realm addOrUpdateObject:tweet];
    [realm commitWriteTransaction];
    
    int64_t twID = tweet.id;
    XCTAssertEqual([Tweet objectInRealm:realm forPrimaryKey:@(twID)].id, tweet.id);
}

- (void)realmWriteTransaction:(void(^)(RLMRealm *realm))transaction
{
    RLMRealm *realm = [[TwitterRealmStore sharedStore] realm];
    [realm beginWriteTransaction];
    if (transaction) transaction(realm);
    [realm commitWriteTransaction];
}

@end
