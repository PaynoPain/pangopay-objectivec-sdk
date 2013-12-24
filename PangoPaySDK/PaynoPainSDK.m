//
//  PaynoPainSDK.m
//  PaynoPain
//
//  Created by Christian Bongardt on 21/11/13.
//  Copyright (c) 2013 PaynoPain. All rights reserved.
//

#import "PaynoPainSDK.h"
#import "NXOAuth2.h"
#import "DataSharer.h"


#define     PNP_MOBILE_ACCOUNT_TYPE            @"paynopain"
#define     PNP_MOBILE_ACCOUNT_IDENTIFIER_KEY  @"pnpaccount"


@interface PaynoPainSDK ()
@property (strong,nonatomic) NSUserDefaults  *userDefaults;
@property (nonatomic)  BOOL userIsLoggedIn;
@end

@implementation PaynoPainSDK


+ (instancetype)sharedInstance{
    static id sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}


#pragma mark - Authentication Methods
-(void) setupLoginObserversWithSuccessCallback:(PnPLoginSuccessHandler)successHandler
                              andErrorCallback:(PnPLoginErrorHandler)errorHandler{
    [[NSNotificationCenter defaultCenter]
     addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification
     object:[NXOAuth2AccountStore sharedStore]
     queue:nil
     usingBlock:^(NSNotification *aNotification){
         if(aNotification.userInfo != nil){
             NXOAuth2Account *a = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreNewAccountUserInfoKey];
             [DataSharer sharedInstance].userAccount = a;
             [self.userDefaults setObject:a.identifier
                                   forKey:PNP_MOBILE_ACCOUNT_IDENTIFIER_KEY];
             [self.userDefaults synchronize];
             self.userIsLoggedIn = YES;
             if(successHandler) successHandler();
         }else{
             NSError *error = [aNotification.userInfo
                               objectForKey:NXOAuth2AccountStoreErrorKey];
            if(errorHandler)errorHandler( [self handleErrors:error]);
         }
     }];
    [[NSNotificationCenter defaultCenter]
     addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification
     object:[NXOAuth2AccountStore sharedStore]
     queue:nil
     usingBlock:^(NSNotification *aNotification){
         NSError *error = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
         if(errorHandler) errorHandler([self handleErrors:error]);
     }];
}

-(void) addAccesRefreshTokenExpiryObserver:(PnPLogoutHandler) callback{
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountDidFailToGetAccessTokenNotification
                                                      object:[DataSharer sharedInstance].userAccount
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      NSLog(@"REFRESH TOKEN INVALID");
                                                      [self logout];
                                                      if(callback) callback();
                                                  }
     ];
    
}


-(void) loginWithUsername:(NSString *)username
              andPassword:(NSString *)password{
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:PNP_MOBILE_ACCOUNT_TYPE
                                                              username:username
                                                              password:password];
}

-(BOOL) isUserLoggedIn{
    return self.userIsLoggedIn;
}

-(void) logout{
    self.userIsLoggedIn = NO;
    [[NXOAuth2AccountStore sharedStore] removeAccount:[DataSharer sharedInstance].userAccount];
    [self.userDefaults removeObjectForKey:PNP_MOBILE_ACCOUNT_IDENTIFIER_KEY];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self.userDefaults synchronize];
    });
}

#pragma mark - User Methods

