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

- (void)testStringVariableGetsCreatedWithDefault {
    DevCycleUser *user = [DevCycleUser initializeWithUserId:@"my_user"];
    DevCycleClient *client = [DevCycleClient initialize:@"key" user:user];
    DVCVariable *variable = [client stringVariableWithKey:@"my-key" defaultValue:@"my-default"];
    XCTAssertNotNil(variable);
    XCTAssertEqual(variable.value, @"my-default");
    XCTAssertEqual(variable.defaultValue, @"my-default");
    XCTAssertTrue(variable.isDefaulted);
}

- (void)testBoolVariableGetsCreatedWithDefault {
    DevCycleUser *user = [DevCycleUser initializeWithUserId:@"my_user"];
    DevCycleClient *client = [DevCycleClient initialize:@"key" user:user];
    DVCVariable *variable = [client boolVariableWithKey:@"my-key" defaultValue:false];
    XCTAssertNotNil(variable);
    NSNumber *boolValue = variable.value;
    XCTAssertEqual(boolValue.boolValue, false);
    NSNumber *defaultBoolValue = variable.defaultValue;
    XCTAssertEqual(defaultBoolValue.boolValue, false);
    XCTAssertTrue(variable.isDefaulted);
    
    bool varValue = [client boolVariableValueWithKey:@"my-key" defaultValue:false];
    XCTAssertFalse(varValue);
}

- (void)testNumberVariableGetsCreatedWithDefault {
    DevCycleUser *user = [DevCycleUser initializeWithUserId:@"my_user"];
    DevCycleClient *client = [DevCycleClient initialize:@"key" user:user];
    NSNumber* defaultNum = @610.1;
    DVCVariable *variable = [client numberVariableWithKey:@"my-key" defaultValue:defaultNum];
    XCTAssertNotNil(variable);
    XCTAssert([variable.value isEqual:defaultNum]);
    XCTAssert([variable.defaultValue isEqual:defaultNum]);
    XCTAssertTrue(variable.isDefaulted);
}

- (void)testJSONVariableGetsCreatedWithDefault {
    DevCycleUser *user = [DevCycleUser initializeWithUserId:@"my_user"];
    DevCycleClient *client = [DevCycleClient initialize:@"key" user:user];
    NSDictionary *defaultDic = @{@"key": @"value", @"num": @610};
    DVCVariable *variable = [client jsonVariableWithKey:@"my-key" defaultValue:defaultDic];
    XCTAssertNotNil(variable);
    XCTAssertEqual(variable.value, defaultDic);
    XCTAssertEqual(variable.defaultValue, defaultDic);
    XCTAssertTrue(variable.isDefaulted);
}

@end
