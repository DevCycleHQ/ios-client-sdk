//
//  ObjcDVCUserTests.m
//  DevCycleTests
//
//

#import <XCTest/XCTest.h>
@import DevCycle;

@interface ObjcDVCUserTests : XCTestCase

@end

@implementation ObjcDVCUserTests

- (void)testCreateUser {
    DVCUser *user = [[[DVCUser builder] userId:@"my_user"] build];
    XCTAssertNotNil(user);
}

- (void)testUserIsNil {
    DVCUser *user = [[DVCUser builder] build];
    XCTAssertNil(user);
}


- (void)testNonUserIdPropertiesAreNil {
    DVCUser *user = [[[DVCUser builder] userId:@"my_user"] build];
    XCTAssertNotNil(user);
    XCTAssert([user.properties[@"user_id"] isEqual:@"my_user"]);
    XCTAssertFalse([user.properties[@"isAnonymous"] boolValue]);
    XCTAssertNil(user.properties[@"email"]);
    XCTAssertNil(user.properties[@"name"]);
    XCTAssertNil(user.properties[@"country"]);
    XCTAssertNil(user.properties[@"appVersion"]);
    XCTAssertNil(user.properties[@"customData"]);
    XCTAssertNil(user.properties[@"publicCustomData"]);
}

@end