-(void) getUserDataWithSuccessCallback:(PnpUserDataSuccessHandler) successHandler
                      andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"users/user_data"]
                   usingParameters:nil
                       withAccount:[DataSharer sharedInstance].userAccount
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError] objectForKey:@"user_data"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain code:[parseError code] userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([responseDictionary objectForKey:@"success"]){
                                   responseDictionary = [responseDictionary objectForKey:@"data"];
                                   PNPWallet *wallet = [[PNPWallet alloc] initWithAmount:[self clearAmount:[responseDictionary objectForKey:@"amount"]]
                                                                          retainedAmount:[self clearAmount:[responseDictionary objectForKey:@"retained"]]
                                                                         availableAmount:[self clearAmount:[responseDictionary objectForKey:@"available"]]
                                                                            currencyCode:[responseDictionary objectForKey:@"currency_code"]
                                                                          currencySymbol:[responseDictionary objectForKey:@"currency_symbol"]];
                                   PNPUser *user = [[PNPUser alloc] initWithUsername:[responseDictionary objectForKey:@"username"]
                                                                                name:[responseDictionary objectForKey:@"name"]
                                                                             surname:[responseDictionary objectForKey:@"surname"]
                                                                               email:[responseDictionary objectForKey:@"email"]
                                                                              prefix:[responseDictionary objectForKey:@"prefix"]
                                                                               phone:[responseDictionary objectForKey:@"phone"]
                                                                            timezone:[NSTimeZone timeZoneWithName:[responseDictionary objectForKey:@"timezone"]]
                                                                              wallet:wallet];
                                   if(successHandler)  successHandler(user);
                                   
                               }else{
                                   if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError" code:-6060 userInfo:nil]);
                                   
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"Exception throwed at getUserData: %@",exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson" code:-2020 userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);

                       }
                   }];
}


-(void) getUserAvatarWithSuccessCallback:(PnpUserAvatarSuccessHandler) successHandler
                        andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[NSURL URLWithString:[PNP_MOBILE_BASE_URL stringByAppendingString:@"users/avatar"]]
                   usingParameters:nil
                       withAccount:[DataSharer sharedInstance].userAccount
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           UIImage *image = [UIImage imageWithData:responseData];
                           if(successHandler) successHandler(image);
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
    
}

#pragma mark - Notification Methods

-(void) getNotificationsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler)successHandler
                           andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"notifications/get"]
                   usingParameters:nil
                       withAccount:[DataSharer sharedInstance].userAccount
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error)

    {
                       if(!error){
                           @try {
                               NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
                               [nf setNumberStyle:NSNumberFormatterNoStyle];
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError] objectForKey:@"get"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain code:[parseError code] userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([responseDictionary objectForKey:@"success"]){
                                   NSDateFormatter *df = [[NSDateFormatter alloc] init];
                                   [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                                   [df setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Madrid"]];
                                   NSMutableArray *notifications = [NSMutableArray array];
                                   for(NSDictionary *dN in [responseDictionary objectForKey:@"data"]){
                                       NSDictionary *d = [dN objectForKey:@"Notification"];
                                       PNPNotification *n = [[PNPNotification alloc]
                                                             initWithId:[nf numberFromString:[d objectForKey:@"id"]]
                                                             creationDate:[df dateFromString:[d objectForKey:@"created"]]
                                                             message:[d objectForKey:@"message"]
                                                             referenceId:[nf numberFromString:[d objectForKey:@"reference_id"]]
                                                             userId:[nf numberFromString:[d objectForKey:@"user_id"]]
                                                             type:[d objectForKey:@"type"]];
                                       [notifications addObject:n];
                                   }
                                   if(successHandler) successHandler(notifications);
                               }else{
                                   if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError" code:-6060 userInfo:nil]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"Exception throwed at getNotifications: %@",exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson" code:-2020 userInfo:nil]);
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                       }

                   }];
}

-(void) deleteNotifications:(NSSet *) notifications withSuccessCallback:(PnPSuccessHandler)successHandler
           andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    NSArray *a = [notifications allObjects];
    NSString *ids = @"";
    for (PNPNotification *n in a){
        ids = [ids stringByAppendingString:[NSString stringWithFormat:@"%@,",n.identifier]];
    }
    if([a count] != 0){
        ids = [ids substringToIndex:[ids length] - 1];
    }else{
        if(successHandler) successHandler();
    }


    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"notifications/markAsRead"]
                   usingParameters:@{@"id":ids}
                       withAccount:[DataSharer sharedInstance].userAccount
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           NSError *parseError;
                           NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError] objectForKey:@"markAsRead"];
                           if(parseError){
                               if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain code:[parseError code] userInfo:parseError.userInfo]);
                               return;
                           }
                           if([responseDictionary objectForKey:@"success"]){
                               if(successHandler) successHandler();
                           }else{
                               if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError" code:-6060 userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
}

