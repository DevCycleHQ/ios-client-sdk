//
//  ObjcDVCVariableTests.m
//  DevCycleTests
//
//  Copyright © 2021 Taplytics. All rights reserved.
//

#import <XCTest/XCTest.h>
@import DevCycle;

@interface ObjcDVCVariableTests : XCTestCase

@end

@implementation ObjcDVCVariableTests

- (void)testVariableGetsCreatedWithDefault {
    NSError *err = nil;
    DVCUser *user = [DVCUser initializeWithUserId:@"my_user"];
    DVCClient *client = [DVCClient initialize:@"key" user:user err:&err];
    DVCVariable *variable = [client stringVariableWithKey:@"my-key" defaultValue:@"my-default"];
    XCTAssertNil(err);
    XCTAssertNotNil(variable);
    XCTAssertEqual(variable.value, @"my-default");
    XCTAssertEqual(variable.defaultValue, @"my-default");
    XCTAssertNil(variable.evalReason);
}

@end
