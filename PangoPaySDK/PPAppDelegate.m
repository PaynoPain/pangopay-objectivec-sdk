//
//  PPAppDelegate.m
//  PangoPaySDK
//
//  Created by Christian Bongardt on 23/12/13.
//  Copyright (c) 2013 Christian Bongardt. All rights reserved.
//

#import "PPAppDelegate.h"
#import "PangoPayDataCacher.h"

@implementation PPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    self.window.rootViewController = [[UIViewController alloc] init];
    
    [self.window makeKeyAndVisible];
    
    [[PangoPayDataCacher sharedInstance] setupWithClientId:@""
                                                    secret:@""
                                               environment:[[PNPSandboxEnvironment alloc] init]
                                                     scope:@[@"basic"]];
    
    [[PangoPayDataCacher sharedInstance] setupLoginObserversWithSuccessCallback:^{
        NSLog(@"User logged in.");
    } andErrorCallback:^(NSError *error) {
        NSLog(@"Error logging user in %@",error);
    }];
    
    
    [[PangoPayDataCacher sharedInstance] addAccesRefreshTokenExpiryObserver:^{
        NSLog(@"Refresh token expired");
        //Present login screen.
    }];
    
    

    
    if([[PangoPayDataCacher sharedInstance] isUserLoggedIn]){
        NSLog(@"User refresh token is saved in keychain");
    }else{
        [[PangoPayDataCacher sharedInstance] loginWithUsername:@"demo" andPassword:@"1234"];
    }
    
    return YES;
}


-(void) startTests{
    
//    [self testUser];
//    [self testUserAvatar];
//    [self testNotifications];
//    [self testPangos];
//    [self testExtractFromPango];
//    [self testChangeAliasForPango];
//    [self testTransactionSend];
//    [self testTransactionList];
//    [self testCancelPendingTransaction];
//    [self testPaymentRequests];
    
//    [self testUploadAvatar];
//    [self testRegister];
//    [self testCountries];
    
//    [self testUploadDnis];
    [self testGetCards];
}

-(void) testUser{
    [[PangoPayDataCacher sharedInstance] getUserDataWithSuccessCallback:^(PNPUser *user) {
        NSLog(@"User %@",user);
    } andErrorCallback:^(NSError *error) {
        NSLog(@"Error in user test %@",error);
    } andRefreshCallback:^(PNPUser *user) {
        NSLog(@"User refreshed %@",user);
    }];
    
}

-(void) testUserAvatar{
    [[PangoPayDataCacher sharedInstance] getUserAvatarWithSuccessCallback:^(UIImage *avatar) {
        NSLog(@"User avatar obtained: %@",avatar);
        
    } andErrorCallback:^(NSError *error) {
        NSLog(@"Error in user avatar test %@",error);
       
    } andRefreshCallback:^(UIImage *avatar) {
        NSLog(@"User avatar image refreshed %@",avatar);
       
    }];
    
}

-(void) testNotifications{
    
    [[PangoPayDataCacher sharedInstance] getNotificationsWithSuccessCallback:^(NSArray *data) {
        NSLog(@"Notifications count: %lu %@",(unsigned long)[data count],data);
        if([data count] > 0){
            [[PangoPayDataCacher sharedInstance] deleteNotification:[data objectAtIndex:0] withSuccessCallback:^{
                NSLog(@"Notification deleted");
                
                [[PangoPayDataCacher sharedInstance] getNotificationsWithSuccessCallback:^(NSArray *data) {
                    NSLog(@"Notifications count: %lu after deleting notification: %@ ",(unsigned long)[data count],data);
                    
                } andErrorCallback:^(NSError *error) {
                    
                }];
                
                
            } andErrorCallback:^(NSError *error) {
                NSLog(@"Error in deleting notification");
                
            }];
            
        }        
        
    } andErrorCallback:^(NSError *error) {
        NSLog(@"error in get notifications");
       
    } andRefreshCallback:nil 

       
    ];
}

-(void) testExtractFromPango{
    [[PangoPayDataCacher sharedInstance] getPangoWithIdentifier:@59 withSuccessCallback:^(PNPPango *pango) {
        NSLog(@"Pango %@",pango);
        
        [[PangoPayDataCacher sharedInstance] extractFromPango:pango amount:@10 withSuccessCallback:^{
            [[PangoPayDataCacher sharedInstance] getPangoWithIdentifier:@59 withSuccessCallback:^(PNPPango *pango) {
                NSLog(@"Pango :%@",pango);
            } andErrorCallback:^(NSError *error) {
                NSLog(@"Error getting pango");
            }];
        } andErrorCallback:^(NSError *error) {
            NSLog(@"Error extracting from pango");
        }];
        
    } andErrorCallback:^(NSError *error) {
        NSLog(@"Error getting pango");
    }];
}

