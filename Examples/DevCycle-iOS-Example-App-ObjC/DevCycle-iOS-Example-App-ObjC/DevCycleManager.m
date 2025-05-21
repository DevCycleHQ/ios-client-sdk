//
//  DevCycleManager.m
//  DevCycle-Example-App-ObjC
//
//

#import "DevCycleManager.h"
@import DevCycle;

@interface DevCycleManager()

@property (atomic) DevCycleClient* _Nullable client;

@end

@implementation DevCycleManager

static NSString *const DEVCYCLE_KEY = @"<DEVCYCLE_MOBILE_SDK_KEY>";

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

- (DevCycleClient*)initialize:(DevCycleUser *)user onInitialized:(void (^_Nullable)(NSError*))onInitialized {
    NSError *err = nil;
    
    DevCycleOptions *options = [[DevCycleOptions alloc] init];
//    options.logLevel = LogLevel.debug;
    
    self.client = [DevCycleClient initialize:DEVCYCLE_KEY
                                   user:user
                                options:options
                          onInitialized:onInitialized];
    if (err) {
        NSLog(@"Error Starting DevCycle: %@", err);
    }
    
    return self.client;
}

@end
