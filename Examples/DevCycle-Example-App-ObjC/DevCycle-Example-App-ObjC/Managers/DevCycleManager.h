//
//  DevCycleManager.h
//  DevCycle-Example-App-ObjC
//
//

#import <Foundation/Foundation.h>
@import DevCycle;

NS_ASSUME_NONNULL_BEGIN

@interface DevCycleManager : NSObject

@property (atomic, readonly) DVCClient * _Nullable client;

+ (id)sharedManager;
- (DVCClient*)initialize:(DVCUser *)user onInitialized:(void (^_Nullable)(NSError*))onInitialized;

@end

NS_ASSUME_NONNULL_END
