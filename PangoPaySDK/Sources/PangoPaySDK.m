//
//  PangoPaySDK.m
//  PaynoPain
//
//  Created by Christian Bongardt on 21/11/13.
//  Copyright (c) 2013 PaynoPain. All rights reserved.
//

#import "PangoPaySDK.h"
#import "NXOAuth2.h"


#define     PNP_MOBILE_ACCOUNT_TYPE            @"paynopain"
#define     PNP_MOBILE_ACCOUNT_IDENTIFIER_KEY  @"pnpaccount"
#define     PNP_REQUEST_TIMEOUT                20

@interface PangoPaySDK ()
@property (strong,nonatomic) NSUserDefaults  *userDefaults;
@property (strong,nonatomic) NSString * clientId;
@property (strong,nonatomic) NSString * clientSecret;
@property (strong,nonatomic) PNPEnvironment *environment;
@property (strong,nonatomic) NSArray *scope;
@property (nonatomic)  BOOL userIsLoggedIn;
@property (strong,nonatomic) NXOAuth2Account *userAccount;

@end

@implementation PangoPaySDK


+ (instancetype)sharedInstance{
    static id sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}
-(id) init{
    self = [super init];
    if(self){
        
        self.userDefaults = [NSUserDefaults standardUserDefaults];
        
        NSString *userAccountIdentifier = [self.userDefaults
                                           objectForKey:PNP_MOBILE_ACCOUNT_IDENTIFIER_KEY];
        if( userAccountIdentifier != nil){
            self.userAccount  = [[NXOAuth2AccountStore sharedStore]
                                 accountWithIdentifier:userAccountIdentifier];
            if(self.userAccount != nil){
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


-(void) setupWithClientId:(NSString *) clientId
                   secret:(NSString *) secret
              environment:(PNPEnvironment *) environment
                    scope:(NSArray *) scope{
    
    self.clientId = clientId;
    self.clientSecret = secret;
    self.environment = environment;
    self.scope = scope;
    
    [[NXOAuth2AccountStore sharedStore] setClientID:self.clientId
                                             secret:self.clientSecret
                                              scope:[NSSet setWithArray:self.scope]
                                   authorizationURL:[self.environment.url URLByAppendingPathComponent: @"oauth/token"]
                                           tokenURL:[self.environment.url URLByAppendingPathComponent: @"oauth/token"]
                                        redirectURL:[NSURL URLWithString:@"localhost"]
                                     forAccountType:PNP_MOBILE_ACCOUNT_TYPE];
}

#pragma mark - Authentication Methods
-(NSArray *) setupLoginObserversWithSuccessCallback:(PnPLoginSuccessHandler)successHandler
                                   andErrorCallback:(PnPLoginErrorHandler)errorHandler{
    
    
    id observer =[[NSNotificationCenter defaultCenter]
                  addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification
                  object:[NXOAuth2AccountStore sharedStore]
                  queue:nil
                  usingBlock:^(NSNotification *aNotification){
                      if(aNotification.userInfo != nil){
                          NXOAuth2Account *a = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreNewAccountUserInfoKey];
                          self.userAccount = a;
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
    
    id observer2 = [[NSNotificationCenter defaultCenter]
                    addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification
                    object:[NXOAuth2AccountStore sharedStore]
                    queue:nil
                    usingBlock:^(NSNotification *aNotification){
                        NSError *error = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
                        if(errorHandler) errorHandler([self handleErrors:error]);
                    }];
    
    return @[observer,observer2];
}



-(void) addAccesRefreshTokenExpiryObserver:(PnPLogoutHandler) callback{
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountDidFailToGetAccessTokenNotification
                                                      object:self.userAccount
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
    [[NXOAuth2AccountStore sharedStore] removeAccount:self.userAccount];
    [self.userDefaults removeObjectForKey:PNP_MOBILE_ACCOUNT_IDENTIFIER_KEY];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self.userDefaults synchronize];
    });
}

#pragma mark - User Methods

-(void) getUserDataWithSuccessCallback:(PnpUserDataSuccessHandler) successHandler
                      andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"users/user_data"]
                   usingParameters:nil
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"user_data"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
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
                                   if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                               code:-6060
                                                                                                           userInfo:nil]);
                                   
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                           
                       }
                   }];
}


-(void) getUserAvatarWithSuccessCallback:(PnpUserAvatarSuccessHandler) successHandler
                        andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self.environment.url URLByAppendingPathComponent:@"users/avatar"]
                   usingParameters:nil
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
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


-(void) deleteUserAvatarWithSuccessCallback:(PnPSuccessHandler) successHandler
                           andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"users/delete_avatar"]
                   usingParameters:nil
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           if(successHandler) successHandler();
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
    
}

-(void) uploadAvatar:(UIImage *)avatar
 withSuccessCallback:(PnPSuccessHandler) successHandler
    andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    
    NSData *imageData = UIImageJPEGRepresentation(avatar, 0.5);
    NSString *base64encodedImage = [imageData base64EncodedString];
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"users/upload_avatar"]
                   usingParameters:@{@"avatar":base64encodedImage}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       
                       if(!error){
                           @try {
                               NSError *parseError;
                               
                               
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"upload_avatar"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   
                                   
                                   
                                   if(successHandler)  successHandler();
                                   
                               }else{
                                   if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                   initWithDomain:@"PNPGenericWebserviceError"
                                                                   code:-6060
                                                                   userInfo:nil]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                           
                       }
                   }];
}

-(void) registerUserWithUsername:(NSString *)username
                        password:(NSString *)password
                            name:(NSString *)name
                         surname:(NSString *)surname
                           email:(NSString *)email
                          prefix:(NSString *)prefix
                           phone:(NSString *)phone
                             pin:(NSNumber *)pin
                            male:(BOOL )isMale
                       birthdate:(NSDate *) date
             withSuccessCallback:(PnPSuccessHandler) successHandler
                andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"YYYY-mm-dd"];
    [params setObject:username  forKey:@"username"];
    [params setObject:password  forKey:@"password"];
    [params setObject:email     forKey:@"mail"];
    [params setObject:name      forKey:@"name"];
    [params setObject:surname   forKey:@"surname"];
    [params setObject:prefix    forKey:@"prefix"];
    [params setObject:phone     forKey:@"phone"];
    [params setObject:pin       forKey:@"pin"];
    [params setObject:[df stringFromDate:date] forKey:@"birthdate"];
    
    if(isMale){
        [params setObject:@"M" forKey:@"sex"];
    }else{
        [params setObject:@"F" forKey:@"sex"];
    }
    
    [params setObject:self.clientId forKey:@"client_id"];
    [params setObject:self.clientSecret forKey:@"client_secret"];
    
    
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"register/index"]
                   usingParameters:params
                       withAccount:nil
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       NSLog(@"%@",[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                       if(!error){
                           @try {
                               NSError *parseError;
                               
                               
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"index"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)  successHandler();
                               }else{
                                   if([[responseDictionary objectForKey:@"code"] isEqualToString:@"EC0920"]){
                                       if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                       initWithDomain:@"PNPGenericWebserviceError"
                                                                       code:-6060
                                                                       userInfo:@{@"errors":[responseDictionary objectForKey:@"data"]}]);
                                   }else{
                                       if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                       initWithDomain:@"PNPGenericWebserviceError"
                                                                       code:-6060
                                                                       userInfo:@{@"errors":@[@[[responseDictionary objectForKey:@"code"],[responseDictionary objectForKey:@"message"]]] }]);
                                   }
                                   
                                   
                                   
                                   
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                           
                       }
                   }];
    
    
    
}

