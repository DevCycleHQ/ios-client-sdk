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
    NSError *err = nil;
    DVCUser *user = [DVCUser build:&err block:^(DVCUserBuilder *builder) {
        builder.userId = @"my_user";
    }];
    
    DVCClient *client = [DVCClient build:&err block:^(DVCClientBuilder *builder) {
        builder.user = user;
    } onInitialized:nil];
    XCTAssertNil(client);
    XCTAssertNotNil(err);
}

- (void)testBuilderReturnsErrorIfNoUser {
    NSError *err = nil;
    DVCClient *client = [DVCClient build:&err block:^(DVCClientBuilder *builder) {
        builder.environmentKey = @"my_env_key";
    } onInitialized:nil];
    XCTAssertNil(client);
    XCTAssertNotNil(err);
}

- (void)testBuilderCreatesClientWithUserAndEnvKey {
    NSError *err = nil;
    DVCUser *user = [DVCUser build:&err block:^(DVCUserBuilder *builder) {
        builder.userId = @"my_user";
    }];
    DVCClient *client = [DVCClient build:&err block:^(DVCClientBuilder *builder) {
        builder.environmentKey = @"my_env_key";
        builder.user = user;
    } onInitialized:nil];
    XCTAssertNil(err);
    XCTAssertNotNil(client);
}

#pragma mark - Variable Tests

- (void)testVariableIsCreated {
    NSError *err = nil;
    DVCUser *user = [DVCUser build:&err block:^(DVCUserBuilder *builder) {
        builder.userId = @"my_user";
    }];
    DVCClient *client = [DVCClient build:&err block:^(DVCClientBuilder *builder) {
        builder.environmentKey = @"my_env_key";
        builder.user = user;
    } onInitialized:nil];
    DVCVariable *variable = [client variableWithKey:@"my-key" defaultValue:@"default-value" error:&err];
    XCTAssertNil(err);
    XCTAssertNotNil(variable);
    XCTAssertNil(variable.type);
    XCTAssertNil(variable.evalReason);
    XCTAssertEqual(variable.value, @"default-value");
    XCTAssertEqual(variable.defaultValue, @"default-value");
}

@end