-(void) deleteNotification:(PNPNotification *) notification withSuccessCallback:(PnPSuccessHandler)successHandler
          andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    [self deleteNotifications:[NSSet setWithObjects:notification, nil] withSuccessCallback:successHandler andErrorCallback:errorHandler];
}


#pragma mark - Pango Methods

-(void) getPangosWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                    andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    

    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"pangos/get"]
                   usingParameters:nil
                       withAccount:[DataSharer sharedInstance].userAccount
                           timeout:10
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
                               [nf setNumberStyle:NSNumberFormatterNoStyle];
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError] objectForKey:@"get"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain code:[parseError code] userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([responseDictionary objectForKey:@"success"]){
                                   NSMutableArray *pangos = [NSMutableArray new];
                                   NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
                                   [nf setNumberStyle:NSNumberFormatterNoStyle];
                                   NSDateFormatter *df = [[NSDateFormatter alloc] init];
                                   [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                                   [df setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Madrid"]];
                                   for(NSDictionary *d in [responseDictionary objectForKey:@"data"]){
                                       NSNumber *amount = [nf numberFromString:[d objectForKey:@"amount"]];
                                       amount = [NSNumber numberWithDouble:[amount doubleValue]/100];
                                       NSNumber *limit;
                                       if([[d objectForKey:@"limit"] isKindOfClass:[NSNumber class]]){
                                           limit = [d objectForKey:@"limit"];
                                       }else{
                                           limit = nil;
                                       }
                                       PNPPango *p = [[PNPPango alloc] initWithIdentifier:[nf numberFromString:[d objectForKey:@"id"]] alias:[d objectForKey:@"alias"] serial:[d objectForKey:@"serial"] status:[d objectForKey:@"status"] creator:[d objectForKey:@"creator"] currencyCode:[d objectForKey:@"currency"] amount:amount limit:limit created:[df dateFromString:[d objectForKey:@"created"]]];
                                       [pangos addObject:p];
                                   }
                                   NSSortDescriptor *sortDescriptor;
                                   sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"created"
                                                                                ascending:NO];
                                   NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                                   pangos = [NSMutableArray arrayWithArray:[pangos sortedArrayUsingDescriptors:sortDescriptors]];
                                   if(successHandler) successHandler(pangos);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError" code:-6060 userInfo:nil]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"Exception throwed at getPangos: %@",exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson" code:-2020 userInfo:nil]);
                           }
                       }else{
                           NSLog(@"Error %@",error);
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                       
                   }];
}

-(void) getPangoWithIdentifier:(NSNumber *) identifier
           withSuccessCallback:(PnpPangoDataSuccessHandler) successHandler
                    andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"pangos/get"]
                   usingParameters:@{@"id":identifier}
                       withAccount:[DataSharer sharedInstance].userAccount
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
                               [nf setNumberStyle:NSNumberFormatterNoStyle];
                               NSDateFormatter *df = [[NSDateFormatter alloc] init];
                               [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                               [df setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Madrid"]];
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError] objectForKey:@"get"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain code:[parseError code] userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([responseDictionary objectForKey:@"success"]){
                                   NSMutableArray *pangos = [NSMutableArray new];
                                   for(NSDictionary *d in [responseDictionary objectForKey:@"data"]){
                                       NSNumber *amount = [nf numberFromString:[d objectForKey:@"amount"]];
                                       amount = [NSNumber numberWithDouble:[amount doubleValue]/100];
                                       NSNumber *limit;
                                       if([[d objectForKey:@"limit"] isKindOfClass:[NSNumber class]]){
                                           limit = [d objectForKey:@"limit"];
                                       }else{
                                           limit = nil;
                                       }
                                       PNPPango *p = [[PNPPango alloc] initWithIdentifier:[nf numberFromString:[d objectForKey:@"id"]] alias:[d objectForKey:@"alias"] serial:[d objectForKey:@"serial"] status:[d objectForKey:@"status"] creator:[d objectForKey:@"creator"] currencyCode:[d objectForKey:@"currency"] amount:amount limit:limit created:[df dateFromString:[d objectForKey:@"created"]]];
                                       [pangos addObject:p];
                                   }
                                   if(successHandler) successHandler([pangos objectAtIndex:0]);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError" code:-6060 userInfo:nil]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"Exception throwed at getPango: %@",exception);
                               if(errorHandler)errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson" code:-2020 userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                       
                   }];
}


