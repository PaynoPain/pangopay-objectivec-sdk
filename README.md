# PangoPay SDK

An SDK for connectiv to PangoPay's API.

## Description

This library is based on [draft 10 of the OAuth2 spec] and using  [nxtbgthng's OAuth2Client https://github.com/nxtbgthng/OAuth2Client.git]

## Getting started

[CocoaPods](http://cocoapods.org/) is a dependency manager for Xcode projects. It manages the installation steps automatically.

In order to install the library this way add the following line to your `Podfile`:

```pod 'PangoPaySDK', :git => 'https://github.com/PaynoPain/pangopay-objectivec-sdk'```

and run the following command `pod install`.

## Using the OAuth2Client

### Configure your Client

The best place to configure your client is `+[UIApplicationDelegate didFinishLaunchingWithOptions]` on iOS. 

There you can call 

<pre>

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
</pre>


on the shared instance. You can either use `[PangoPaySDK sharedInstance]` or `[PangoPayDataCacher sharedInstance]`.

