# YSRealmStore
Simple wrapper for [Realm Cocoa](https://github.com/realm/realm-cocoa).

## Features
- Support Realm Cocoa (0.91.5)
- Simple Initialize.
- Async operation.
- Cancel operation.

## Installation
```
pod 'YSRealmStore'
```

## Usage

### Initialize
```
// Default Realm
YSRealmStore *store = [[YSRealmStore alloc] init];

// Other Realm
NSString *custumDatabaseName = @"database";
YSRealmStore *store = [[YSRealmStore alloc] initWithRealmName:custumDatabaseName];

// Encryption Realm
YSRealmStore *store = [[YSRealmStore alloc] initEncryptionWithRealmName:@"encryption-database"];
```

### Write transaction
#### Transaction
```
/* Sync */
[store writeTransactionWithWriteBlock:^(YSRealmWriteTransaction *transaction, RLMRealm *realm) {
    // Can be operated for the realm. (Main thread)
    [realm addOrUpdateObject:[[Tweet alloc] initWithObject:obj]];
}];

/* Async */
[store writeTransactionWithWriteBlock:^(YSRealmWriteTransaction *transaction, RLMRealm *realm) {
    // Can be operated for the realm. (Background thread)
    [realm addOrUpdateObject:[[Tweet alloc] initWithObject:obj]];
} completion:^(YSRealmStore *store, YSRealmWriteTransaction *transaction) {
        
}];
```

#### Cancel
```
YSRealmWriteTransaction *transaction = [store writeTransactionWithWriteBlock:writeBlock
                                                                  completion:completion];
[transaction cancel];
```

### Operation
#### Add
```
/* Sync */
[store writeObjectsWithObjectsBlock:^id(YSRealmOperation *operation, RLMRealm *realm) {
    // Can be operated for the realm. (Main thread)
    return [[Tweet alloc] initWithObject:tweetJsonObj];
}];

/* Async */
[store writeObjectsWithObjectsBlock:^id(YSRealmOperation *operation, RLMRealm *realm) {
    // Can be operated for the realm. (Background thread)
    return [[Tweet alloc] initWithObject:tweetJsonObj];
} completion:^(YSRealmStore *store, YSRealmOperation *operation) {

}];
```

#### Delete
```
/* Sync */
[store deleteObjectsWithObjectsBlock:^id(YSRealmOperation *operation, RLMRealm *realm) {
    // Can be operated for the realm. (Main thread)
    return [Tweet allObjects];
}];

/* Async */
[store deleteObjectsWithObjectsBlock:^id(YSRealmOperation *operation, RLMRealm *realm) {
    // Can be operated for the realm. (Background thread)
    return [Tweet allObjects];
} completion:^(YSRealmStore *store, YSRealmOperation *operation) {

}];
```

#### Fetch
*Fetched object is require primary key.

```
/* Async */
[store fetchObjectsWithObjectsBlock:^id(YSRealmOperation *operation, RLMRealm *realm) {
    // Can be operated for the realm. (Background thread)
    RLMResults *tweets = [Tweet allObjects];
    return [tweets sortedResultsUsingProperty:@"id" ascending:YES];
} completion:^(YSRealmStore *store, YSRealmOperation *operation, RLMRealm *realm, RLMResults *results) {

}];
```

#### Cancel
```
YSRealmOperation *operation = [store writeObjectsWithObjectsBlock:objectsBlock
                                                       completion:completion];

[operation cancel];
```