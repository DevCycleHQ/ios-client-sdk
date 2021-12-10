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
    }];
    XCTAssertNil(client);
    XCTAssertNotNil(err);
}

- (void)testBuilderReturnsErrorIfNoUser {
    NSError *err = nil;
    DVCClient *client = [DVCClient build:&err block:^(DVCClientBuilder *builder) {
        builder.environmentKey = @"my_env_key";
    }];
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
    }];
    XCTAssertNil(err);
    XCTAssertNotNil(client);
}


@end