-(void) resendTokenWithSuccessCallback:(NSString *)prefix
                                 phone:(NSString *)phone
                   withSuccessCallback:(PnPSuccessHandler)successHandler
                      andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"register/resend_token"]
                   usingParameters:@{@"prefix":prefix,@"phone":phone,@"client_id":self.clientId,@"client_secret":self.clientSecret}
                       withAccount:nil
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               
                               
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"resend_token"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)  successHandler();
                               }else{
                                   if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                   initWithDomain:@"PNPGenericWebserviceError"
                                                                   code:-6060
                                                                   userInfo:responseDictionary ]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                           
                       }
                   }];
    
    
}

-(void) confirmUserWithToken:(NSString *)token
         withSuccessCallback:(PnPSuccessHandler)successHandler
            andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"register/validate_user"]
                   usingParameters:@{@"token":token}
                       withAccount:nil
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               
                               
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"validate_user"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)  successHandler();
                               }else{
                                   if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                   initWithDomain:@"PNPGenericWebserviceError"
                                                                   code:-6060
                                                                   userInfo:responseDictionary ]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                           
                       }
                   }];
    
}

-(void) registerDevice:(NSData *)deviceToken
   withSuccessCallback:(PnPSuccessHandler)successHandler
      andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    
    NSString *ds = [NSString stringWithFormat:@"%@",deviceToken];
    ds = [ds stringByReplacingOccurrencesOfString:@" " withString:@""];
    ds = [ds stringByReplacingOccurrencesOfString:@"<" withString:@""];
    ds = [ds stringByReplacingOccurrencesOfString:@">" withString:@""];
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"devices/register"]
                   usingParameters:@{@"token":ds,@"type":@"IOS"}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               
                               
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"register"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)  successHandler();
                               }else{
                                   if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                   initWithDomain:@"PNPGenericWebserviceError"
                                                                   code:-6060
                                                                   userInfo:responseDictionary ]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                           
                       }
                   }];
    
    
}

-(void) requestRecoverPinWithSuccessCallback:(PnPSuccessHandler)successHandler
                            andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"users/recover_pin"]
                   usingParameters:nil
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               
                               
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"recover_pin"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)  successHandler();
                               }else{
                                   if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                   initWithDomain:@"PNPGenericWebserviceError"
                                                                   code:-6060
                                                                   userInfo:responseDictionary]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                           
                       }
                   }];
    
}

-(void) recoverPinwithNewPin:(NSString *)pin
                    andToken:(NSString *)token
         withSuccessCallback:(PnPSuccessHandler)successHandler
            andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"users/confirm_pin"]
                   usingParameters:@{@"token":token,@"pin":pin}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               
                               
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"confirm_pin"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)  successHandler();
                               }else{
                                   if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                   initWithDomain:@"PNPGenericWebserviceError"
                                                                   code:-6060
                                                                   userInfo:responseDictionary ]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                           
                       }
                   }];
    
}

-(void) requestRecoverPassword:(NSString *)email
           withSuccessCallback:(PnPSuccessHandler)successHandler
              andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"register/recover_password"]
                   usingParameters:@{@"mail":email,@"client_id":self.clientId,@"client_secret":self.clientSecret}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       NSLog(@"Responsedata %@",[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                       if(!error){
                           @try {
                               NSError *parseError;
                               
                               
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"recover_password"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)  successHandler();
                               }else{
                                   if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                   initWithDomain:@"PNPGenericWebserviceError"
                                                                   code:-6060
                                                                   userInfo:responseDictionary ]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                           
                       }
                   }];
    
}

-(void) recoverPassword:(NSString *)password
                  token:(NSString *)token
    withSuccessCallback:(PnPSuccessHandler)successHandler
       andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"register/confirm_password"]
                   usingParameters:@{@"password":password,@"client_id":self.clientId,@"client_secret":self.clientSecret,@"token":token}
                       withAccount:nil
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               
                               
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"confirm_password"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)  successHandler();
                               }else{
                                   if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                   initWithDomain:@"PNPGenericWebserviceError"
                                                                   code:-6060
                                                                   userInfo:responseDictionary ]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                           
                       }
                   }];
    
}


-(void) changePhone:(NSString *)prefix
              phone:(NSString *)phone
                pin:(NSString *)pin
         confirmUrl:(NSURL *)confirmUrl
withSuccessCallback:(PnPSuccessHandler)successHandler
   andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    if(prefix == nil || phone == nil){
        successHandler();
        return;
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"users/change_phone"]
                   usingParameters:@{@"prefix":prefix,@"phone":phone,@"url_confirm":[confirmUrl absoluteString],@"pin":pin}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               
                               
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"change_phone"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)  successHandler();
                               }else{
                                   if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                   initWithDomain:@"PNPGenericWebserviceError"
                                                                   code:-6060
                                                                   userInfo:responseDictionary]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                           
                       }
                   }];
}

-(void) confirmChangePhone:(NSString *)token
       withSuccessCallback:(PnPSuccessHandler)successHandler
          andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"register/confirm_phone"]
                   usingParameters:@{@"hash":token}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               
                               
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"confirm_phone"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)  successHandler();
                               }else{
                                   if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                   initWithDomain:@"PNPGenericWebserviceError"
                                                                   code:-6060
                                                                   userInfo:responseDictionary]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                           
                       }
                   }];
}

-(void) getUserValidationStatusWithSuccessCallback:(PnpUserValidationSuccessHandler) successHandler
                                  andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"users/validation_status"]
                   usingParameters:nil
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"validation_status"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   NSDictionary * data = [responseDictionary objectForKey:@"data"];
                                   NSDictionary * files = [data objectForKey:@"files"];
                                   PNPUserValidationItem *front = [[PNPUserValidationItem alloc] initWithStatus:[files objectForKey:@"dni_front"]];
                                   PNPUserValidationItem *back = [[PNPUserValidationItem alloc] initWithStatus:[files objectForKey:@"dni_back"]];
                                   PNPUserValidationItem *bill = [[PNPUserValidationItem alloc] initWithStatus:[files objectForKey:@"bill"]];
                                   PNPUserValidationItem *agreement = [[PNPUserValidationItem alloc] initWithStatus:[files objectForKey:@"agreement"]];
                                   PNPUserValidation *validation = [[PNPUserValidation alloc] initWithStatus:[[data objectForKey:@"status"] boolValue]
                                                                                                  andFrontId:front
                                                                                                      rearId:back
                                                                                                        bill:bill
                                                                                                andAgreement:agreement];
                                   
                                   
                                   if(successHandler)  successHandler(validation);
                               }else{
                                   if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                   initWithDomain:@"PNPGenericWebserviceError"
                                                                   code:-6060
                                                                   userInfo:responseDictionary]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                           
                       }
                   }];
}

