//
//  PangoPaySDKTests.m
//  PangoPaySDKTests
//
//  Created by Christian Bongardt on 23/12/13.
//  Copyright (c) 2013 Christian Bongardt. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "PaynoPainDataCacher.h"

@interface PangoPaySDKTests : XCTestCase

@end

@implementation PangoPaySDKTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    [[PaynoPainDataCacher sharedInstance] setupWithClientId:@"NTE0MmY3NDE1ODcwYTQ2"
                                                     secret:@"427f2acb4fafc6d4104917ca44573884f290eed0"
                                                environment:[[PNPSandboxEnvironment alloc] init]
                                                      scope:@[@"basic"]];
    [[PaynoPainDataCacher sharedInstance] setupLoginObserversWithSuccessCallback:^{
        NSLog(@"User logged in.");
    } andErrorCallback:^(NSError *error) {
        XCTFail(@"Couldn't log in: %@",error);
    }];
    
    [[PaynoPainDataCacher sharedInstance] addAccesRefreshTokenExpiryObserver:^{
        XCTFail(@"Refresh token expired");
    }];
    
    [[PaynoPainDataCacher sharedInstance] loginWithUsername:@"jordi2" andPassword:@"1234"];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testUserdata
{
    if(![[PaynoPainDataCacher sharedInstance] isUserLoggedIn]){
        NSLog(@"User still not logged in. Waiting for login or error.");
        [self testUserdata];
    }
    
    __block BOOL hasCalledBack = NO;
    __block BOOL hasRefreshed  = NO;
    
    
    [[PaynoPainDataCacher sharedInstance]getUserDataWithSuccessCallback:^(PNPUser *user) {
        hasCalledBack = YES;
        NSLog(@"user: %@",user);
       
    } andErrorCallback:^(NSError *error) {
        hasCalledBack = YES;
       
    } andRefreshCallback:^(PNPUser *user) {
                NSLog(@"user: %@",user);
        hasRefreshed = YES;
        
    }];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:10];
    while (hasCalledBack == NO && [loopUntil timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    if (!hasCalledBack && !hasRefreshed)
    {
        XCTFail(@"getUserData did not perform any callbacks in specified timeout.");
    }
    
}

@end
