//
//  ObjcDVCClientTests.m
//  DevCycleTests
//
//  Created by Jason Salaber on 2021-12-06.
//

#import <XCTest/XCTest.h>
@import DevCycle;

@interface ObjcDVCClientTests : XCTestCase

@end

@implementation ObjcDVCClientTests

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    DVCClient *client = [[[DVCClient builder] environmentKey:@"my_env_key"] build];
    XCTAssertNotNil(client)
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