-(void) testChangeAliasForPango{
    [[PangoPayDataCacher sharedInstance] getPangoWithIdentifier:@59 withSuccessCallback:^(PNPPango *pango) {
        NSLog(@"Pango %@",pango);
        pango.alias = @"caca";
        [[PangoPayDataCacher sharedInstance] updatePangoAlias:pango withSuccessCallback:^{
            [[PangoPayDataCacher sharedInstance] getPangoWithIdentifier:@59 withSuccessCallback:^(PNPPango *pango) {
                NSLog(@"Pango :%@",pango);
            } andErrorCallback:^(NSError *error) {
                NSLog(@"Error getting pango");
            }];
        } andErrorCallback:^(NSError *error) {
            NSLog(@"Error extracting from pango");
        }];
        
    } andErrorCallback:^(NSError *error) {
        NSLog(@"Error getting pango");
    }];
    
}

-(void) testChangeStatusForPango{
    [[PangoPayDataCacher sharedInstance] getPangoWithIdentifier:@59 withSuccessCallback:^(PNPPango *pango) {
        NSLog(@"Pango %@",pango);
        
        [[PangoPayDataCacher sharedInstance] changeStatusForPango:pango withSuccessCallback:^{
            [[PangoPayDataCacher sharedInstance] getPangoWithIdentifier:@59 withSuccessCallback:^(PNPPango *pango) {
                NSLog(@"Pango :%@",pango);
            } andErrorCallback:^(NSError *error) {
                NSLog(@"Error getting pango");
            }];
        } andErrorCallback:^(NSError *error) {
            NSLog(@"Error updating status for pango");
        }];
        
    } andErrorCallback:^(NSError *error) {
        NSLog(@"Error getting pango");
    }];
}

-(void) testPangos{
    [[PangoPayDataCacher sharedInstance] getPangosWithSuccessCallback:^(NSArray *data) {
        NSLog(@"data %@",data);
        if([data count] > 0){
            [[PangoPayDataCacher sharedInstance] getPangoMovements:[data objectAtIndex:0] withSuccessCallback:^(NSArray *data) {
                NSLog(@"Pango movements %@",data);
            } andErrorCallback:^(NSError *error) {
                NSLog(@"Error in pango movements");
            } andRefreshCallback:^(NSArray *data) {
                NSLog(@"Pango movements refreshed");
            }];
        }
       
    } andErrorCallback:^(NSError *error) {
        NSLog(@"Error in getting pangos");
    } andRefreshCallback:^(NSArray *data) {
        NSLog(@"Pangos were refreshed");
       
    }];
}

-(void) testTransactionSend{
    [[PangoPayDataCacher sharedInstance] getUserDataWithSuccessCallback:^(PNPUser *user) {
        NSLog(@"User before sending %@",user);
    } andErrorCallback:nil andRefreshCallback:nil];

    
    [[PangoPayDataCacher sharedInstance] getSendTransactionCommissionForAmount:@100 withPrefix:@"34" andPhone:@"3" withSuccessCallback:^(NSNumber *number) {
        NSLog(@"Commision %@",number);
        
        [[PangoPayDataCacher sharedInstance] getTransactionReceiverWithPrefix:@"34" andPhone:@"3" andSuccessCallBack:^(PNPTransactionReceiver *receiver) {
            NSLog(@"Transaction receiver :%@",receiver);
            
            [[PangoPayDataCacher sharedInstance] sendTransactionWithAmount:@100 toPrefix:@"34" phone:@"3" pin:@"1234" withSuccessCallback:^{
                NSLog(@"Transaction sent succesfully");
                [[PangoPayDataCacher sharedInstance] getUserDataWithSuccessCallback:^(PNPUser *user) {
                    NSLog(@"User after sending %@",user);
                } andErrorCallback:nil andRefreshCallback:nil];
            } andErrorCallback:^(NSError *error) {
                NSLog(@"Error sending transaction %@",error);
            }];
        } andErrorCallback:^(NSError *error) {
            NSLog(@"Error getting receiver info");
        }];
        
    } andErrorCallback:^(NSError *error) {
        NSLog(@"Error getting commision for transaction");
    }];
    
    
}

-(void) testTransactionList{
    [[PangoPayDataCacher sharedInstance] getTransactionsWithSuccessCallback:^(NSArray *data) {
        NSLog(@"All transactions count %lu %@",(unsigned long)[data count],data);
    }andErrorCallback:^(NSError *error) {
        NSLog(@"Error obtaining all transactions");
    } andRefreshCallback:^(NSArray *data) {
        NSLog(@"Refreshed all transactions %@",data);
    }];
}

-(void) testCancelPendingTransaction{
    [[PangoPayDataCacher sharedInstance] getPendingTransactionsWithSuccessCallback:^(NSArray *data) {
        NSLog(@"Count of pending transaction before cancel %lu, %@",(unsigned long)[data count],data);
        if([data count] > 0){

            [[PangoPayDataCacher sharedInstance] cancelPendingTransaction:[data objectAtIndex:0] withSuccessCallback:^{
                NSLog(@"caca");
                
                [[PangoPayDataCacher sharedInstance] getPendingTransactionsWithSuccessCallback:^(NSArray *data) {
                    NSLog(@"Count of pending transaction after cancel %lu : %@",(unsigned long)[data count],data);
                } andErrorCallback:nil andRefreshCallback:nil];
            } andErrorCallback:^(NSError *error) {
                NSLog(@"Error cancelling transaction");
            }];
        }
    } andErrorCallback:^(NSError *error) {
        NSLog(@"Error getting pending transactions");
    } andRefreshCallback:nil];
}

