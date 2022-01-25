//
//  DevCycleManager.m
//  DevCycle-Example-App-ObjC
//
//

#import "DevCycleManager.h"
@import DevCycle;

@interface DevCycleManager()

@property (atomic) DVCClient * _Nullable client;

@end

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

- (DVCClient*)initialize:(DVCUser *)user onInitialized:(void (^_Nullable)(NSError*))onInitialized {
    NSError *err = nil;
    
    DVCOptions *options = [[DVCOptions alloc] init];
    options.logLevel = LogLevel.debug;
    
    self.client = [DVCClient initialize:DEVELOPMENT_KEY
                                   user:user
                                options:options
                                    err:&err
                          onInitialized:onInitialized];
    if (err) {
        NSLog(@"Error Starting DevCycle: %@", err);
    }
    
    return self.client;
}

@end
