# DevCycle iOS Client SDK

[![CocoaPods compatible](https://img.shields.io/cocoapods/v/DevCycle.svg)](https://cocoapods.org/pods/DevCycle)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/)


The DevCycle iOS Client SDK. This SDK uses our Client SDK APIs to perform all user segmentation 
and bucketing for the SDK, providing fast response times using our globally distributed edge workers 
all around the world.

## Requirements

This version of the DevCycle iOS Client SDK supports a minimum of iOS 12.

## Installation

### CocoaPods

The SDK can be installed into your iOS project by adding the following to your cocoapod spec:

```swift
pod 'DevCycle'
```

### Carthage

Include the following in your `Cartfile`: 

```swift
github "DevCycleHQ/ios-client-sdk"
```

### Swift Package Manager

To use the library with Swift Package Manager, include it as a dependency in your `Package.swift` file like so:

```
...
    dependencies: [
        .package(url: "https://github.com/DevCycleHQ/ios-client-sdk.git", .upToNextMinor("1.2.0")),
    ],
    targets: [
        .target(
            name: "YOUR_TARGET",
            dependencies: ["DevCycle"]
        )
    ],
...
```

You can also add it through Xcode, i.e. `File > Swift Packages > Add Package Dependency`, then enter the repository clone URL.

## Usage

### Initializing the SDK

#### Swift
Using the builder pattern we can initialize the DevCycle SDK by providing the DVCUser and DevCycle mobile environment key:

```swift
let user = try DVCUser.builder()
                    .userId("my-user1")
                    .build()

guard let dvcClient = try DVCClient.builder()
        .environmentKey("<DEVCYCLE_MOBILE_ENVIRONMENT_KEY>")
        .user(user)
        .build(onInitialized: nil)
```

The user object needs either a `user_id`, or `isAnonymous` set to `true` for an anonymous user. 

#### Objective-C
For Objective-C we use a standard callback pattern to initialize the DevCycle SDK by providing the DVCUser and DevCycle mobile environment key:

```objc
DVCUser *user = [DVCUser initializeWithUserId:@"my-user1"];


self.dvcClient = [DVCClient initialize:@"<DEVCYCLE_MOBILE_ENVIRONMENT_KEY>"
                               user:user
                            options:nil
                      onInitialized:^(NSError * _Nullable error) {
    if (error) {
        NSLog(@"DevCycle failed to initialize: %@", error);
    }
}];
```

### Notifying when DevCycle features are available

In the initialize call there is an optional `onInitialized` parameter you can use to determine when your features have been loaded:

#### Swift

```swift
self.dvcClient = try? DVCClient.builder()
        .environmentKey("<DEVCYCLE_MOBILE_ENVIRONMENT_KEY>")
        .user(user)
        .options(options)
        .build(onInitialized: { error in
            if (error != nil) {
                // there was an error with building the client
            } else {
                // initialized successfully
            }
        })
```

#### Objective-C

```objc
self.dvcClient = [DVCClient initialize:@"<DEVCYCLE_MOBILE_ENVIRONMENT_KEY>"
                               user:user
                            options:nil
                      onInitialized:^(NSError * _Nullable error) {
    if (error) {
        NSLog(@"DevCycle failed to initialize: %@", error);
    } else {
        // initialized successfully
    }
}];
```

## Using Variable Values

To get values from your Features, the `variable()` method is used to fetch variable values using 
the variable's identifier `key` coupled with a default value. The default value can be of type 
string, boolean, number, or JSONObject:

#### Swift
```swift
let boolVariable = dvcClient.variable(key: "bool_key", defaultValue: false)
let strVariable = dvcClient.variable(key: "string_key", defaultValue: "default")
let numVariable = dvcClient.variable(key: "num_key", defaultValue: 4)
let jsonVariable = dvcClient.variable(key: "json_key", defaultValue: [:])
```

#### Objective-C
```objc
DVCVariable *boolVariable = [self.dvcClient boolVariableWithKey:@"bool_key" defaultValue:false];
DVCVariable *strVariable = [self.dvcClient stringVariableWithKey:@"string_key" defaultValue:@"default"];
DVCVariable *numVariable = [self.dvcClient numberVariableWithKey:@"num_key" defaultValue:@4];
DVCVariable *jsonVariable = [self.dvcClient jsonVariableWithKey:@"json_key" defaultValue:@{}];
```

To grab the value, there is a property on the object returned to grab the value:

#### Swift
```swift
if (boolVariable.value == true) {
    // Run Feature Flag Code
} else {
    // Run Default Code
}
```

#### Objective-C
```objc
if (boolVariable.value == true) {
    // Run Feature Flag Code
} else {
    // Run Default Code
}
```

To listen for updates on the variable's `value`, for example when the user's `userId` is changed or `resetUser()` is called, an `onUpdate()` handler can be used:

#### Swift
```swift
let boolVariable = dvcClient.variable(key: "bool_key", defaultValue: false)
                        .onUpdate { value in
    // Variable value updated
}
```

#### Objective-C
```objc
DVCVariable *boolVar = [[self.dvcClient boolVariableWithKey:@"bool_key" defaultValue:true]
                        onUpdateWithHandler:^(id _Nonnull value) {
    // Variable value updated
}];
```

The `Variable` object also contains the following params: 
    - `key`: the key indentifier for the Variable
    - `type`: the type of the Variable, one of: `String` / `Boolean` / `Number` / `JSON`
    - `value`: the Variable's value
    - `defaultValue`: the Variable's default value
    - `isDefaulted`: if the Variable is using the `defaultValue`
    - `evalReason`: evaluation reason for why the variable was bucketed into its value

If the value is not ready, it will return the default value passed in the creation of the variable.

## Grabbing All Features / Variables

To grab all the Features or Variables returned in the config:

#### Swift
```swift
let features: [String: Feature] = dvcClient.allFeatures()
let variables: [String: Variable] = dvcClient.allVariables()
```

#### Objective-C
```objc
NSDictionary *allFeatures = [self.dvcClient allFeatures];
NSDictionary *allVariables = [self.dvcClient allVariables];
```

If the SDK has not finished initializing, these methods will return an empty object.

## Identifying User

To identify a different user, or the same user passed into the initialize method with more attributes, 
build a DVCUser object and pass it into `identifyUser`:

#### Swift
```swift
do {
    let user = try DVCUser.builder()
                        .userId("my-user1")
                        .email("my-email@email.com")
                        .country("CA")
                        .name("My Name")
                        .language("EN")
                        .customData([ "customkey": "customValue" ])
                        .privateCustomData([ "customkey2": "customValue2" ])
                        .build()
    try dvcClient.identifyUser(user: user)
} catch {
    print("Error building new DVCUser: \(error)")
}
```

#### Objective-C
```objc
DVCUser *user = [DVCUser initializeWithUserId:@"my-user1"];
user.email = @"my-email@email.com";
user.appBuild = @1005;
user.appVersion = @"1.1.1";
user.country = @"CA";
user.name = @"My Name";
user.language = @"EN";
user.customData = @{@"customKey": @"customValue"};
user.privateCustomData = @{@"customkey2": @"customValue2"};

[self.dvcClient identifyUser:user callback:^(NSError *error, NSDictionary<NSString *,id> *variables) {
    if (error) {
        return NSLog(@"Error calling DVCClient identifyUser:callback: %@", error);
    }
}];
```

To wait on Variables that will be returned from the identify call, you can pass in a DVCCallback:

#### Swift
```swift
try dvcClient.identifyUser(user: user) { error, variables in
    if (error != nil) {
        // error identifying user
    } else {
        // use variables 
    }
}
```

#### Objective-C
```objc
[self.dvcClient identifyUser:user callback:^(NSError *error, NSDictionary<NSString *,id> *variables) {
    if (error) {
        // error identifying user
    } else {
        // use variables 
    }
}];
```

If `error` exists the called the user's configuration will not be updated and previous user's data will persist.

## Reset User

To reset the user into an anonymous user, `resetUser` will reset to the anonymous user created before 
or will create one with an anonymous `user_id`.

#### Swift
```swift
try dvcClient.resetUser()
```

#### Objective-C
```objc
[self.dvcClient resetUser:nil];
```

To wait on the Features of the anonymous user, you can pass in a DVCCallback:

#### Swift
```swift
try dvcClient.resetUser { error, variables in
    // anonymous user
}
```

#### Objective-C
```objc
[self.dvcClient resetUser:^(NSError *error, NSDictionary<NSString *,id> *variables) {
    if (error) {
        // Error resetting user, existing user used
    } else {
        // anonymous user
    }
}];
```


If `error` exists is called the user's configuration will not be updated and previous user's data will persist.

## Tracking Events

To track events, pass in an object with at least a `type` key:

#### Swift
```swift
let event = try DVCEvent.builder()
                        .type("my_event")
                        .target("my_target")
                        .value(3)
                        .metaData([ "key": "value" ])
                        .clientDate(Date())
                        .build()
dvcClient.track(event)
```

#### Objective-C
```objc
NSError *err = nil;
DVCEvent *event = [DVCEvent initializeWithType:@"my-event"];
[self.dvcClient track:event err:&err];
if (err) {
    NSLog(@"Error calling DVCClient track:err: %@", err);
}
```

The SDK will flush events every 10s or `flushEventsMS` specified in the options. To manually flush events, call:

#### Swift
```swift
dvcClient.flushEvents()
```

#### Objective-C
```objc
[self.dvcClient flushEvents];
```