-(void) uploadIdCard:(UIImage *)front
             andBack:(UIImage *)back
 withSuccessCallback:(PnPSuccessHandler)successHandler
    andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    __block BOOL uploadedOtherFile = NO;
    __block BOOL calledBack = NO;
    
    void (^callback)(NSURLResponse * ,NSData *,NSError *);
    callback  = ^(NSURLResponse *response, NSData *responseData, NSError *error){
        if(!error){
            @try {
                NSError *parseError;
                NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                    options:0
                                                                                      error:&parseError]
                                                    objectForKey:@"upload_file"];
                if(parseError){
                    if(errorHandler && !calledBack) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                    calledBack = YES;
                    
                }else{
                    if([[responseDictionary objectForKey:@"success"] boolValue]){
                        if(uploadedOtherFile){
                            if(successHandler)  successHandler();
                        }
                        uploadedOtherFile = YES;
                    }else{
                        if(errorHandler && !calledBack)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                       initWithDomain:@"PNPGenericWebserviceError"
                                                                       code:-6060
                                                                       userInfo:nil]);
                        calledBack = YES;
                    }
                }
            }
            @catch (NSException *exception) {
                NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                if(errorHandler && !calledBack) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                calledBack = YES;
            }
        }else{
            if(errorHandler && !calledBack) errorHandler([self handleErrors:error]);
            calledBack = YES;
        }
    };
    
    NSData *imageDataFront = UIImageJPEGRepresentation(front, 0.5);
    NSString *base64encodedImageFront = [imageDataFront base64EncodedString];
    
    NSData *imageDataBack = UIImageJPEGRepresentation(front, 0.5);
    NSString *base64encodedImageBack = [imageDataBack base64EncodedString];
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"users/upload_file"]
                   usingParameters:@{@"file":base64encodedImageFront,@"type":@"dni_front"}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:callback];
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"users/upload_file"]
                   usingParameters:@{@"file":base64encodedImageBack,@"type":@"dni_back"}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:callback];
    
    
}




-(void) changePassword:(NSString * ) password
            toPassword:(NSString *) newpassword
   withSuccessCallback:(PnPSuccessHandler) successHandler
      andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    [self changeCredential:password
              toCredential:newpassword
                      type:@"pass"
       withSuccessCallback:successHandler
          andErrorCallback:errorHandler];
    
}

-(void) changePin:(NSString * ) pin
            toPin:(NSString *) newpin
withSuccessCallback:(PnPSuccessHandler) successHandler
 andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    [self changeCredential:pin
              toCredential:newpin
                      type:@"pin"
       withSuccessCallback:successHandler
          andErrorCallback:errorHandler];
    
}


-(void) changeCredential:(NSString * ) credential
            toCredential:(NSString *) newcredential
                    type:(NSString *) type
     withSuccessCallback:(PnPSuccessHandler) successHandler
        andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"users/change_credential"]
                   usingParameters:@{@"old_credential":credential,@"new_credential":newcredential,@"confirm_credential":newcredential,@"type":type}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"change_credential"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)  successHandler();
                               }else{
                                   if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                   initWithDomain:@"PNPGenericWebserviceError"
                                                                   code:-6060
                                                                   userInfo:responseDictionary]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                           
                       }
                   }];
    
}

-(void) editUserSetName:(NSString *) name
                surname:(NSString *) surname
                  email:(NSString *) email
                 prefix:(NSString *) prefix
                  phone:(NSString *) phone
                withPin:(NSString *) pin
             confirmUrl:(NSURL *) url
    withSuccessCallback:(PnPSuccessHandler) successHandler
       andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    __block BOOL hasCalledBack = NO;
    __block BOOL firstFinished = NO;
    
    [self changePhone:prefix phone:phone pin:pin confirmUrl:url withSuccessCallback:^{
        if(successHandler && firstFinished) successHandler();
        firstFinished = YES;
    } andErrorCallback:^(NSError *error) {
        if(errorHandler && !hasCalledBack) errorHandler(error);
        hasCalledBack = YES;
    }];
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    if(name != nil) [params setObject:name forKey:@"name"];
    if(surname != nil)[params setObject:surname forKey:@"surname"];
    if(email != nil) [params setObject:email forKey:@"email"];
    [params setObject:pin forKey:@"pin"];
    
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"users/edit"]
                   usingParameters:params
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"edit"];
                               if(parseError){
                                   if(errorHandler && !hasCalledBack) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                                        code:[parseError code]
                                                                                                                    userInfo:parseError.userInfo]);
                                   hasCalledBack = YES;
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler && firstFinished)  successHandler();
                                   firstFinished = YES;
                               }else{
                                   if(errorHandler && !hasCalledBack)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                                     initWithDomain:@"PNPGenericWebserviceError"
                                                                                     code:-6060
                                                                                     userInfo:responseDictionary]);
                                   hasCalledBack = YES;
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler && !hasCalledBack) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                                        code:-2020
                                                                                                                    userInfo:nil]);
                               hasCalledBack = YES;
                               
                           }
                       }else{
                           if(errorHandler && !hasCalledBack) errorHandler([self handleErrors:error]);
                           hasCalledBack = YES;
                           
                       }
                   }];
    
}


#pragma mark - Credit cards

-(void) getCreditCardsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                         andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"creditCards/get_all"]
                   usingParameters:nil
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"get_all"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   NSDictionary * data = [responseDictionary objectForKey:@"data"];
                                   NSMutableArray *cards = [NSMutableArray new];
                                   
                                   for(NSDictionary *c in data){
                                       PNPCreditCard *card = [[PNPCreditCard alloc] initWithIdentifier:[c objectForKey:@"id"] number:[c objectForKey:@"number"] year:[c objectForKey:@"year"] month:[c objectForKey:@"month"] alias:[c objectForKey:@"alias"] type:[c objectForKey:@"type"] isDefault:[[c objectForKey:@"default"] boolValue]];
                                       [cards addObject:card];
                                   }
                                   if(successHandler)  successHandler(cards);
                               }else{
                                   if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                   initWithDomain:@"PNPGenericWebserviceError"
                                                                   code:-6060
                                                                   userInfo:responseDictionary]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                           
                       }
                   }];
    
}

-(void) createCard:(PNPCreditCard *) card
withSuccessCallback:(PnPSuccessHandler) successHandler
  andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"creditCards/add"]
                   usingParameters:@{@"number":card.number,@"month":card.month,@"year":card.year,@"alias":card.alias,@"default":[NSNumber numberWithBool:card.isDefault]}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"add"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)  successHandler();
                               }else{
                                   if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                   initWithDomain:@"PNPGenericWebserviceError"
                                                                   code:-6060
                                                                   userInfo:responseDictionary]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                           
                       }
                   }];
}

-(void) updateCard:(PNPCreditCard *) card
withSuccessCallback:(PnPSuccessHandler) successHandler
  andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"creditCards/edit"]
                   usingParameters:@{@"id":card.identifier,@"month":card.month,@"year":card.year,@"alias":card.alias,@"default":[NSNumber numberWithBool:card.isDefault]}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"edit"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)  successHandler();
                               }else{
                                   if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                   initWithDomain:@"PNPGenericWebserviceError"
                                                                   code:-6060
                                                                   userInfo:responseDictionary]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                           
                       }
                   }];
    
    
}

