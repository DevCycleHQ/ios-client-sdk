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
    
    DVCUser *user = [DVCUser initializeWithUserId:@"test_user"];
    user.customData = @{
        @"key": @"value",
        @"num": @610.610,
        @"bool": @YES
    };
    
    [[DevCycleManager sharedManager] initialize:user onInitialized:^(NSError * _Nonnull err) {
        DVCClient *client = [[DevCycleManager sharedManager] client];
        if (err || client == nil) {
            return NSLog(@"Error starting DevCycle: %@", err.description);
        }
        
        DVCVariable *stringVar = [[client stringVariableWithKey:@"string_key" defaultValue:@"default"]
                                  onUpdateWithHandler:^(id _Nonnull value) {
            NSLog(@"string_key value updated: %@", value);
        }];
        DVCVariable *numVar = [[client numberVariableWithKey:@"num_key" defaultValue:@610]
                               onUpdateWithHandler:^(id _Nonnull value) {
            NSLog(@"num_key value updated: %@", value);
        }];
        DVCVariable *boolVar = [[client boolVariableWithKey:@"bool_key" defaultValue:NO]
                                onUpdateWithHandler:^(id _Nonnull value) {
            NSLog(@"bool_key value updated: %@", value);
        }];
        DVCVariable *jsonVar = [[client jsonVariableWithKey:@"json_key" defaultValue:@{@"key": @"value"}]
                                onUpdateWithHandler:^(id _Nonnull value) {
            NSLog(@"json_key value updated: %@", value);
        }];
        
        NSLog(@"DVC Var Values\n string: %@\n num: %@\n bool: %@\n json: %@", stringVar.value, numVar.value, boolVar.value, jsonVar.value);
        
        NSDictionary *allFeatures = [client allFeatures];
        NSLog(@"DVC All Features: %@", allFeatures);
        NSDictionary *allVariables = [client allVariables];
        NSLog(@"DVC All Variables: %@", allVariables);
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
