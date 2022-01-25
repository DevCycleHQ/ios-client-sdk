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
    DVCClient *client = [DVCClient initialize:@"my_env_key" user:user options:nil onInitialized:^(NSError * _Nullable err) {
        XCTAssertNil(err);
    }];
}

- (void)testAnonUser {
    DVCUser *user = [[DVCUser alloc] init];
    DVCClient *client = [DVCClient initialize:@"my_env_key" user:user options:nil onInitialized:^(NSError * _Nullable err) {
        XCTAssertNil(err);
        XCTAssertTrue(user.isAnonymous);
    }];
}

- (void)testNonUserIdPropertiesAreNil {
    DVCUser *user = [DVCUser initializeWithUserId:@"my_user"];
    DVCClient *client = [DVCClient initialize:@"my_env_key" user:user options:nil onInitialized:^(NSError * _Nullable err) {
        XCTAssertNil(err);
        XCTAssertNotNil(user);
        XCTAssert([user.userId isEqual:@"my_user"]);
        XCTAssertFalse([user.isAnonymous boolValue]);
        XCTAssertNil(user.email);
        XCTAssertNil(user.name);
        XCTAssertNil(user.country);
        XCTAssertNil(user.appVersion);
        XCTAssertNil(user.customData);
        XCTAssertNil(user.privateCustomData);
    }];
}

- (void)testNonUserIdPropertiesAreNotNil {
    DVCUser *user = [DVCUser initializeWithUserId:@"my_user"];
    user.isAnonymous = @NO;
    user.email = @"email.com";
    user.name = @"Jason Smith";
    user.country = @"CAN";
    user.appVersion = @"1.0.0";
    DVCClient *client = [DVCClient initialize:@"my_env_key" user:user options:nil onInitialized:^(NSError * _Nullable err) {
        XCTAssertNil(err);
        XCTAssertNotNil(user);
        XCTAssert([user.userId isEqual:@"my_user"]);
        XCTAssertFalse([user.isAnonymous boolValue]);
        XCTAssertEqual(user.email, @"email.com");
        XCTAssertEqual(user.name, @"Jason Smith");
        XCTAssertEqual(user.country, @"CAN");
        XCTAssertEqual(user.appVersion, @"1.0.0");
    }];
}

@end