-(void) updatePangoAlias:(PNPPango *) pango
        withSuccessCallback:(PnPSuccessHandler) successHandler
           andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(pango == nil){
        if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPWebserviceError" code:-6060 userInfo:@{@"error":@"Pango cannot be nil"}]);
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"pangos/edit_alias"]
                   usingParameters:@{@"id":pango.identifier,@"alias":pango.alias}
                       withAccount:[DataSharer sharedInstance].userAccount
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           NSError *parseError;
                           NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError] objectForKey:@"edit_alias"];
                           if(parseError){
                               if(errorHandler)errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain code:[parseError code] userInfo:parseError.userInfo]);
                               return;
                           }
                           if([responseDictionary objectForKey:@"success"]){
                               if(successHandler) successHandler();
                           }else{
                               if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError" code:-6060 userInfo:[responseDictionary objectForKey:@"message"]]);
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                       }
                   }];

    
}
-(void) changeStatusForPango:(PNPPango *) pango
         withSuccessCallback:(PnPSuccessHandler)successHandler
            andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(pango == nil){
        if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPWebserviceError" code:-6060 userInfo:@{@"error":@"Pango cannot be nil"}]);
        return;
    }
    NSString *resourceParam;
    if([pango.status isEqualToString:PNPPangoStatusBlocked]){
        resourceParam = @"unblock";
    }else{
        resourceParam = @"block";
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:[NSString stringWithFormat:@"pangos/%@",resourceParam]]
                   usingParameters:@{@"id":pango.identifier}
                       withAccount:[DataSharer sharedInstance].userAccount
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           NSError *parseError;
                           NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError] objectForKey:resourceParam];
                           if(parseError){
                               if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain code:[parseError code] userInfo:parseError.userInfo]);
                               return;
                           }
                           if([responseDictionary objectForKey:@"success"]){
                               if(successHandler)successHandler();
                           }else{
                               if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError" code:-6060 userInfo:[responseDictionary objectForKey:@"message"]]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
}

-(void) cancelPango:(PNPPango *) pango
withSuccessCallback:(PnPSuccessHandler)successHandler
   andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(pango == nil){
        if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPWebserviceError" code:-6060 userInfo:@{@"error":@"Pango cannot be nil"}]);
        return;
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"pangos/cancel"]
                   usingParameters:@{@"id":pango.identifier}
                       withAccount:[DataSharer sharedInstance].userAccount
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           NSError *parseError;
                           NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError] objectForKey:@"cancel"];
                           if(parseError){
                               if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain code:[parseError code] userInfo:parseError.userInfo]);
                               return;
                           }
                           if([responseDictionary objectForKey:@"success"]){
                               if(successHandler)successHandler();
                           }else{
                               if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError" code:-6060 userInfo:[responseDictionary objectForKey:@"message"]]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
}


