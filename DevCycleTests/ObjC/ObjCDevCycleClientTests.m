//
//  ObjcDevCycleClientTests.m
//  DevCycleTests
//
//

#import <XCTest/XCTest.h>
@import DevCycle;

@interface ObjcDevCycleClientTests : XCTestCase

@end

@implementation ObjcDevCycleClientTests

- (void)testBuilderReturnsErrorIfNoSDKKey {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Builder returns error if no sdk key"];
    DevCycleUser *user = [DevCycleUser initializeWithUserId:@"my_user"];
    DevCycleClient *client = [DevCycleClient initialize:nil user:user options:nil onInitialized:^(NSError * _Nullable err) {
        XCTAssertNil(client);
        XCTAssertNotNil(err);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testBuilderReturnsErrorIfNoUser {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Builder returns error if no user"];
    DevCycleClient *client = [DevCycleClient initialize:@"my_sdk_key" user:nil options:nil onInitialized:^(NSError * _Nullable err) {
        XCTAssertNil(client);
        XCTAssertNotNil(err);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testBuilderCreatesClientWithUserAndSDKKey {
    DevCycleUser *user = [DevCycleUser initializeWithUserId:@"my_user"];
    DevCycleClient *client = [DevCycleClient initialize:@"my_sdk_key" user:user options:nil onInitialized:nil];
    XCTAssertNotNil(client);
}

- (void)testBuilderCreatesClientWithUserAndSDKKeyAndOptions {
    DevCycleUser *user = [DevCycleUser initializeWithUserId:@"my_user"];
    DevCycleOptions *options = [[DevCycleOptions alloc] init];
    options.logLevel = LogLevel.info;
    options.disableRealtimeUpdates = @true;
    options.configCacheTTL = @86400000;
    
    DevCycleClient *client = [DevCycleClient initialize:@"my_sdk_key" user:user options:options onInitialized:nil];
    XCTAssertNotNil(client);
}

- (void)testDepracatedDVCClientWorks {
    DevCycleUser *user = [DevCycleUser initializeWithUserId:@"my_user"];
    DVCClient *client = [DVCClient initialize:@"my_sdk_key" user:user options:nil onInitialized:nil];
    XCTAssertNotNil(client);
}

#pragma mark - Variable Tests

- (void)testVariableIsDefaulted {
    DevCycleUser *user = [DevCycleUser initializeWithUserId:@"my_user"];
    DevCycleClient *client = [DevCycleClient initialize:@"my_sdk_key" user:user options:nil onInitialized:nil];
    XCTAssertNotNil(client);
    DVCVariable *variable = [client stringVariableWithKey:@"my-key" defaultValue:@"default-value"];
    XCTAssertNotNil(variable);
    XCTAssertTrue([variable.type isEqualToString:@"String"]);
    XCTAssertEqual(variable.value, @"default-value");
    XCTAssertEqual(variable.defaultValue, @"default-value");

    XCTAssertNotNil(variable.eval);
    XCTAssertTrue([variable.eval.reason isEqualToString:@"DEFAULT"]);
    XCTAssertTrue([variable.eval.details isEqualToString:@"User Not Targeted"]);
    XCTAssertNil(variable.eval.targetId);
}

// TODO: these should all be non-deafulted
- (void)testVariableValueStringDefault {
    DevCycleUser *user = [DevCycleUser initializeWithUserId:@"my_user"];
    DevCycleClient *client = [DevCycleClient initialize:@"my_sdk_key" user:user options:nil onInitialized:nil];
    XCTAssertNotNil(client);
    NSString *variableValue = [client stringVariableValueWithKey:@"my-key" defaultValue:@"default-value"];
    XCTAssertNotNil(variableValue);
    XCTAssertEqual(variableValue, @"default-value");
}

- (void)testVariableValueBoolDefault {
    DevCycleUser *user = [DevCycleUser initializeWithUserId:@"my_user"];
    DevCycleClient *client = [DevCycleClient initialize:@"my_sdk_key" user:user options:nil onInitialized:nil];
    XCTAssertNotNil(client);
    BOOL boolValue = [client boolVariableValueWithKey:@"my-key" defaultValue:true];
    XCTAssertTrue(boolValue);
}

- (void)testVariableValueNumberDefault {
    DevCycleUser *user = [DevCycleUser initializeWithUserId:@"my_user"];
    DevCycleClient *client = [DevCycleClient initialize:@"my_sdk_key" user:user options:nil onInitialized:nil];
    XCTAssertNotNil(client);
    NSNumber *numDefault = @610.1;
    NSNumber *numVal = [client numberVariableValueWithKey:@"my-key" defaultValue:numDefault];
    XCTAssertEqual(numVal, numDefault);
}

- (void)testVariableValueJSONDefault {
    DevCycleUser *user = [DevCycleUser initializeWithUserId:@"my_user"];
    DevCycleClient *client = [DevCycleClient initialize:@"my_sdk_key" user:user options:nil onInitialized:nil];
    XCTAssertNotNil(client);
    NSDictionary *defaultDic = @{@"key": @"value", @"num": @610};
    NSDictionary *jsonVal = [client jsonVariableValueWithKey:@"my-key" defaultValue:defaultDic];
    XCTAssertEqual(jsonVal, defaultDic);
}

@end
