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

- (void)testBuilderReturnsNilIfNoEnvKey {
    DVCUser *user = [[[DVCUser builder] userId:@"my_user"] build];
    DVCClient *client = [[[DVCClient builder] user:user] build];
    XCTAssertNil(client);
}

- (void)testBuilderReturnsNilIfNoUser {
    DVCClient *client = [[[DVCClient builder] environmentKey:@"my_env_key"] build];
    XCTAssertNil(client);
}

@end