-(void) unlinkPango:(PNPPango *) pango
withSuccessCallback:(PnPSuccessHandler)successHandler
   andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(pango == nil){
        if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPWebserviceError" code:-6060 userInfo:@{@"error":@"Pango cannot be nil"}]);
        return;
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"pangos/unlink_pango"]
                   usingParameters:@{@"id":pango.identifier}
                       withAccount:[DataSharer sharedInstance].userAccount
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           NSError *parseError;
                           NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError] objectForKey:@"unlink_pango"];
                           if(parseError){
                               if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain code:[parseError code] userInfo:parseError.userInfo]);
                               return;
                           }
                           if([responseDictionary objectForKey:@"success"]){
                               if(successHandler)successHandler();
                           }else{
                               if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError" code:-6060 userInfo:[responseDictionary objectForKey:@"message"]]);
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                       }
                   }];

}

-(void) rechargePango:(PNPPango *) pango
           withAmount:(NSNumber *) amount
  withSuccessCallback:(PnPSuccessHandler) successHandler
     andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(pango == nil){
        if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPWebserviceError" code:-6060 userInfo:@{@"error":@"Pango cannot be nil"}]);
        return;
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"pangos/move_in"]
                   usingParameters:@{@"id":pango.identifier,@"amount":[NSString stringWithFormat:@"%f",[amount doubleValue] *100]}
                       withAccount:[DataSharer sharedInstance].userAccount
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           NSError *parseError;
                           NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError] objectForKey:@"move_in"];
                           if(parseError){
                               if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain code:[parseError code] userInfo:parseError.userInfo]);
                               return;
                           }
                           if([responseDictionary objectForKey:@"success"]){
                               if(successHandler)successHandler();
                           }else{
                               if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError" code:-6060 userInfo:[responseDictionary objectForKey:@"message"]]);
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                       }
                   }];
    
}

