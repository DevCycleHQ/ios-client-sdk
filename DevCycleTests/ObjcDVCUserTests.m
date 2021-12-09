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
    DVCUser *user = [DVCUser build:^(DVCUserBuilder *builder) {
        builder.userId = @"my_user";
    }];
    XCTAssertNotNil(user);
}

- (void)testUserIsNil {
    DVCUser *user = [DVCUser build:^(DVCUserBuilder *builder) {}];
    NSDictionary *dic = user.properties;
    XCTAssert(dic.count == 0);
}


- (void)testNonUserIdPropertiesAreNil {
    DVCUser *user = [DVCUser build:^(DVCUserBuilder *builder) {
        builder.userId = @"my_user";
    }];
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

- (void)testNonUserIdPropertiesAreNotNil {
    DVCUser *user = [DVCUser build:^(DVCUserBuilder *builder) {
        builder.userId = @"my_user";
        builder.isAnonymous = @NO;
        builder.email = @"email.com";
        builder.name = @"Jason Smith";
        builder.country = @"CAN";
        builder.appVersion = @"1.0.0";
    }];
    XCTAssertNotNil(user);
    XCTAssert([user.properties[@"user_id"] isEqual:@"my_user"]);
    XCTAssertFalse([user.properties[@"isAnonymous"] boolValue]);
    XCTAssertEqual(user.properties[@"email"], @"email.com");
    XCTAssertEqual(user.properties[@"name"], @"Jason Smith");
    XCTAssertEqual(user.properties[@"country"], @"CAN");
    XCTAssertEqual(user.properties[@"appVersion"], @"1.0.0");
}

@end
