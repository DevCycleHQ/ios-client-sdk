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

- (void)testBuilderReturnsErrorIfNoEnvKey {
    NSError *err = nil;
    DVCUser *user = [DVCUser build:&err block:^(DVCUserBuilder *builder) {
        builder.userId = @"my_user";
    }];
    
    DVCClient *client = [DVCClient build:&err block:^(DVCClientBuilder *builder) {
        builder.user = user;
    } onInitialized: nil];
    XCTAssertNil(client);
    XCTAssertNotNil(err);
}

- (void)testBuilderReturnsErrorIfNoUser {
    NSError *err = nil;
    DVCClient *client = [DVCClient build:&err block:^(DVCClientBuilder *builder) {
        builder.environmentKey = @"my_env_key";
    } onInitialized: nil];
    XCTAssertNil(client);
    XCTAssertNotNil(err);
}

- (void)testBuilderCreatesClientWithUserAndEnvKey {
    NSError *err = nil;
    DVCUser *user = [DVCUser build:&err block:^(DVCUserBuilder *builder) {
        builder.userId = @"my_user";
    }];
    DVCClient *client = [DVCClient build:&err block:^(DVCClientBuilder *builder) {
        builder.environmentKey = @"my_env_key";
        builder.user = user;
    } onInitialized: nil];
    XCTAssertNil(err);
    XCTAssertNotNil(client);
}

- (void)testTrackWithValidDVCEventNoOptionals {
    NSError *err = nil;
    DVCUser *user = [DVCUser build:&err block:^(DVCUserBuilder *builder) {
        builder.userId = @"my_user";
    }];
    DVCClient *client = [DVCClient build:&err block:^(DVCClientBuilder *builder) {
        builder.environmentKey = @"my_env_key";
        builder.user = user;
    } onInitialized: nil];
    DVCEvent *event = [[DVCEvent alloc] initWithType:@"test" target:nil date:nil value:nil metaData:nil];
    
    [client track:event];
    XCTAssertTrue(client.eventQueue.count == 1);
}

- (void)testTrackWithValidDVCEventWithAllParamsDefined {
    NSError *err = nil;
    DVCUser *user = [DVCUser build:&err block:^(DVCUserBuilder *builder) {
        builder.userId = @"my_user";
    }];
    DVCClient *client = [DVCClient build:&err block:^(DVCClientBuilder *builder) {
        builder.environmentKey = @"my_env_key";
        builder.user = user;
    } onInitialized: nil];
    NSDate *testDate = [NSDate date];
    NSDictionary<NSString *, id> *testMetaData = @{ @"test1": @"key", @"test2": @2, @"test3": @false };
    DVCEvent *event = [[DVCEvent alloc] initWithType:@"test" target:@"test" date:testDate value:@1 metaData:testMetaData];
    
    [client track:event];
    XCTAssertTrue(client.eventQueue.count == 1);
}

@end