-(void) deleteCard: (PNPCreditCard *) card
withSuccessCallback:(PnPSuccessHandler) successHandler
  andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"creditCards/delete"]
                   usingParameters:@{@"id":card.identifier}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"delete"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }

                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)  successHandler();
                               }else{
                                   if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                   initWithDomain:@"PNPGenericWebserviceError"
                                                                   code:-6060
                                                                   userInfo:responseDictionary]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                           
                       }
                   }];
    
}

-(void) rechargeWithCreditCard:(PNPCreditCard *)card
                           cvv:(NSString *) cvv
                        amount:(NSNumber *)amount
           withSuccessCallback:(PnPSuccessHandler)successHandler
         secureRechargeHandler:(PnPSecureRechargeHandler)secureRecharge
                 errorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    
    amount = [NSNumber numberWithDouble:[amount doubleValue] *100];
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"wallets/recharge"]
                   usingParameters:@{@"creditcard_id":card.identifier,@"cvv":cvv,@"amount":amount}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"recharge"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if([[responseDictionary objectForKey:@"code"] isEqualToString:@"EC1004"]){
                                       NSURL * url = [NSURL URLWithString:[responseDictionary objectForKey:@"data"]];
                                       if(secureRecharge) secureRecharge(url);
                                   }else{
                                       if(successHandler)  successHandler();
                                   }
                               }else{
                                   if(errorHandler)  errorHandler([[PNPGenericWebserviceError alloc]
                                                                   initWithDomain:@"PNPGenericWebserviceError"
                                                                   code:-6060
                                                                   userInfo:responseDictionary]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                               
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                           
                       }
                   }];

    
    
    
}



#pragma mark - Notification Methods

-(void) getNotificationsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler)successHandler
                           andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"notifications/get"]
                   usingParameters:nil
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
                               [nf setNumberStyle:NSNumberFormatterNoStyle];
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"get"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
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
                                   if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                              code:-6060
                                                                                                          userInfo:nil]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s -> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                       }
                   }];
}

-(void) deleteNotifications:(NSSet *) notifications withSuccessCallback:(PnPSuccessHandler)successHandler
           andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    
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
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           NSError *parseError;
                           NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                               options:0
                                                                                                 error:&parseError]
                                                               objectForKey:@"markAsRead"];
                           if(parseError){
                               if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                  code:[parseError code]
                                                                                              userInfo:parseError.userInfo]);
                               return;
                           }
                           if([responseDictionary objectForKey:@"success"]){
                               if(successHandler) successHandler();
                           }else{
                               if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                         code:-6060
                                                                                                     userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
}

-(void) deleteNotification:(PNPNotification *) notification withSuccessCallback:(PnPSuccessHandler)successHandler
          andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    [self deleteNotifications:[NSSet setWithObjects:notification, nil] withSuccessCallback:successHandler andErrorCallback:errorHandler];
}


#pragma mark - Pango Methods

-(void) getPangosWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                    andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    
    
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"pangos/get"]
                   usingParameters:nil
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
                               [nf setNumberStyle:NSNumberFormatterNoStyle];
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"get"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
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
                                       PNPPango *p = [[PNPPango alloc] initWithIdentifier:[nf numberFromString:[d objectForKey:@"id"]]
                                                                                    alias:[d objectForKey:@"alias"]
                                                                                   serial:[d objectForKey:@"serial"]
                                                                                   status:[d objectForKey:@"status"]
                                                                                  creator:[d objectForKey:@"creator"]
                                                                             currencyCode:[d objectForKey:@"currency"]
                                                                                   amount:amount
                                                                                    limit:limit
                                                                                  created:[df dateFromString:[d objectForKey:@"created"]]];
                                       [pangos addObject:p];
                                   }
                                   NSSortDescriptor *sortDescriptor;
                                   sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"created"
                                                                                ascending:NO];
                                   NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                                   pangos = [NSMutableArray arrayWithArray:[pangos sortedArrayUsingDescriptors:sortDescriptors]];
                                   if(successHandler) successHandler(pangos);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                             code:-6060
                                                                                                         userInfo:nil]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"Exception throwed at getPangos: %@",exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
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
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"pangos/get"]
                   usingParameters:@{@"id":identifier}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
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
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"get"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
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
                                       PNPPango *p = [[PNPPango alloc] initWithIdentifier:[nf numberFromString:[d objectForKey:@"id"]]
                                                                                    alias:[d objectForKey:@"alias"]
                                                                                   serial:[d objectForKey:@"serial"]
                                                                                   status:[d objectForKey:@"status"]
                                                                                  creator:[d objectForKey:@"creator"]
                                                                             currencyCode:[d objectForKey:@"currency"]
                                                                                   amount:amount
                                                                                    limit:limit
                                                                                  created:[df dateFromString:[d objectForKey:@"created"]]];
                                       [pangos addObject:p];
                                   }
                                   if(successHandler) successHandler([pangos objectAtIndex:0]);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                             code:-6060
                                                                                                         userInfo:nil]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"Exception throwed at getPango: %@",exception);
                               if(errorHandler)errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                     code:-2020
                                                                                                 userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                       
                   }];
}


-(void) updatePangoAlias:(PNPPango *) pango
     withSuccessCallback:(PnPSuccessHandler) successHandler
        andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    if(pango == nil){
        if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPWebserviceError"
                                                                                   code:-6060
                                                                               userInfo:@{@"error":@"Pango cannot be nil"}]);
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"pangos/edit_alias"]
                   usingParameters:@{@"id":pango.identifier,@"alias":pango.alias}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           NSError *parseError;
                           NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                               options:0
                                                                                                 error:&parseError]
                                                               objectForKey:@"edit_alias"];
                           if(parseError){
                               if(errorHandler)errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                 code:[parseError code]
                                                                                             userInfo:parseError.userInfo]);
                               return;
                           }
                           if([responseDictionary objectForKey:@"success"]){
                               if(successHandler) successHandler();
                           }else{
                               if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                         code:-6060
                                                                                                     userInfo:[responseDictionary
                                                                                                               objectForKey:@"message"]]);
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                       }
                   }];
    
    
}
-(void) changeStatusForPango:(PNPPango *) pango
         withSuccessCallback:(PnPSuccessHandler)successHandler
            andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    
    if(pango == nil){
        if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPWebserviceError"
                                                                                   code:-6060
                                                                               userInfo:@{@"error":@"Pango cannot be nil"}]);
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
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           NSError *parseError;
                           NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                               options:0
                                                                                                 error:&parseError]
                                                               objectForKey:resourceParam];
                           if(parseError){
                               if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                  code:[parseError code]
                                                                                              userInfo:parseError.userInfo]);
                               return;
                           }
                           if([responseDictionary objectForKey:@"success"]){
                               if(successHandler)successHandler();
                           }else{
                               if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                          code:-6060
                                                                                                      userInfo:[responseDictionary
                                                                                                                objectForKey:@"message"]]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
}

-(void) cancelPango:(PNPPango *) pango
withSuccessCallback:(PnPSuccessHandler)successHandler
   andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    if(pango == nil){
        if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPWebserviceError"
                                                                                   code:-6060
                                                                               userInfo:@{@"error":@"Pango cannot be nil"}]);
        return;
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"pangos/cancel"]
                   usingParameters:@{@"id":pango.identifier}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           NSError *parseError;
                           NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                               options:0
                                                                                                 error:&parseError]
                                                               objectForKey:@"cancel"];
                           if(parseError){
                               if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                  code:[parseError code]
                                                                                              userInfo:parseError.userInfo]);
                               return;
                           }
                           if([responseDictionary objectForKey:@"success"]){
                               if(successHandler)successHandler();
                           }else{
                               if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                         code:-6060
                                                                                                     userInfo:[responseDictionary
                                                                                                               objectForKey:@"message"]]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
}


