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
