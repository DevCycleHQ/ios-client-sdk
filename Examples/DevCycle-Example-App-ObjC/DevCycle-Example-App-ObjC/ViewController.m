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
    NSError *err = nil;
    if (self.loggedIn) {
        
    } else {
        DVCUser *user = [DVCUser build:&err block:^(DVCUserBuilder * builder) {
            builder.userId = @"my-user";
            builder.name = @"My Name";
            builder.language = @"EN-CA";
            builder.appVersion = @"1.0.0";
            builder.country = @"CA";
            builder.email = @"my@email.com";
        }];
        __weak typeof(self) weakSelf = self;
        [self.client identifyWithUser:user error:&err callback:^(NSError * error, NSDictionary<NSString *,id> *variables) {
            NSLog(@"Identified User!");
            NSLog(@"%@", variables);
            weakSelf.loggedIn = YES;
        }];
    }
}

- (IBAction)track:(id)sender {
    DVCEvent *event = [[DVCEvent alloc] initWithType:@"my-event" target:nil date:[NSDate date] value:nil metaData:nil];
    [self.client track:event];
}


- (IBAction)logAllFeatures:(id)sender {
    NSLog(@"All Features");
    NSLog(@"All Variables");
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.client = [[DevCycleManager sharedManager] client];
}


@end