-(void) unlinkPango:(PNPPango *) pango
withSuccessCallback:(PnPSuccessHandler)successHandler
   andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    if(pango == nil){
        if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPWebserviceError"
                                                                                   code:-6060
                                                                               userInfo:@{@"error":@"Pango cannot be nil"}]);
        return;
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"pangos/unlink_pango"]
                   usingParameters:@{@"id":pango.identifier}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           NSError *parseError;
                           NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                               options:0
                                                                                                 error:&parseError]
                                                               objectForKey:@"unlink_pango"];
                           if(parseError){
                               if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                  code:[parseError code]
                                                                                              userInfo:parseError.userInfo]);
                               return;
                           }
                           if([responseDictionary objectForKey:@"success"]){
                               if(successHandler)successHandler();
                           }else{
                               if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                         code:-6060
                                                                                                     userInfo:[responseDictionary
                                                                                                               objectForKey:@"message"]]);
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
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    if(pango == nil){
        if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPWebserviceError"
                                                                                  code:-6060
                                                                              userInfo:@{@"error":@"Pango cannot be nil"}]);
        return;
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"pangos/move_in"]
                   usingParameters:@{@"id":pango.identifier,@"amount":[NSString stringWithFormat:@"%f",[amount doubleValue] *100]}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           NSError *parseError;
                           NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                               options:0
                                                                                                 error:&parseError]
                                                               objectForKey:@"move_in"];
                           if(parseError){
                               if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                  code:[parseError code]
                                                                                              userInfo:parseError.userInfo]);
                               return;
                           }
                           if([responseDictionary objectForKey:@"success"]){
                               if(successHandler)successHandler();
                           }else{
                               if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                          code:-6060
                                                                                                      userInfo:[responseDictionary
                                                                                                                objectForKey:@"message"]]);
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
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    if(pango == nil){
        if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPWebserviceError"
                                                                                   code:-6060
                                                                               userInfo:@{@"error":@"Pango cannot be nil"}]);
        return;
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"pangos/move_out"]
                   usingParameters:@{@"id":pango.identifier,@"amount":[NSString stringWithFormat:@"%f",[amount doubleValue] *100]}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           NSError *parseError;
                           NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                               options:0
                                                                                                 error:&parseError]
                                                               objectForKey:@"move_out"];
                           if(parseError){
                               if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                  code:[parseError code]
                                                                                              userInfo:parseError.userInfo]);
                               return;
                           }
                           if([responseDictionary objectForKey:@"success"]){
                               if(successHandler)successHandler();
                           }else{
                               if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                         code:-6060
                                                                                                     userInfo:[responseDictionary
                                                                                                               objectForKey:@"message"]]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
    
}

-(void) getPangoMovements:(PNPPango *) pango
      withSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
         andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    if(pango == nil){
        if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPWebserviceError"
                                                                                   code:-6060
                                                                               userInfo:@{@"error":@"Pango cannot be nil"}]);
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"pangos/movements"]
                   usingParameters:@{@"pango_id":pango.identifier}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
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
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"movements"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
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
                                       
                                       if([type isEqualToString:PNPPangoMovementTypeCommerceToPango] ||
                                          [type isEqualToString:PNPPangoMovementTypePangoChargeback] ){
                                           
                                           classString = @"PNPPangoMovementIncome";
                                           emitter = [[PNPPangoMovementCommerce alloc] initWithIdentifier:[nf numberFromString:[emitterDictionary objectForKey:@"id"]]
                                                                                                     name:[emitterDictionary objectForKey:@"name"]
                                                                                               andSurname:[emitterDictionary objectForKey:@"surname"]];
                                           receiver = [[PNPPangoMovementPango alloc] initWithIdentifier:[nf numberFromString:[receiverDictionary objectForKey:@"id"]]
                                                                                               andAlias:[receiverDictionary objectForKey:@"alias"]];
                                       }
                                       else if([type isEqualToString:PNPPangoMovementTypePangoRechargeChargeback] ||
                                               [type isEqualToString:PNPPangoMovementTypePangoToCommerce]){
                                           
                                           classString = @"PNPPangoMovementExpense";
                                           receiver = [[PNPPangoMovementCommerce alloc] initWithIdentifier:[nf numberFromString:[receiverDictionary objectForKey:@"id"]]
                                                                                                      name:[receiverDictionary objectForKey:@"name"]
                                                                                                andSurname:[receiverDictionary objectForKey:@"surname"]];
                                           emitter = [[PNPPangoMovementPango alloc] initWithIdentifier:[nf numberFromString:[emitterDictionary objectForKey:@"id"]]
                                                                                              andAlias:[emitterDictionary objectForKey:@"alias"]];
                                           
                                       }
                                       else if([type isEqualToString:PNPPangoMovementTypePangoToWallet]){
                                           
                                           classString = @"PNPPangoMovementExpense";
                                           receiver = [[PNPPangoMovementWallet alloc] initWithIdentifier:[nf numberFromString:[receiverDictionary objectForKey:@"id"]]];
                                           emitter = [[PNPPangoMovementPango alloc] initWithIdentifier:[nf numberFromString:[emitterDictionary objectForKey:@"id"]]
                                                                                              andAlias:[emitterDictionary objectForKey:@"alias"]];
                                       }
                                       else if([type isEqualToString:PNPPangoMovementTypeWalletToPango]){
                                           
                                           classString = @"PNPPangoMovementIncome";
                                           receiver = [[PNPPangoMovementPango alloc] initWithIdentifier:[nf numberFromString:[receiverDictionary objectForKey:@"id"]]
                                                                                               andAlias:[receiverDictionary objectForKey:@"alias"]];
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
                                   if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                              code:-6060
                                                                                                          userInfo:nil]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"Exception throwed at getPangoMovements: %@",exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                       }
                       
                   }];
    
    
}

#pragma mark - Send Payment methods

-(void) getSendTransactionCommissionForAmount:(NSNumber *) amount
                                   withPrefix:(NSString *) prefix
                                     andPhone:(NSString *)phone
                          withSuccessCallback:(PnPNSNumberSucceddHandler) successHandler
                             andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    amount = [NSNumber numberWithDouble:([amount doubleValue] * 100)];
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"transactions/get_commission"]
                   usingParameters:@{@"controller":@"transactions",@"method":@"send",@"prefix":prefix,@"phone":phone,@"amount":amount}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"get_commission"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc]
                                                                   initWithDomain:parseError.domain
                                                                   code:[parseError code]
                                                                   userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([responseDictionary objectForKey:@"success"]){
                                   if(successHandler)successHandler([self clearAmount:[responseDictionary objectForKey:@"data"]]);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:[responseDictionary objectForKey:@"message"]]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc]
                                                              initWithDomain:@"PNPMalformedJson"
                                                              code:-2020
                                                              userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
    
    
}