-(void) extractFromPango:(PNPPango *) pango
                  amount:(NSNumber *) amount
     withSuccessCallback:(PnPSuccessHandler) successHandler
        andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(pango == nil){
        if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPWebserviceError" code:-6060 userInfo:@{@"error":@"Pango cannot be nil"}]);
        return;
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"pangos/move_out"]
                   usingParameters:@{@"id":pango.identifier,@"amount":[NSString stringWithFormat:@"%f",[amount doubleValue] *100]}
                       withAccount:[DataSharer sharedInstance].userAccount
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           NSError *parseError;
                           NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError] objectForKey:@"move_out"];
                           if(parseError){
                               if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain code:[parseError code] userInfo:parseError.userInfo]);
                               return;
                           }
                           if([responseDictionary objectForKey:@"success"]){
                               if(successHandler)successHandler();
                           }else{
                               if(successHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError" code:-6060 userInfo:[responseDictionary objectForKey:@"message"]]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
    
}

-(void) getPangoMovements:(PNPPango *) pango
      withSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
         andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(pango == nil){
        if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPWebserviceError" code:-6060 userInfo:@{@"error":@"Pango cannot be nil"}]);
        return;
    }   
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"pangos/movements"]
                   usingParameters:@{@"pango_id":pango.identifier}
                       withAccount:[DataSharer sharedInstance].userAccount
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
                               [nf setNumberStyle:NSNumberFormatterNoStyle];
                               NSDateFormatter *df = [[NSDateFormatter alloc] init];
                               [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                               [df setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Madrid"]];
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError] objectForKey:@"movements"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain code:[parseError code] userInfo:parseError.userInfo]);
                                   return;
                               }
                               
                               if([responseDictionary objectForKey:@"success"]){
                                   NSMutableArray *movements = [NSMutableArray new];

                                   NSArray *results;
                                   if([[responseDictionary objectForKey:@"data"] isKindOfClass:[NSDictionary class]]){
                                       results = [[responseDictionary objectForKey:@"data"] objectForKey:@"results"];
                                   }

                                   for (NSDictionary *r in results){
                                       NSString * type = [r objectForKey:@"type"];
                                       PNPPangoMovementEntity *emitter;
                                       PNPPangoMovementEntity *receiver;
                                       PNPPangoMovementIncome *movement;
                                       NSString *classString;
                                       NSNumber *amount = [self clearAmount:[r objectForKey:@"amount"]];
                                       NSDate *created = [df dateFromString:[r objectForKey:@"created"]];
                                       NSDictionary *emitterDictionary = [[r objectForKey:@"emitter"] objectForKey:@"data"];
                                       NSDictionary *receiverDictionary = [[r objectForKey:@"receiver"] objectForKey:@"data"];
                                       if([type isEqualToString:PNPPangoMovementTypeCommerceToPango] ||[type isEqualToString:PNPPangoMovementTypePangoChargeback] ){
                                           classString = @"PNPPangoMovementIncome";
                                           emitter = [[PNPPangoMovementCommerce alloc] initWithIdentifier:[nf numberFromString:[emitterDictionary objectForKey:@"id"]] name:[emitterDictionary objectForKey:@"name"] andSurname:[emitterDictionary objectForKey:@"surname"]];
                                           receiver = [[PNPPangoMovementPango alloc] initWithIdentifier:[nf numberFromString:[receiverDictionary objectForKey:@"id"]] andAlias:[receiverDictionary objectForKey:@"alias"]];
                                       }
                                       else if([type isEqualToString:PNPPangoMovementTypePangoRechargeChargeback]|| [type isEqualToString:PNPPangoMovementTypePangoToCommerce]){
                                           classString = @"PNPPangoMovementExpense";
                                           receiver = [[PNPPangoMovementCommerce alloc] initWithIdentifier:[nf numberFromString:[receiverDictionary objectForKey:@"id"]] name:[receiverDictionary objectForKey:@"name"] andSurname:[receiverDictionary objectForKey:@"surname"]];
                                           emitter = [[PNPPangoMovementPango alloc] initWithIdentifier:[nf numberFromString:[emitterDictionary objectForKey:@"id"]] andAlias:[emitterDictionary objectForKey:@"alias"]];
                                           
                                       }
                                       else if([type isEqualToString:PNPPangoMovementTypePangoToWallet]){
                                           classString = @"PNPPangoMovementExpense";
                                           receiver = [[PNPPangoMovementWallet alloc] initWithIdentifier:[nf numberFromString:[receiverDictionary objectForKey:@"id"]]];
                                           emitter = [[PNPPangoMovementPango alloc] initWithIdentifier:[nf numberFromString:[emitterDictionary objectForKey:@"id"]] andAlias:[emitterDictionary objectForKey:@"alias"]];
                                       }
                                       else if([type isEqualToString:PNPPangoMovementTypeWalletToPango]){
                                           classString = @"PNPPangoMovementIncome";
                                           receiver = [[PNPPangoMovementPango alloc] initWithIdentifier:[nf numberFromString:[receiverDictionary objectForKey:@"id"]] andAlias:[receiverDictionary objectForKey:@"alias"]];
                                           emitter = [[PNPPangoMovementWallet alloc] initWithIdentifier:[nf numberFromString:[emitterDictionary objectForKey:@"id"]]];
                                       }
                                       movement = [[NSClassFromString(classString) alloc] initWithEmitter:emitter
                                                                                                 receiver:receiver
                                                                                                     type:type
                                                                                                   status:[r objectForKey:@"status"]
                                                                                                  concept:[r objectForKey:@"concept"]
                                                                                                   amount:amount
                                                                                           currencySymbol:[r objectForKey:@"currency"]
                                                                                                     date:created];
                        
                                       
                                       [movements addObject:movement];
                                   }
                                   NSSortDescriptor *sortDescriptor;
                                   sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date"
                                                                                ascending:NO];
                                   NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                                   movements = [NSMutableArray arrayWithArray:[movements sortedArrayUsingDescriptors:sortDescriptors]];
                                   if(successHandler)successHandler(movements);
                               }else{
                                   if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError" code:-6060 userInfo:nil]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"Exception throwed at getPangoMovements: %@",exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson" code:-2020 userInfo:nil]);
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                       }
                       
                   }];

    
}


#pragma mark - Private Methods
-(NSNumber *) clearAmount:(NSNumber *)n{
    
    return [NSNumber numberWithDouble:[n doubleValue]/100];
}

