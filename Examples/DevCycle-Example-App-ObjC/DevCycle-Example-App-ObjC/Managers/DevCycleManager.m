//
//  DevCycleManager.m
//  DevCycle-Example-App-ObjC
//
//

#import "DevCycleManager.h"
@import DevCycle;

@implementation DevCycleManager

static NSString *const DEVELOPMENT_KEY = @"mobile-16e8e500-80d2-4bb5-9d4f-8219381a90da";

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
    DVCOptions *options = [DVCOptions build:&err block:^(DVCOptionsBuilder *builder) {
        builder.logLevel = LogLevel.debug;
    }];
    self.client = [DVCClient build:&err block:^(DVCClientBuilder *builder) {
        builder.user = user;
        builder.environmentKey = DEVELOPMENT_KEY;
        builder.options = options;
    } onInitialized:nil];
}


@end
