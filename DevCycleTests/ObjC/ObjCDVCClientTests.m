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
    DVCUser *user = [DVCUser initializeWithUserId:@"my_user"];
    DVCClient *client = [DVCClient initialize:nil user:user options:nil onInitialized:^(NSError * _Nullable err) {
        XCTAssertNil(client);
        XCTAssertNotNil(err);
    }];
}

- (void)testBuilderReturnsErrorIfNoUser {
    DVCClient *client = [DVCClient initialize:@"my_env_key" user:nil options:nil onInitialized:^(NSError * _Nullable err) {
        XCTAssertNil(client);
        XCTAssertNotNil(err);
    }];
}

- (void)testBuilderCreatesClientWithUserAndEnvKey {
    DVCUser *user = [DVCUser initializeWithUserId:@"my_user"];
    DVCClient *client = [DVCClient initialize:@"my_env_key" user:user options:nil onInitialized:^(NSError * _Nullable err) {
        XCTAssertNil(err);
        XCTAssertNotNil(client);
    }];
}

#pragma mark - Variable Tests

- (void)testVariableIsCreated {
    DVCUser *user = [DVCUser initializeWithUserId:@"my_user"];
    DVCClient *client = [DVCClient initialize:@"my_env_key" user:user options:nil onInitialized:^(NSError * _Nullable err) {
        XCTAssertNil(err);
        XCTAssertNotNil(client);
        
        DVCVariable *variable = [client stringVariableWithKey:@"my-key" defaultValue:@"default-value"];
        XCTAssertNotNil(variable);
        XCTAssertNil(variable.type);
        XCTAssertNil(variable.evalReason);
        XCTAssertEqual(variable.value, @"default-value");
        XCTAssertEqual(variable.defaultValue, @"default-value");
    }];
}

@end