-(id) init{
    self = [super init];
    if(self){
        [[NXOAuth2AccountStore sharedStore] setClientID:PNP_MOBILE_CLIENT_ID
                                                 secret:PNP_MOBILE_CLIENT_SECRET
                                                  scope:[NSSet setWithArray:PNP_MOBILE_SCOPES]
                                       authorizationURL:[NSURL URLWithString:[PNP_MOBILE_BASE_URL stringByAppendingString:@"oauth/token"]]
                                               tokenURL:[NSURL URLWithString:[PNP_MOBILE_BASE_URL stringByAppendingString:@"oauth/token"]]
                                            redirectURL:[NSURL URLWithString:@"localhost"]
                                         forAccountType:PNP_MOBILE_ACCOUNT_TYPE];
        
        self.userDefaults = [NSUserDefaults standardUserDefaults];
        
        NSString *userAccountIdentifier = [self.userDefaults
                                           objectForKey:PNP_MOBILE_ACCOUNT_IDENTIFIER_KEY];
        if( userAccountIdentifier != nil){
            [DataSharer sharedInstance].userAccount  = [[NXOAuth2AccountStore sharedStore]
                                 accountWithIdentifier:userAccountIdentifier];
            if([DataSharer sharedInstance].userAccount != nil){
                self.userIsLoggedIn = YES;
            }else{
                self.userIsLoggedIn = NO;
                [self logout];
            }
        }else{
            self.userIsLoggedIn = NO;
        }
    }
    return self;
}

-(NSError *) handleErrors:(NSError *) error{
    
    if([error code] == 401){
        PNPUnuthorizedAccessError * e = [[PNPUnuthorizedAccessError alloc] initWithDomain:@"PNPConnectionError"
                                                                                     code:[error code]
                                                                                 userInfo:[error userInfo]];
        return e;
    }
    else if ([error code] == 400){
        PNPBadRequest *e = [[PNPBadRequest alloc] initWithDomain:@"PNPConnectionError"
                                                            code:[error code]
                                                        userInfo:[error userInfo]];
        return e;
    }
    else if ([error code] == -1){
        PNPUnknownError *e = [[PNPUnknownError alloc] initWithDomain:@"PNPConnectionError"
                                                                code:[error code]
                                                            userInfo:[error userInfo]];
        return e;
    }
    else if([error code] == -1002 ||
            [error code] == -1000 ||
            [error code] == -1003){
        
        PNPBadUrlError *e = [[PNPBadUrlError alloc] initWithDomain:@"PNPConnectionError"
                                                              code:[error code]
                                                          userInfo:[error userInfo]];
        return e;
    }
    else if([error code] == -1005 ||
            [error code] == -1001){
        PNPTimedOutError *e = [[PNPTimedOutError alloc] initWithDomain:@"PNPConnectionError"
                                                                  code:[error code]
                                                              userInfo:[error userInfo]];
        return e;
    }
    else if ([error code] == -1009){
        PNPDeviceOfflineError *e = [[PNPDeviceOfflineError alloc] initWithDomain:@"PNPConnectionError"
                                                                            code:[error code]
                                                                        userInfo:[error userInfo]];
        return e;
    }
    else if ([error code] >= -12006 &&
             [error code] <= -12000){
        PNPCertificateError *e = [[PNPCertificateError alloc] initWithDomain:@"PNPConnectionError"
                                                                        code:[error code]
                                                                    userInfo:[error userInfo]];
        return e;
    }else{
        PNPUnknownError *e = [[PNPUnknownError alloc] initWithDomain:@"PNPConnectionError"
                                                                code:[error code]
                                                            userInfo:[error userInfo]];
        return e;
    }
}

-(NSURL *) generateUrl:(NSString *) extension{
    return [NSURL URLWithString:[PNP_MOBILE_BASE_URL stringByAppendingString:[NSString stringWithFormat:@"%@.json",extension]]];
}





@end
