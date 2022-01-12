# DevCycle iOS Client SDK

The DevCycle iOS Client SDK. This SDK uses our Client SDK APIs to perform all user segmentation 
and bucketing for the SDK, providing fast response times using our globally distributed edge workers 
all around the world.

## Requirements

This version of the DevCycle iOS Client SDK supports a minimum of iOS 12.

## Installation

The SDK can be installed into your iOS project by adding the following to your cocoapod spec:

```swift
    pod 'DevCycle'
```

## Usage

### Initializing the SDK

Using the builder pattern we can initialize the DevCycle SDK by providing the DVCUser and DevCycle mobile environment key:

```swift
let user = try DVCUser.builder()
                    .userId("my-user1")
                    .build()

guard let client = try DVCClient.builder()
        .environmentKey("<DEVCYCLE_MOBILE_ENVIRONMENT_KEY>")
        .user(user)
        .build(onInitialized: nil)
```

The user object needs either a `user_id`, or `isAnonymous` set to `true` for an anonymous user. 

## Using Variable Values

To get values from your Features, the `variable()` method is used to fetch variable values using 
the variable's identifier `key` coupled with a default value. The default value can be of type 
string, boolean, number, or JSONObject:

```swift
let strVariable: DVCVariable<String> = client.variable(key: "str_key", defaultValue: "default")
let boolVariable: DVCVariable<Bool> = client.variable(key: "bool_key", defaultValue: false)
let numVariable: DVCVariable<Int> = client.variable(key: "num_key", defaultValue: 4)
let jsonVariable: DVCVariable<[String:Any]> = client.variable(key: "json_key", defaultValue: [:])
```

To grab the value, there is a property on the object returned to grab the value:

```swift
if (boolVariable.value == true) {
    // Run Feature Flag Code
} else {
    // Run Default Code
}
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

```swift
let features: [String: Feature] = client.allFeatures()
let variables: [String: Variable] = client.allVariables()
```

If the SDK has not finished initializing, these methods will return an empty object.

## Identifying User

To identify a different user, or the same user passed into the initialize method with more attributes, 
build a DVCUser object and pass it into `identifyUser`:

```swift
let user = try DVCUser.builder()
                    .userId("my-user1")
                    .email("my-email@email.com")
                    .appBuild(1005)
                    .appVersion("1.1.1")
                    .country("CA")
                    .name("My Name")
                    .language("EN")
                    .customData([
                        "customkey": "customValue"
                    ])
                    .privateCustomData([
                        "customkey2": "customValue2"
                    ])
                    .build()
client.identifyUser(user)
```

To wait on Variables that will be returned from the identify call, you can pass in a DVCCallback:

```swift
try client.identifyUser(user) { error, variables in
    if (error != nil) {
        // error identifying user
    } else {
        // use variables 
    }
}
```

If `error` exists the called the user's configuration will not be updated and previous user's data will persist.

## Reset User

To reset the user into an anonymous user, `resetUser` will reset to the anonymous user created before 
or will create one with an anonymous `user_id`.

```swift
client.resetUser()
```

To wait on the Features of the anonymous user, you can pass in a DVCCallback:

```swift
try client.resetUser { error, variables in
    // anonymous user
}
```

If `error` exists is called the user's configuration will not be updated and previous user's data will persist.

## Tracking Events

To track events, pass in an object with at least a `type` key:

```swift
let event = try DVCEvent.builder()
                        .type("my_event")
                        .target("my_target")
                        .value(3)
                        .metaData([ "key": "value" ])
                        .clientDate(Date())
                        .build()
client.track(event)
```

The SDK will flush events every 10s or `flushEventsMS` specified in the options. To manually flush events, call:

```swift
client.flushEvents()
```