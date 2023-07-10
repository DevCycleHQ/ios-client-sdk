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
    DVCUser *user = [DVCUser initializeWithUserId:@"my_user"];
    DevCycleClient *client = [DevCycleClient initialize:@"my_sdk_key" user:user options:nil onInitialized:nil];
    XCTAssertNotNil(user);
    XCTAssertNotNil(client);
}

- (void)testAnonUser {
    DVCUser *user = [[DVCUser alloc] init];
    DevCycleClient *client = [DevCycleClient initialize:@"my_sdk_key" user:user options:nil onInitialized:nil];
    XCTAssertNotNil(user);
    XCTAssertTrue(user.isAnonymous);
}

- (void)testNonUserIdPropertiesAreNil {
    DVCUser *user = [DVCUser initializeWithUserId:@"my_user"];
    DevCycleClient *client = [DevCycleClient initialize:@"my_sdk_key" user:user options:nil onInitialized:nil];
    XCTAssertNotNil(user);
    XCTAssert([user.userId isEqual:@"my_user"]);
    XCTAssertFalse([user.isAnonymous boolValue]);
    XCTAssertNil(user.email);
    XCTAssertNil(user.name);
    XCTAssertNil(user.country);
    XCTAssertNil(user.customData);
    XCTAssertNil(user.privateCustomData);
}

- (void)testNonUserIdPropertiesAreNotNil {
    DVCUser *user = [DVCUser initializeWithUserId:@"my_user"];
    user.isAnonymous = @NO;
    user.email = @"email.com";
    user.name = @"Jason Smith";
    user.country = @"CAN";
    DevCycleClient *client = [DevCycleClient initialize:@"my_sdk_key" user:user options:nil onInitialized:nil];
    XCTAssertNotNil(user);
    XCTAssert([user.userId isEqual:@"my_user"]);
    XCTAssertFalse([user.isAnonymous boolValue]);
    XCTAssertEqual(user.email, @"email.com");
    XCTAssertEqual(user.name, @"Jason Smith");
    XCTAssertEqual(user.country, @"CAN");
}

@end
