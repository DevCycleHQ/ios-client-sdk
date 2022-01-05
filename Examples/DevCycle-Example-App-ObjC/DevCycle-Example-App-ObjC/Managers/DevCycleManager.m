//
//  DevCycleManager.m
//  DevCycle-Example-App-ObjC
//
//

#import "DevCycleManager.h"
@import DevCycle;

@implementation DevCycleManager

static NSString *const DEVELOPMENT_KEY = @"client-123fde1a-2e2b-40a7-bfac-10e47d2608f8";

+ (id)sharedManager {
    static DevCycleManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
  if (self = [super init]) {
      self.client = nil;
  }
  return self;
}

- (void)initialize:(DVCUser *)user {
    NSError *err = nil;
    self.client = [DVCClient build:&err block:^(DVCClientBuilder *builder) {
        builder.user = user;
        builder.environmentKey = DEVELOPMENT_KEY;
    } onInitialized:nil];
}


@end
