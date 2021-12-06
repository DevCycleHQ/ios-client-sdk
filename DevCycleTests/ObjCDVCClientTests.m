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
    DVCClient *client = [[DVCClient builder] build];
    XCTAssertNil(client);
}

- (void)testBuilderReturnsNilIfNoUser {
    DVCClient *client = [[[DVCClient builder] environmentKey:@"my_env_key"] build];
    XCTAssertNil(client);
}

@end
