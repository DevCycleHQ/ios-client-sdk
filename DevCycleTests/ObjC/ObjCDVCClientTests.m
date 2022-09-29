//
//  ObjcDVCClientTests.m
//  DevCycleTests
//
//

#import <XCTest/XCTest.h>
@import DevCycle;

@interface ObjcDVCClientTests : XCTestCase

@end

@implementation ObjcDVCClientTests

- (void)testBuilderReturnsErrorIfNoEnvKey {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Builder returns error if no env key"];
    DVCUser *user = [DVCUser initializeWithUserId:@"my_user"];
    DVCClient *client = [DVCClient initialize:nil user:user options:nil onInitialized:^(NSError * _Nullable err) {
        XCTAssertNil(client);
        XCTAssertNotNil(err);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testBuilderReturnsErrorIfNoUser {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Builder returns error if no user"];
    DVCClient *client = [DVCClient initialize:@"my_env_key" user:nil options:nil onInitialized:^(NSError * _Nullable err) {
        XCTAssertNil(client);
        XCTAssertNotNil(err);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testBuilderCreatesClientWithUserAndEnvKey {
    DVCUser *user = [DVCUser initializeWithUserId:@"my_user"];
    DVCClient *client = [DVCClient initialize:@"my_env_key" user:user options:nil onInitialized:nil];
    XCTAssertNotNil(client);
}

#pragma mark - Variable Tests

- (void)testVariableIsCreated {
    DVCUser *user = [DVCUser initializeWithUserId:@"my_user"];
    DVCClient *client = [DVCClient initialize:@"my_env_key" user:user options:nil onInitialized:nil];
    XCTAssertNotNil(client);
    DVCVariable *variable = [client stringVariableWithKey:@"my-key" defaultValue:@"default-value"];
    XCTAssertNotNil(variable);
    XCTAssertTrue([variable.type isEqualToString:@"String"]);
    XCTAssertNil(variable.evalReason);
    XCTAssertEqual(variable.value, @"default-value");
    XCTAssertEqual(variable.defaultValue, @"default-value");
}

@end
