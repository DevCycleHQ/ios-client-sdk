//
//  AppDelegate.m
//  DevCycle-Example-App-ObjC
//
//

#import "AppDelegate.h"
#import "DevCycleManager.h"

@import DevCycle;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // TODO: Set SDK Key in DevCycleManager.m
    
    DevCycleUser *user = [DevCycleUser initializeWithUserId:@"test_user"];
    user.customData = @{
        @"key": @"value",
        @"num": @610.610,
        @"bool": @YES
    };
    
    [[DevCycleManager sharedManager] initialize:user onInitialized:^(NSError * _Nonnull err) {
        DevCycleClient *client = [[DevCycleManager sharedManager] client];
        if (err || client == nil) {
            return NSLog(@"Error starting DevCycle: %@", err.description);
        }
        
        NSString *stringValue = [client stringVariableValueWithKey:@"string_key" defaultValue:@"default"];
        
        NSNumber *numValue = [client numberVariableValueWithKey:@"num_key" defaultValue:@610];
        
        BOOL boolValue = [client boolVariableValueWithKey:@"bool_key" defaultValue:NO];
        
        DVCVariable *jsonVar = [[client jsonVariableWithKey:@"json_key" defaultValue:@{@"key": @"value"}]
                                onUpdateWithHandler:^(id _Nonnull value) {
            NSLog(@"json_key value updated: %@", value);
        }];
        
        NSLog(@"DevCycle Variable Values\n string: %@\n num: %@\n bool: %i\n json: %@", stringValue, numValue, boolValue, jsonVar.value);
        
        NSDictionary *allFeatures = [client allFeatures];
        NSLog(@"DevCycle All Features: %@", allFeatures);
        
        NSDictionary *allVariables = [client allVariables];
        NSLog(@"DevCycle All Variables: %@", allVariables);
    }];
    
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