-(void) sendTransactionWithAmount:(NSNumber *) amount
                         toPrefix:(NSString *) prefix
                            phone:(NSString *) phone
                              pin:(NSString *) pin
              withSuccessCallback:(PnPSuccessHandler) successHandler
                 andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    amount = [NSNumber numberWithDouble:([amount doubleValue] * 100)];
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"transactions/send"]
                   usingParameters:@{@"amount":amount,@"prefix":prefix,@"phone":phone,@"pin":pin}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"send"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc]
                                                                   initWithDomain:parseError.domain
                                                                   code:[parseError code]
                                                                   userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([responseDictionary objectForKey:@"success"]){
                                   if(successHandler) successHandler();
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:[responseDictionary objectForKey:@"message"]]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc]
                                                              initWithDomain:@"PNPMalformedJson"
                                                              code:-2020
                                                              userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
    
}

-(void) getTransactionReceiverWithPrefix:(NSString *) prefix
                                andPhone:(NSString *) phone
                      andSuccessCallBack:(PnPTransactionReceiverSuccessHandler) successHandler
                        andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"users/get_user"]
                   usingParameters:@{@"prefix":prefix,@"phone":phone}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"get_user"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   NSDictionary *dataDic = [responseDictionary objectForKey:@"data"];
                                   
                                   PNPTransactionReceiverUser *receiver = [[PNPTransactionReceiverUser alloc]
                                                                           initWithName:[dataDic objectForKey:@"name"]
                                                                           prefix:prefix phone:phone
                                                                           email:[dataDic objectForKey:@"email"]
                                                                           ];
                                   
                                   successHandler(receiver);
                                   
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:[responseDictionary objectForKey:@"message"]]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc] initWithDomain:@"PNPMalformedJson"
                                                                                                      code:-2020
                                                                                                  userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
    
    
    
    
}

#pragma mark - Transaction methods

-(void) getTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                          andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    __block int counter = 0;
    NSMutableArray *transactionArray = [NSMutableArray new];
    __block BOOL calledBack = NO;
    
    [self getSentTransactionsWithSuccessCallback:^(NSArray *data) {
        [transactionArray addObjectsFromArray:data];
        counter+= 1;
        if(counter == 3){
            if(successHandler) successHandler(transactionArray);
        }
    } andErrorCallback:^(NSError *error) {
        if(errorHandler && !calledBack) {
            errorHandler(error);
            calledBack = YES;
        }
    }];
    
    [self getReceivedTransactionsWithSuccessCallback:^(NSArray *data) {
        [transactionArray addObjectsFromArray:data];
        counter+= 1;
        if(counter == 3){
            if(successHandler) successHandler(transactionArray);
        }
    } andErrorCallback:^(NSError *error) {
        if(errorHandler && !calledBack) {
            errorHandler(error);
            calledBack = YES;
        }
    }];
    
    [self getPendingTransactionsWithSuccessCallback:^(NSArray *data) {
        [transactionArray addObjectsFromArray:data];
        counter+= 1;
        if(counter == 3){
            if(successHandler) successHandler(transactionArray);
        }
    } andErrorCallback:^(NSError *error) {
        if(errorHandler && !calledBack) {
            errorHandler(error);
            calledBack = YES;
        }
    }];
    
}

-(void) getReceivedTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                                  andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"transactions/revenue"]
                   usingParameters:nil
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"revenue"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   NSDateFormatter *df = [[NSDateFormatter alloc] init];
                                   [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                                   [df setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Madrid"]];
                                   NSArray *dataArray = [[responseDictionary objectForKey:@"data"] objectForKey:@"results"];
                                   NSMutableArray *PNPTransactionsArray = [NSMutableArray new];
                                   for (NSDictionary *d in dataArray){
                                       NSDictionary *emitter = [d objectForKey:@"emitter"];
                                       NSDictionary *emitterData = [emitter objectForKey:@"data"];
                                       NSDictionary *currency = [d objectForKey:@"currency"];
                                       NSString *emitterType = [emitter objectForKey:@"type"];
                                       NSNumber *amount = [self clearAmount:[d objectForKey:@"amount"]];
                                       NSDate *created = [df dateFromString:[d objectForKey:@"created"]];
                                       PNPTransactionEntity *entity;
                                       if([emitterType isEqualToString:@"User"]){
                                           entity = [[PNPTransactionEmitterUser alloc]
                                                     initWithName:[emitterData objectForKey:@"name"]
                                                     prefix:[emitterData objectForKey:@"prefix"]
                                                     phone:[emitterData objectForKey:@"phone"]
                                                     email:nil
                                                     avatarUrl:[self generateAvatarUrlFromPrefix:[emitterData objectForKey:@"prefix"]
                                                                                        andPhone:[emitterData objectForKey:@"phone"]]];
                                           
                                       }else if([emitterType isEqualToString:@"Pango"]){
                                           entity = [[PNPTransactionEmitterPango alloc] init];
                                       }else if([emitterType isEqualToString:@"HalCash"]){
                                           entity = [[PNPTransactionEmitterHalcash alloc] init];
                                       }
                                       else{
                                           NSLog(@"No implementation for emitter type %@",emitterType);
                                           if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                         initWithDomain:@"PNPGenericWebserviceError"
                                                                         code:-6060
                                                                         userInfo:@{
                                                                                    @"description":
                                                                                        @"NO Implementation for this emitter type."
                                                                                    }]);
                                           return;
                                       }
                                       
                                       [PNPTransactionsArray addObject:[[PNPTransactionReceived alloc]
                                                                        initWithIdentifier:[d objectForKey:@"id"]
                                                                        amount:amount
                                                                        currencyCode:[currency objectForKey:@"code"]
                                                                        currencySymbol:[currency objectForKey:@"symbol"]
                                                                        concept:[d objectForKey:@"concept"]
                                                                        status:[d objectForKey:@"status"]
                                                                        created:created
                                                                        andEntity:entity]];
                                       
                                   }
                                   if(successHandler)successHandler(PNPTransactionsArray);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:[responseDictionary objectForKey:@"message"]]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc]
                                                              initWithDomain:@"PNPMalformedJson"
                                                              code:-2020
                                                              userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
    
}

