//
//  DevCycleManager.h
//  DevCycle-Example-App-ObjC
//
//

#import <Foundation/Foundation.h>
@import DevCycle;

NS_ASSUME_NONNULL_BEGIN

@interface DevCycleManager : NSObject

@property DVCClient * _Nullable client;

+ (id)sharedManager;
- (void)initialize:(DVCUser *)user;
- (void)initializeUserBuilder:(DVCUserBuilder *)userBuilder;

@end

NS_ASSUME_NONNULL_END
