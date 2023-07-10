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
    DVCUser *user = [DVCUser initializeWithUserId:@"my_user"];
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
    DVCUser *user = [DVCUser initializeWithUserId:@"my_user"];
    DevCycleClient *client = [DevCycleClient initialize:@"my_sdk_key" user:user options:nil onInitialized:nil];
    XCTAssertNotNil(client);
}

- (void)testBuilderCreatesClientWithUserAndSDKKeyAndOptions {
    DVCUser *user = [DVCUser initializeWithUserId:@"my_user"];
    DVCOptions *options = [[DVCOptions alloc] init];
    options.logLevel = LogLevel.info;
    options.disableRealtimeUpdates = @true;
    options.configCacheTTL = @86400000;
    
    DevCycleClient *client = [DevCycleClient initialize:@"my_sdk_key" user:user options:options onInitialized:nil];
    XCTAssertNotNil(client);
}

- (void)testDepracatedDVCClientWorks {
    DVCUser *user = [DVCUser initializeWithUserId:@"my_user"];
    DVCClient *client = [DVCClient initialize:@"my_sdk_key" user:user options:nil onInitialized:nil];
    XCTAssertNotNil(client);
}

#pragma mark - Variable Tests

- (void)testVariableIsCreated {
    DVCUser *user = [DVCUser initializeWithUserId:@"my_user"];
    DevCycleClient *client = [DevCycleClient initialize:@"my_sdk_key" user:user options:nil onInitialized:nil];
    XCTAssertNotNil(client);
    DVCVariable *variable = [client stringVariableWithKey:@"my-key" defaultValue:@"default-value"];
    XCTAssertNotNil(variable);
    XCTAssertTrue([variable.type isEqualToString:@"String"]);
    XCTAssertNil(variable.evalReason);
    XCTAssertEqual(variable.value, @"default-value");
    XCTAssertEqual(variable.defaultValue, @"default-value");
}

- (void)testVariableValueIsCreated {
    DVCUser *user = [DVCUser initializeWithUserId:@"my_user"];
    DevCycleClient *client = [DevCycleClient initialize:@"my_sdk_key" user:user options:nil onInitialized:nil];
    XCTAssertNotNil(client);
    NSString *variableValue = [client stringVariableValueWithKey:@"my-key" defaultValue:@"default-value"];
    XCTAssertNotNil(variableValue);
    XCTAssertEqual(variableValue, @"default-value");
}

- (void)testVariableValueBool {
    DVCUser *user = [DVCUser initializeWithUserId:@"my_user"];
    DevCycleClient *client = [DevCycleClient initialize:@"my_sdk_key" user:user options:nil onInitialized:nil];
    XCTAssertNotNil(client);
    BOOL boolValue = [client boolVariableValueWithKey:@"my-key" defaultValue:true];
    XCTAssertTrue(boolValue);
}

@end
