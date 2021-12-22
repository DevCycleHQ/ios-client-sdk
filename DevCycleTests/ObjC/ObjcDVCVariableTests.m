//
//  ObjcDVCVariableTests.m
//  DevCycleTests
//
//  Created by Jason Salaber on 2021-12-22.
//  Copyright © 2021 Taplytics. All rights reserved.
//

#import <XCTest/XCTest.h>
@import DevCycle;

@interface ObjcDVCVariableTests : XCTestCase

@end

@implementation ObjcDVCVariableTests

- (void)testVariableGetsCreated {
    NSError *err = nil;
    DVCVariable *variable = [[DVCVariable alloc] initWithKey:@"my-key" type:@"String" evalReason:nil value:@"my-value" defaultValue:@"my-default" error:&err];
    XCTAssertNil(err);
    XCTAssertNotNil(variable);
    XCTAssertEqual(variable.value, @"my-value");
    XCTAssertEqual(variable.defaultValue, @"my-default");
    XCTAssertNil(variable.evalReason);
}

- (void)testVariableThrowsErrorIfValueTypeDoesntMatchDefault {
    NSError *err = nil;
    DVCVariable *variable = [[DVCVariable alloc] initWithKey:@"my-key" type:@"String" evalReason:nil value:@5 defaultValue:@"my-default" error:&err];
    XCTAssertNotNil(err);
    XCTAssertNil(variable);
}

@end