-(void) getSentTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                              andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"transactions/payments"]
                   usingParameters:nil
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"payments"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   NSDateFormatter *df = [[NSDateFormatter alloc] init];
                                   [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                                   [df setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Madrid"]];
                                   NSArray *dataArray = [[responseDictionary objectForKey:@"data"] objectForKey:@"results"];
                                   NSMutableArray *PNPTransactionsArray = [NSMutableArray new];
                                   for (NSDictionary *d in dataArray){
                                       NSDictionary *receiver = [d objectForKey:@"receiver"];
                                       NSDictionary *receiverData = [receiver objectForKey:@"data"];
                                       NSDictionary *currency = [d objectForKey:@"currency"];
                                       NSString *receiverType = [receiver objectForKey:@"type"];
                                       NSNumber *amount = [self clearAmount:[d objectForKey:@"amount"]];
                                       NSDate *created = [df dateFromString:[d objectForKey:@"created"]];
                                       PNPTransactionEntity *entity;
                                       if([receiverType isEqualToString:@"User"]){
                                           entity = [[PNPTransactionReceiverUser alloc]
                                                     initWithName:[receiverData objectForKey:@"name"]
                                                     prefix:[receiverData objectForKey:@"prefix"]
                                                     phone:[receiverData objectForKey:@"phone"]
                                                     email:nil];
                                           
                                           
                                       }else if([receiverType isEqualToString:@"UnregisteredUser"]){
                                           entity = [[PNPTransactionReceiverUnregistered alloc] initWithPrefix:[receiverData objectForKey:@"prefix"]
                                                                                                      andPhone:[receiverData objectForKey:@"phone"]];
                                           
                                       }else if([receiverType isEqualToString:@"Pango"]){
                                           entity = [[PNPTransactionEmitterPango alloc] init];
                                       }else if([receiverType isEqualToString:@"HalCash"]){
                                           entity = [[PNPTransactionReceiverHalcash alloc] init];
                                       }else{
                                           NSLog(@"No implementation for receiver type %@",receiverType);
                                           if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                         initWithDomain:@"PNPGenericWebserviceError"
                                                                         code:-6060
                                                                         userInfo:@{
                                                                                    @"description":
                                                                                        @"NO Implementation for this receiver type."
                                                                                    }]);
                                           return;
                                       }
                                       
                                       [PNPTransactionsArray addObject:[[PNPTransactionReceived alloc]
                                                                        initWithIdentifier:[d objectForKey:@"id"]
                                                                        amount:amount
                                                                        currencyCode:[currency objectForKey:@"code"]
                                                                        currencySymbol:[currency objectForKey:@"symbol"]
                                                                        concept:[d objectForKey:@"concept"]
                                                                        status:[d objectForKey:@"status"]
                                                                        created:created
                                                                        andEntity:entity]];
                                       
                                   }
                                   if(successHandler)successHandler(PNPTransactionsArray);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:[responseDictionary objectForKey:@"message"]]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc]
                                                              initWithDomain:@"PNPMalformedJson"
                                                              code:-2020
                                                              userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
    
}

-(void) getPendingTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                                 andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"transactions/pending"]
                   usingParameters:nil
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"pending"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   NSDateFormatter *df = [[NSDateFormatter alloc] init];
                                   [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                                   [df setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Madrid"]];
                                   NSArray *dataArray = [[responseDictionary objectForKey:@"data"] objectForKey:@"results"];
                                   NSMutableArray *PNPTransactionsArray = [NSMutableArray new];
                                   for (NSDictionary *d in dataArray){
                                       NSDictionary *receiver = [d objectForKey:@"receiver"];
                                       NSDictionary *receiverData = [receiver objectForKey:@"data"];
                                       NSDictionary *currency = [d objectForKey:@"currency"];
                                       NSString *receiverType = [receiver objectForKey:@"type"];
                                       NSNumber *amount = [self clearAmount:[d objectForKey:@"amount"]];
                                       NSDate *created = [df dateFromString:[d objectForKey:@"created"]];
                                       PNPTransactionEntity *entity;
                                       if([receiverType isEqualToString:@"UnregisteredUser"]){
                                           entity = [[PNPTransactionReceiverUnregistered alloc]
                                                     initWithPrefix:[receiverData objectForKey:@"prefix"]
                                                     andPhone:[receiverData objectForKey:@"phone"]];
                                           
                                           
                                       }else{
                                           NSLog(@"No implementation for receiver type %@",receiverType);
                                           if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                         initWithDomain:@"PNPGenericWebserviceError"
                                                                         code:-6060
                                                                         userInfo:@{
                                                                                    @"description":
                                                                                        @"NO Implementation for receiver type."
                                                                                    }]);
                                           return;
                                       }
                                       
                                       [PNPTransactionsArray addObject:[[PNPTransactionReceived alloc]
                                                                        initWithIdentifier:[d objectForKey:@"id"]
                                                                        amount:amount
                                                                        currencyCode:[currency objectForKey:@"code"]
                                                                        currencySymbol:[currency objectForKey:@"symbol"]
                                                                        concept:[d objectForKey:@"concept"]
                                                                        status:[d objectForKey:@"status"]
                                                                        created:created
                                                                        andEntity:entity]];
                                       
                                   }
                                   if(successHandler)successHandler(PNPTransactionsArray);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:[responseDictionary objectForKey:@"message"]]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc]
                                                              initWithDomain:@"PNPMalformedJson"
                                                              code:-2020
                                                              userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
    
}




-(void) cancelPendingTransaction:(PNPTransactionPending *) transaction
             withSuccessCallback:(PnPSuccessHandler) successHandler
                andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"transactions/cancel"]
                   usingParameters: @{@"id":transaction.identifier}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"cancel"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)successHandler();
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:[responseDictionary objectForKey:@"message"]]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc]
                                                              initWithDomain:@"PNPMalformedJson"
                                                              code:-2020
                                                              userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
}


#pragma mark - Payment request methods

-(void) getPaymentRequestsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                             andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"payment_requests/get"]
                   usingParameters:nil
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"get"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   NSDateFormatter *df = [[NSDateFormatter alloc] init];
                                   [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                                   [df setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Madrid"]];
                                   NSArray *dataArray = [[responseDictionary objectForKey:@"data"] objectForKey:@"results"];
                                   NSMutableArray *PNPRequestsArray = [NSMutableArray new];
                                   for (NSDictionary *d in dataArray){
                                       [PNPRequestsArray addObject:[[PNPPaymentRequest alloc]
                                                                    initWithIdentifier:[d objectForKey:@"id"]
                                                                    amount:[self clearAmount:[d objectForKey:@"amount"]]
                                                                    currencySymbol:[d objectForKey:@"currency"]
                                                                    creationDate:[df dateFromString:[d objectForKey:@"date"]]
                                                                    concept:[d objectForKey:@"concept"]
                                                                    prefix:[d objectForKey:@"prefix"]
                                                                    phone:[d objectForKey:@"phone"]
                                                                    name:[d objectForKey:@"name"]]];
                                   }
                                   if(successHandler)successHandler(PNPRequestsArray);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:[responseDictionary objectForKey:@"message"]]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc]
                                                              initWithDomain:@"PNPMalformedJson"
                                                              code:-2020
                                                              userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
}

-(void) cancelPaymentRequest:(PNPPaymentRequest *) request
         withSuccessCallback:(PnPSuccessHandler) successHandler
            andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"payment_requests/cancel"]
                   usingParameters: @{@"id":request.identifier}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"cancel"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)successHandler();
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:[responseDictionary objectForKey:@"message"]]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc]
                                                              initWithDomain:@"PNPMalformedJson"
                                                              code:-2020
                                                              userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
    
}

-(void) confirmPaymentRequest:(PNPPaymentRequest *) request
                          pin:(NSString *) pin
          withSuccessCallback:(PnPSuccessHandler) successHandler
             andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"payment_requests/confirm"]
                   usingParameters: @{@"id":request.identifier,@"pin":pin}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"confirm"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)successHandler();
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:[responseDictionary objectForKey:@"message"]]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc]
                                                              initWithDomain:@"PNPMalformedJson"
                                                              code:-2020
                                                              userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
    
}