-(void) testPaymentRequests{
    [[PangoPayDataCacher sharedInstance] getPaymentRequestsWithSuccessCallback:^(NSArray *data) {
        NSLog(@"Payment requests count %lu: %@",(unsigned long)[data count],data);
        if([data count] > 0){
            [[PangoPayDataCacher sharedInstance] cancelPaymentRequest:[data objectAtIndex:0] withSuccessCallback:^{
                [[PangoPayDataCacher sharedInstance] getPaymentRequestsWithSuccessCallback:^(NSArray *data) {
                    NSLog(@"Count of payment request after cancelling %lu",(unsigned long) [data count]);
                } andErrorCallback:nil];
            } andErrorCallback:^(NSError *error) {
                NSLog(@"Error cancelling payment request");
            }];
            
            [[PangoPayDataCacher sharedInstance] getUserDataWithSuccessCallback:^(PNPUser *user) {
                NSLog(@"User before confirming payment request %@",user);
            } andErrorCallback:nil];
            
            
            [[PangoPayDataCacher sharedInstance] confirmPaymentRequest:[data objectAtIndex:2] pin:@"1234" withSuccessCallback:^{
                [[PangoPayDataCacher sharedInstance] getPaymentRequestsWithSuccessCallback:^(NSArray *data) {
                    NSLog(@"Count of payment request after confirming %lu",(unsigned long) [data count]);
                } andErrorCallback:nil];
                [[PangoPayDataCacher sharedInstance] getUserDataWithSuccessCallback:^(PNPUser *user) {
                    NSLog(@"User after confirming payment request %@",user);
                } andErrorCallback:nil];
                
            } andErrorCallback:^(NSError *error) {
                NSLog(@"Error confirming payment request");
            }];
            
            
        }
    } andErrorCallback:^(NSError *error) {
        NSLog(@"Error obtaining payment requests");
    } andRefreshCallback:nil];
}

-(void) testUploadAvatar{
    [[PangoPayDataCacher sharedInstance] uploadAvatar:[UIImage imageNamed:@"image.jpg"] withSuccessCallback:^{
        NSLog(@"Avatar uploaded");
    } andErrorCallback:^(NSError *error) {
        NSLog(@"error uploading avatar");
    }];
}

-(void) testRegister{
    [[PangoPayDataCacher sharedInstance] registerUserWithUsername:@"pepopepo" password:@"lalalalala12A" name:@"trololo" surname:@"lolo" email:@"lolo@mail.com" prefix:@"34" phone:@"12823758" pin:@1234 male:YES withSuccessCallback:^{
        NSLog(@"Register user OK");
       
    } andErrorCallback:^(NSError *error){
        NSLog(@"Error in register user %@",[error userInfo]);
       
    }];
}

-(void) testCountries{
    [[PangoPayDataCacher sharedInstance] getCountriesWithSuccessCallback:^(NSArray *data) {
        NSLog(@"Countries: %@",data);
    } andErrorCallback:^(NSError *error) {
        NSLog(@"Error getting countries %@",error);
    }];
}

-(void)testUploadDnis{
    
    [[PangoPayDataCacher sharedInstance] getUserValidationStatusWithSuccessCallback:^(PNPUserValidation *val) {
        NSLog(@"User Validation %@",val);
    } andErrorCallback:^(NSError *error) {
        NSLog(@"Error getting user validation");
    } andRefreshCallback:nil];
    
    
    [[PangoPayDataCacher sharedInstance] uploadIdCard:[UIImage imageNamed:@"image.jpg"] andBack:[UIImage imageNamed:@"image.jpg"] withSuccessCallback:^{
        NSLog(@"DNIS uploaded");
        [[PangoPayDataCacher sharedInstance] getUserValidationStatusWithSuccessCallback:^(PNPUserValidation *val) {
            NSLog(@"User Validation %@",val);
        } andErrorCallback:^(NSError *error) {
            NSLog(@"Error getting user validation");
        } andRefreshCallback:nil];
    } andErrorCallback:^(NSError *error) {
        NSLog(@"Error uploading dnis");
    }];
}

-(void) testGetCards{
    [[PangoPayDataCacher sharedInstance] getCreditCardsWithSuccessCallback:^(NSArray *data) {
        NSLog(@"Credit cards obtained %@",data);
        PNPCreditCard *c = [data objectAtIndex:0];
        c.isDefault = YES;
        c.alias = @"caca";
        [[PangoPayDataCacher sharedInstance] updateCard:c withSuccessCallback:^{
            [[PangoPayDataCacher sharedInstance] getCreditCardsWithSuccessCallback:^(NSArray *data) {
                NSLog(@"Card updated %@",data);
            } andErrorCallback:nil];
        } andErrorCallback:^(NSError *error) {
            NSLog(@"Error updating card %@",error);
        }];
    } andErrorCallback:^(NSError *error) {
        NSLog(@"Credit cards error");
    } refreshCallback:nil];
}

@end
