//
//  ViewController.m
//  DevCycle-Example-App-ObjC
//
//

#import "ViewController.h"
#import "DevCycleManager.h"
@import DevCycle;

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (strong) DVCClient *client;
@property BOOL loggedIn;

@end

@implementation ViewController

- (IBAction)loginButtonPressed:(id)sender {
    __weak typeof(self) weakSelf = self;
    if (self.loggedIn) {
        [self.client resetUser:^(NSError *error, NSDictionary<NSString *,id> *variables) {
            NSLog(@"Reset User!");
            NSLog(@"%@", variables);
            weakSelf.loggedIn = NO;
            [weakSelf.loginButton setTitle:@"Log In" forState:UIControlStateNormal];
        }];
    } else {
        DVCUser *user = [DVCUser initializeWithUserId:@"my-user"];
        user.userId = @"my-user";
        user.name = @"My Name";
        user.language = @"en";
        user.country = @"CA";
        user.email = @"my@email.com";
        
        [self.client identifyUser:user callback:^(NSError *error, NSDictionary<NSString *,id> *variables) {
            if (error) {
                return NSLog(@"Error calling DVCClient identifyUser:callback: %@", error);
            }
            NSLog(@"Identified User!");
            NSLog(@"%@", variables);
            weakSelf.loggedIn = YES;
            [weakSelf.loginButton setTitle:@"Log Out" forState:UIControlStateNormal];
        }];
    }
}

- (IBAction)track:(id)sender {
    NSError *err = nil;
    DVCEvent *event = [DVCEvent initializeWithType:@"my-event"];
    [self.client track:event err:&err];
    if (err) {
        NSLog(@"Error calling DVCClient track:err: %@", err);
    }
}


- (IBAction)logAllFeatures:(id)sender {
    NSLog(@"All Features: %@", [self.client allFeatures]);
    NSLog(@"All Variables: %@", [self.client allVariables]);
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.client = [[DevCycleManager sharedManager] client];
}


@end
