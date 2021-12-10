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
    NSError *err = nil;
    DVCUser *user = [DVCUser build:&err block:^(DVCUserBuilder *builder) {
        builder.userId = @"my_user";
    }];
    XCTAssertNotNil(user);
    XCTAssertNil(err);
}

- (void)testReturnsErrorIfNoUserIdOrIsAnonymousSet {
    NSError *err = nil;
    DVCUser *user = [DVCUser build:&err block:^(DVCUserBuilder *builder) {}];
    XCTAssertNil(user);
    XCTAssertNotNil(err);
}

- (void)testReturnsErrorIfNoUserIdOrIsAnonymousSetToFalse {
    NSError *err = nil;
    DVCUser *user = [DVCUser build:&err block:^(DVCUserBuilder *builder) {
        builder.isAnonymous = @NO;
    }];
    XCTAssertNil(user);
    XCTAssertNotNil(err);
}


- (void)testNonUserIdPropertiesAreNil {
    NSError *err = nil;
    DVCUser *user = [DVCUser build:&err block:^(DVCUserBuilder *builder) {
        builder.userId = @"my_user";
    }];
    XCTAssertNotNil(user);
    XCTAssert([user.userId isEqual:@"my_user"]);
    XCTAssertFalse([user.isAnonymous boolValue]);
    XCTAssertNil(user.email);
    XCTAssertNil(user.name);
    XCTAssertNil(user.country);
    XCTAssertNil(user.appVersion);
    XCTAssertNil(user.customData);
    XCTAssertNil(user.publicCustomData);
}

- (void)testNonUserIdPropertiesAreNotNil {
    NSError *err = nil;
    DVCUser *user = [DVCUser build:&err block:^(DVCUserBuilder *builder) {
        builder.userId = @"my_user";
        builder.isAnonymous = @NO;
        builder.email = @"email.com";
        builder.name = @"Jason Smith";
        builder.country = @"CAN";
        builder.appVersion = @"1.0.0";
    }];
    XCTAssertNotNil(user);
    XCTAssert([user.userId isEqual:@"my_user"]);
    XCTAssertFalse([user.isAnonymous boolValue]);
    XCTAssertEqual(user.email, @"email.com");
    XCTAssertEqual(user.name, @"Jason Smith");
    XCTAssertEqual(user.country, @"CAN");
    XCTAssertEqual(user.appVersion, @"1.0.0");
}

@end
