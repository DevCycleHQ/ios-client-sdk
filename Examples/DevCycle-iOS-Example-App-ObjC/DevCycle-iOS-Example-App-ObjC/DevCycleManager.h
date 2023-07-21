//
//  DevCycleManager.h
//  DevCycle-Example-App-ObjC
//
//

#import <Foundation/Foundation.h>
@import DevCycle;

NS_ASSUME_NONNULL_BEGIN

@interface DevCycleManager : NSObject

@property (atomic, readonly) DevCycleClient * _Nullable client;

+ (id)sharedManager;

- (DevCycleClient*)initialize:(DevCycleUser *)user onInitialized:(void (^_Nullable)(NSError*))onInitialized;

@end

NS_ASSUME_NONNULL_END