-(void) requestPaymentFromPrefix:(NSString *) prefix
                           phone:(NSString *) phone
                     withConcept:(NSString *) concept
                       andAmount:(NSNumber *) amount
             withSuccessCallback:(PnPSuccessHandler) successHandler
                andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    amount = [NSNumber numberWithDouble:([amount doubleValue] *100)];
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"payment_requests/request"]
                   usingParameters: @{@"amount":amount,@"concept":concept,@"prefix":prefix,@"phone":phone}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"request"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)successHandler();
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:[responseDictionary objectForKey:@"message"]]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc]
                                                              initWithDomain:@"PNPMalformedJson"
                                                              code:-2020
                                                              userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
    
}
#pragma mark - Static data

-(void) getCountriesWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                       andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"register/countries"]
                   usingParameters: nil
                       withAccount:nil
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"countries"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   NSArray *dataArray = [responseDictionary objectForKey:@"data"];
                                   NSMutableArray *countries = [NSMutableArray new];
                                   
                                   for(NSDictionary *dataDic in dataArray){
                                       
                                       NSDictionary * country = [dataDic objectForKey:@"Country"];
                                       NSDictionary * currency = [country objectForKey:@"currency"];
                                       [countries addObject:[[PNPCountry alloc] initWithName:[country objectForKey:@"name"]
                                                                                      prefix:[country objectForKey:@"prefix"]
                                                                                        code:[country objectForKey:@"code"]
                                                                              currencySymbol:[currency objectForKey:@"symbol"]
                                                                                currencyCode:[currency objectForKey:@"code"]]];
                                       
                                   }
                                   if(successHandler)successHandler(countries);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:[responseDictionary objectForKey:@"message"]]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc]
                                                              initWithDomain:@"PNPMalformedJson"
                                                              code:-2020
                                                              userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
    
    
    
}


#pragma mark - Halcash Methods

-(void) getHalcashExtractionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                                andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"hal_cash/get"]
                   usingParameters: @{@"date_start":@"2014-01-01"}
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                       
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"get"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               
                               NSDateFormatter *df = [[NSDateFormatter alloc] init];
                               [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                               [df setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Madrid"]];
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   NSArray *dataArray = [responseDictionary objectForKey:@"data"];
                                   NSMutableArray *extractions = [NSMutableArray new];
                                   for(NSDictionary *dataDic in dataArray){
                                       PNPHalcashExtraction *e = [[PNPHalcashExtraction alloc]
                                                                  initWithIdentifier:[dataDic objectForKey:@"id"]
                                                                  amount:[self clearAmount:[dataDic objectForKey:@"amount"]]
                                                                  currencySymbol:[dataDic objectForKey:@"currency"]
                                                                  status:[dataDic objectForKey:@"status"]
                                                                  created:[df dateFromString:[dataDic objectForKey:@"created"]]
                                                                  expiry:[df dateFromString:[dataDic objectForKey:@"expiration_date"]]
                                                                  ticket:[dataDic objectForKey:@"ticket"]
                                                                  transactionId:[dataDic objectForKey:@"transaction_id"]];
                                       
                                       [extractions addObject:e];
                                       
                                       
                                   }
                                   if(successHandler)successHandler(extractions);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:[responseDictionary objectForKey:@"message"]]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc]
                                                              initWithDomain:@"PNPMalformedJson"
                                                              code:-2020
                                                              userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
    
    
    
    
}

-(void) sendHalcashWithAmount:(NSNumber *) amount
                          pin:(NSString *) pin
                      concept:(NSString *) concept
          withSuccessCallback:(PnPSuccessHandler) successHandler
             andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    amount = [NSNumber numberWithDouble:([amount doubleValue] *100)];
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"hal_cash/send"]
                   usingParameters: @{@"amount":amount,@"concept":concept,@"pin":pin}
                       withAccount:self.userAccount
                           timeout:20
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                       NSLog(@"%@",[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"send"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)successHandler();
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:[responseDictionary objectForKey:@"message"]]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc]
                                                              initWithDomain:@"PNPMalformedJson"
                                                              code:-2020
                                                              userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
}

-(void) cancelHalcashTransaction:(PNPHalcashExtraction *) extraction
             withSuccessCallback:(PnPSuccessHandler) successHandler
                andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"hal_cash/cancel"]
                   usingParameters: @{@"ticket":extraction.ticket}
                       withAccount:self.userAccount
                           timeout:20
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"cancel"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)successHandler();
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:[responseDictionary objectForKey:@"message"]]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc]
                                                              initWithDomain:@"PNPMalformedJson"
                                                              code:-2020
                                                              userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
    
}

-(void) getAtmsNearLocation:(CLLocation *)location
              andRadiusInKm:(float)radius
        withSuccessCallback:(PnPGenericNSAarraySucceddHandler)successHandler
           andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"hal_cash/near_atms"]
                   usingParameters: @{@"latitude":[NSString stringWithFormat:@"%f",location.coordinate.latitude] ,@"longitude":[NSString stringWithFormat:@"%f",location.coordinate.longitude],@"distance":[NSString stringWithFormat:@"%f",radius]}
                       withAccount:self.userAccount
                           timeout:20
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"near_atms"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               NSLog(@"responseDictionary %@",responseDictionary);
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   NSMutableArray *a = [NSMutableArray new];
                                   for (NSDictionary *d in [responseDictionary objectForKey:@"data"]) {
                                       CLLocation *loc =[[CLLocation alloc] initWithLatitude:[[d objectForKey:@"latitude"] doubleValue]
                                                                                   longitude:[[d objectForKey:@"longitude"] doubleValue]];
                                       PNPLocation *l = [[PNPLocation alloc] initWithLocation:loc city:[d objectForKey:@"locality"] address:[d objectForKey:@"address"] name:[d objectForKey:@"name"]];
                                       [a addObject:l];
                                   }
                                   if(successHandler) successHandler(a);
                                   
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:[responseDictionary objectForKey:@"message"]]);
                               }
                           }
                           @catch (NSException *exception) {
                               NSLog(@"%s --> %@",__PRETTY_FUNCTION__,exception);
                               if(errorHandler) errorHandler([[PNPMalformedJsonError alloc]
                                                              initWithDomain:@"PNPMalformedJson"
                                                              code:-2020
                                                              userInfo:nil]);
                           }
                       }else{
                           if(errorHandler)errorHandler([self handleErrors:error]);
                       }
                   }];
    
}

#pragma mark - Private Methods
-(NSNumber *) clearAmount:(NSNumber *)n{
    
    return [NSNumber numberWithDouble:[n doubleValue]/100];
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
    return [self.environment.url URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.json",extension]];
}

-(NSURL *) generateAvatarUrlFromPrefix:(NSString *) prefix
                              andPhone:(NSString *) phone{
    
    return [self.environment.url URLByAppendingPathComponent:
            [NSString stringWithFormat:@"avatars/get/%@/%@/%@",self.clientId,prefix,phone]];
}

@end


#pragma mark - ENVIRONMENTS

@implementation PNPEnvironment
-(id) initWithUrl:(NSURL *) url{
    self = [super init];
    if(self){
        self.url = url;
    }
    return self;
}
@end


@implementation PNPSandboxEnvironment
-(id) init{
    self = [super initWithUrl:[NSURL URLWithString:@"https://demo-core.paynopain.com"]];
    return self;
}
@end

@implementation PNPProductionEnvironment
-(id) init{
    self = [super initWithUrl:[NSURL URLWithString:@"https://api.paynopain.com"]];
    return self;
}
@end


