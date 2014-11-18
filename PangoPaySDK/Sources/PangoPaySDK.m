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
#define     PNP_REQUEST_TIMEOUT                30
#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

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
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   
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

-(void) getCommerceDataWithSuccessCallback:(PnpCommerceDataSuccessHandler)successHandler
                          andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }

    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"ComUsers/commerce_data"]
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
                                                                   objectForKey:@"commerce_data"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   PNPCommerce *c = [[PNPCommerce alloc] initWithIdentifier:[[responseDictionary objectForKey:@"data"] objectForKey:@"id"] commerceId:[[[responseDictionary objectForKey:@"data"] objectForKey:@"location_data"] objectForKey:@"id"] name:[[[responseDictionary objectForKey:@"data"] objectForKey:@"location_data"] objectForKey:@"name"]];
                                   if(successHandler)  successHandler(c);
                                   
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
                       
                       NSLog(@"%@",[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
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
                           timeout:60
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

-(void) validatePinWithSuccessCallback:(NSString *)pin
                   withSuccessCallback:(PnPSuccessHandler)successHandler
                      andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"users/validate_pin"]
                   usingParameters:@{@"pin":pin}
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
                                                                                                objectForKey:@"validate_pin"];
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
                           timeout:60
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

-(void) getRawProvinceDataWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"register/provinces"]
                   usingParameters:nil
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
                                                                   objectForKey:@"provinces"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   NSArray *data = [responseDictionary objectForKey:@"data"];
                                   if(successHandler) successHandler(data);
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

-(void) getProvincesWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    [self getRawProvinceDataWithSuccessCallback:^(NSArray *data) {
        NSMutableArray *provinces  = [NSMutableArray new];
        for(NSDictionary *d in data){
            [provinces addObject:[[d objectForKey:@"Province"] objectForKey:@"province"]];
        }
        if(successHandler)  successHandler(provinces);
    } andErrorCallback:errorHandler];
}

-(void) getCitysForProvince:(NSString *) province
        withSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
           andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    [self getRawProvinceDataWithSuccessCallback:^(NSArray *data) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Province.province contains[cd] %@",province];
        data = [data filteredArrayUsingPredicate:predicate];
        NSArray *cities = [[data firstObject] objectForKey:@"City"];
        NSMutableArray *cityStrings = [NSMutableArray new];
        for (NSDictionary *c in cities){
            [cityStrings addObject:[c objectForKey:@"city"]];
        }
        if(successHandler)  successHandler(cityStrings);
    } andErrorCallback:errorHandler];
}

-(void) registerUserWithUsername:(NSString *)username
                        password:(NSString *)password
                            name:(NSString *)name
                         surname:(NSString *)surname
                           email:(NSString *)email
                          prefix:(NSString *)prefix
                           phone:(NSString *)phone
                             pin:(NSString *)pin
                            city:(NSString *) city
                        province:(NSString *) province
                            male:(BOOL )isMale
                       birthdate:(NSDate *) date
                    commerceCode:(NSString *) commerceCode
             withSuccessCallback:(PnPSuccessHandler) successHandler
                andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd"];
    [params setObject:username  forKey:@"username"];
    [params setObject:password  forKey:@"password"];
    [params setObject:email     forKey:@"mail"];
    [params setObject:name      forKey:@"name"];
    [params setObject:surname   forKey:@"surname"];
    [params setObject:prefix    forKey:@"prefix"];
    [params setObject:phone     forKey:@"phone"];
    [params setObject:pin       forKey:@"pin"];
    [params setObject:city      forKey:@"city"];
    [params setObject:province  forKey:@"province"];
    [params setObject:[df stringFromDate:date] forKey:@"birthdate"];
    [params setObject:commerceCode forKey:@"commerce_code"];
    if(isMale){
        [params setObject:@"M" forKey:@"gender"];
    }else{
        [params setObject:@"F" forKey:@"gender"];
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
                   usingParameters:@{@"token":token,@"client_id":self.clientId,@"client_secret":self.clientSecret}
                       withAccount:nil
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSLog(@"%@",[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                               
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
                   usingParameters:@{@"device":ds,@"type":@"IOS"}
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
                               NSLog(@"%@",responseDictionary);
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
                               NSLog(@"%@",responseDictionary);
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
    NSMutableDictionary *params;
    if(!card.identifier){
        params = [NSMutableDictionary dictionaryWithDictionary:@{@"number":card.number,@"month":[NSString stringWithFormat:@"%02lu",(long unsigned)[card.month intValue]],@"year":card.year}];
    }else{
        params = [NSMutableDictionary dictionaryWithDictionary:@{@"creditcard_id":card.identifier}];
    }
    
    amount = [NSNumber numberWithDouble:[amount doubleValue] *100];
    
    [params setObject:amount forKey:@"amount"];
    [params setObject:cvv forKey:@"cvv"];
    
    NSLog(@"%@",params);
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"wallets/recharge"]
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


#pragma mark - Commerce Payment Methods


-(void) getOrderWithReference:(NSString *) reference
          withSuccessCallback:(PnPOrderSuccessHandler)successHandler
                errorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"orders/view_order"]
                   usingParameters:@{@"reference":reference,@"check_loyalty":@1}
                       withAccount:self.userAccount
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
                                                                   objectForKey:@"view_order"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   NSDictionary *order = [[responseDictionary objectForKey:@"data"] objectForKey:@"order"];
                                   NSNumber *amount = [self clearAmount:[order objectForKey:@"amount"]];
                                   NSDateFormatter *df = [[NSDateFormatter alloc] init];
                                   [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                                   [df setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Madrid"]];
                                   PNPOrder *o = [[PNPOrder alloc] initWithIdentifier:[order objectForKey:@"id"]
                                                                            reference:[order objectForKey:@"reference"]
                                                                              concept:[order objectForKey:@"concept"]
                                                                              created:[df dateFromString:[order objectForKey:@"created"]]
                                                                             commerce:[order objectForKey:@"commerce"]
                                                                               amount:amount
                                                                            netAmount:[self clearAmount:[order objectForKey:@"net_amount"]]
                                                                    loyaltyPercentage:[self clearAmount:[order objectForKey:@"loyalty_percentage"]]
                                                                loyaltyDiscountAmount:[self clearAmount:[order objectForKey:@"loyalty_discount_amount"]]
                                                                             currency:[[order objectForKey:@"currency"] objectForKey:@"symbol"]];
                                   if(successHandler) successHandler(o);
                                   

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

-(void) payOrder:(PNPOrder *) order
         withPin:(NSString *) pin
withSuccessCallback:(PnPSuccessHandler)successHandler
   errorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"orders/payment"]
                   usingParameters:@{@"reference":order.reference,@"pin":pin,@"check_loyalty":@1}
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
                                                                   objectForKey:@"payment"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler) successHandler();
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
                   usingParameters:@{@"read":@"all"}
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
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
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
                                                             type:[d objectForKey:@"type"]
                                                             read:[[d objectForKey:@"read"] boolValue]];
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
                           if([[responseDictionary objectForKey:@"success"] boolValue]){
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
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
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
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
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
                           if([[responseDictionary objectForKey:@"success"] boolValue]){
                               if(successHandler) successHandler();
                           }else{
                               if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                         code:-6060
                                                                                                     userInfo:responseDictionary]);
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
                           if([[responseDictionary objectForKey:@"success"] boolValue]){
                               if(successHandler)successHandler();
                           }else{
                               if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                          code:-6060
                                                                                                      userInfo:responseDictionary]);
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
                           if([[responseDictionary objectForKey:@"success"] boolValue]){
                               if(successHandler)successHandler();
                           }else{
                               if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                         code:-6060
                                                                                                     userInfo:responseDictionary]);
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
                           if([[responseDictionary objectForKey:@"success"] boolValue]){
                               if(successHandler)successHandler();
                           }else{
                               if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                         code:-6060
                                                                                                     userInfo:responseDictionary]);
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
                           if([[responseDictionary objectForKey:@"success"] boolValue]){
                               if(successHandler)successHandler();
                           }else{
                               if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                          code:-6060
                                                                                                      userInfo:responseDictionary]);
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
                           if([[responseDictionary objectForKey:@"success"] boolValue]){
                               if(successHandler)successHandler();
                           }else{
                               if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                         code:-6060
                                                                                                     userInfo:responseDictionary]);
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
                               
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   NSMutableArray *movements = [NSMutableArray new];
                                   
                                   NSArray *results;
                                   if([[responseDictionary objectForKey:@"data"] isKindOfClass:[NSDictionary class]]){
                                       results = [[responseDictionary objectForKey:@"data"] objectForKey:@"results"];
                                   }
                                   
                                   for (NSDictionary *r in results){
                                       NSLog(@"%@",r);
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
                                           NSLog(@"%@",r);

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
-(void) getPangoCommission:(PNPPango *) pango
           withMethod:(NSString *) method
          withAmount:(NSNumber *) amount
  withSuccessCallback:(PnPSuccessHandler) successHandler
     andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self isUserLoggedIn ]){
        NSLog(@"No user logged in.");
        return;
    }
    amount = [NSNumber numberWithDouble:([amount doubleValue] * 100)];
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"transactions/get_commission"]
                   usingParameters:@{@"controller":@"pangos",@"method":method,@"pango_id":pango.identifier,@"amount":amount}
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
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)successHandler([self clearAmount:[responseDictionary objectForKey:@"data"]]);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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
                            NSLog(@"%@",error);
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
                                                                   objectForKey:@"get"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc]
                                                                   initWithDomain:parseError.domain
                                                                   code:[parseError code]
                                                                   userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)successHandler([self clearAmount:[responseDictionary objectForKey:@"data"]]);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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
                           timeout:60
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
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler) successHandler();
                               }else{

                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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
                                       @try {
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
                                           }else if([emitterType isEqualToString:@"Recharge"]){
                                               entity = [[PNPTransactionEmitterRecharge alloc] init];
                                           }else if ([emitterType isEqualToString:@"PromoRecharge"]){
                                               entity = [[PNPTransactionEmitterRechargePromo alloc] init];
                                           }
                                           else if([emitterType isEqualToString:@"Commerce"]){
                                               entity = [[PNPTransactionEmitterCommerce alloc] initWithName:[emitterData objectForKey:@"name"]];
                                           }
                                           else{
                                               entity = [[PNPTransactionEntity alloc] init];
                                               NSLog(@"No implementation for emitter type %@ transaction %@",emitterType,d);
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
                                       @catch (NSException *exception) {
                                           NSLog(@"No se ha podido parsear las transaction %@ por el error %@",d,exception);

                                       }
 
 
                                   }
                                   if(successHandler)successHandler(PNPTransactionsArray);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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
                                       @try {
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
                                               entity = [[PNPTransactionReceiverPango alloc] init];
                                           }else if([receiverType isEqualToString:@"HalCash"]){
                                               entity = [[PNPTransactionReceiverHalcash alloc] init];
                                           }else if ([receiverType isEqualToString:@"Commerce"]){
                                               entity = [[PNPTransactionReceiverCommerce alloc] initWithName:[receiverData objectForKey:@"name"]];
                                           }else{
                                               NSLog(@"No implementation for receiver type %@ transaction %@",receiverType,d);                                           }
                                           
                                           [PNPTransactionsArray addObject:[[PNPTransactionSent alloc]
                                                                            initWithIdentifier:[d objectForKey:@"id"]
                                                                            amount:amount
                                                                            currencyCode:[currency objectForKey:@"code"]
                                                                            currencySymbol:[currency objectForKey:@"symbol"]
                                                                            concept:[d objectForKey:@"concept"]
                                                                            status:[d objectForKey:@"status"]
                                                                            created:created
                                                                            andEntity:entity]];

                                       }
                                       @catch (NSException *exception) {
                                           NSLog(@"No se ha podido parsear las transaction %@ por el error %@",d,exception);
                                       }
                                   }
                                   if(successHandler)successHandler(PNPTransactionsArray);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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
                                       @try {
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
                                               NSLog(@"No implementation for receiver type %@ transaction %@",receiverType,d);
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
                                       @catch (NSException *exception) {
                                           NSLog(@"No se ha podido parsear las transaction %@ por el error %@",d,exception);
                                       }
                                   }
                                   if(successHandler)successHandler(PNPTransactionsArray);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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
                                                                 userInfo:responseDictionary]);
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

-(void) getRequestedPaymentRequestsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                                      andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"payment_requests/get"]
                   usingParameters:@{@"type":@"requester",@"status":@"all"}
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
                                                                    name:[d objectForKey:@"name"]
                                                                    status:[d objectForKey:@"status"]]];
                                   }
                                   if(successHandler)successHandler(PNPRequestsArray);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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


-(void) cancelRequestedPaymentRequest:(PNPPaymentRequest *) request
                  withSuccessCallback:(PnPSuccessHandler) successHandler
                     andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"payment_requests/cancel"]
                   usingParameters: @{@"id":request.identifier,@"type":@"requester"}
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
                                                                 userInfo:responseDictionary]);
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

-(void) getPaymentRequestsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                             andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"payment_requests/get"]
                   usingParameters:@{@"status":@"all"}
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
                                                                    name:[d objectForKey:@"name"]
                                                                    status:[d objectForKey:@"status"]]];
                                   }
                                   if(successHandler)successHandler(PNPRequestsArray);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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
                                                                 userInfo:responseDictionary]);
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
                           timeout:60
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
                                                                 userInfo:responseDictionary]);
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
                                                                 userInfo:responseDictionary]);
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
                                                                 userInfo:responseDictionary]);
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

-(void) getCommerceOrdersWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                               errorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"orders/get_orders"]
                   usingParameters: nil
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
                                                                   objectForKey:@"get_orders"];
                               
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   NSMutableArray *orders = [NSMutableArray new];
                                   for (NSDictionary *d in [responseDictionary objectForKey:@"data"]) {

                                       NSDictionary *orderDic = [d objectForKey:@"order"];
                                       NSDictionary *payerDic = [orderDic objectForKey:@"payer"];
                                       NSArray *orderLines = [d objectForKey:@"order_lines"];
                                       NSDateFormatter *df = [[NSDateFormatter alloc] init];
                                       [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                                       [df setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Madrid"]];
                                       if([payerDic isKindOfClass:[NSArray class]]){
                                           payerDic = [NSDictionary new];
                                       }
                                       
                                       PNPCommerceOrder *o = [[PNPCommerceOrder alloc] initWithIdentifier:[orderDic objectForKey:@"id"] reference:[orderDic objectForKey:@"reference"] type:[orderDic objectForKey:@"type"] concept:[orderDic objectForKey:@"concept"] status:[orderDic objectForKey:@"status"] amount:[self clearAmount:[orderDic objectForKey:@"amount"]] netAmount:[self clearAmount:[orderDic objectForKey:@"net_amount"]] currencySymbol:[[orderDic objectForKey:@"currency"] objectForKey:@"symbol"] mail:[payerDic objectForKey:@"mail"] userId:[payerDic objectForKey:@"user_id"] name:[payerDic objectForKey:@"name"] surname:[payerDic objectForKey:@"surname"] prefix:[payerDic objectForKey:@"prefix"] phone:[payerDic objectForKey:@"phone"] created:[df dateFromString:[orderDic objectForKey:@"created"]] orderLines:orderLines];
                                       [orders addObject:o];
                                       if(successHandler) successHandler(orders);
                                   }
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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
                                                                 userInfo:responseDictionary]);
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
                                                                 userInfo:responseDictionary]);
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
                                                                 userInfo:responseDictionary]);
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
                           timeout:60
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
                                                                 userInfo:responseDictionary]);
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


#pragma mark - Commerce payment methods


-(void) createOrderWithConcept:(NSString *) concept
                          cart:(Cart *) cart
                          type:(NSString *) type
           withSuccessCallback:(PnPSuccessStringHandler) successHandler
              andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    NSNumber *amount = [NSNumber numberWithDouble:[[cart getPriceWithoutGlobalDiscount] doubleValue] * 100];
    
    NSNumber *netAmount = [NSNumber numberWithDouble:[[cart getPrice] doubleValue] * 100];
    
    
    NSMutableArray *orderLines = [NSMutableArray new];
    
    for (CartItem * c in cart.cartItems) {

        if([c.product.getPrice floatValue] > 0){
            NSMutableDictionary *oLine = [NSMutableDictionary new];
            [oLine setObject:[NSNumber numberWithDouble:[[c.product getPrice] doubleValue] * 100] forKey:@"amount"];
            [oLine setObject:@"product" forKey:@"type"];
            [oLine setObject:c.product.name forKey:@"name"];
            if(c.product.externalId){
                [oLine setObject:c.product.externalId forKey:@"external_id"];
            }
            [oLine setObject:[c getQuantity] forKey:@"number"];
            [orderLines addObject:oLine];
            oLine = [NSMutableDictionary new];
            if([c getDiscount] &&  ![c getDiscount].comesFromCoupon){
                [oLine setObject:@"discount" forKey:@"type"];
                [oLine setObject:[NSNumber numberWithDouble:[[[c getDiscount] getPrice] doubleValue] * 100] forKey:@"amount"];
                [oLine setObject:[NSNumber numberWithDouble:[[[c getDiscount] getDiscountPercentage] doubleValue] * 100] forKey:@"number"];
                [oLine setObject:[NSString stringWithFormat:NSLocalizedString(@"Descuento aplicado al producto %@",nil),c.product.name] forKey:@"name"];
                [orderLines addObject:oLine];
            }

        }
    }
    NSMutableDictionary *oLine = [NSMutableDictionary new];
    if(cart.fidelityDiscount){
        [oLine setObject:@"loyaltyDiscount" forKey:@"type"];
        NSNumber *fidelityDiscount = [NSNumber numberWithDouble:[[cart getPrice] doubleValue] - ([[cart getPrice] doubleValue] * [cart.fidelityDiscount doubleValue] / 100)];
        netAmount = [NSNumber numberWithDouble:[netAmount doubleValue] - [fidelityDiscount doubleValue]];
        [oLine setObject:fidelityDiscount forKey:@"amount"];
        [oLine setObject:[NSNumber numberWithDouble:[cart.fidelityDiscount doubleValue] * 100] forKey:@"number"];
        [oLine setObject:NSLocalizedString(@"Fidelización",nil) forKey:@"name"];
        [oLine setObject:cart.fidelityIdentifier forKey:@"external_id"];
        [orderLines addObject:oLine];
    }

    
    oLine = [NSMutableDictionary new];
    if([cart getDiscount] && ![cart getDiscount].comesFromCoupon){
        [oLine setObject:@"discount" forKey:@"type"];
        [oLine setObject:[NSNumber numberWithDouble:[[[cart getDiscount] getPrice] doubleValue] * 100] forKey:@"amount"];
        [oLine setObject:[NSNumber numberWithDouble:[[[cart getDiscount] getDiscountPercentage] doubleValue] * 100] forKey:@"number"];
        [oLine setObject:NSLocalizedString(@"Descuento aplicado a la compra",nil) forKey:@"name"];
        [orderLines addObject:oLine];
    }
    
    [self getProductCategoriesWithSuccessCallback:^(NSArray *data) {
        for (PNPCoupon *c in cart.coupons){
            NSMutableDictionary *oLine = [NSMutableDictionary new];
            [oLine setObject:@"coupon" forKey:@"type"];
            [oLine setObject:c.ccode forKey:@"external_id"];
            if(c.gift.length > 0){
                [oLine setObject:@0 forKey:@"amount"];
                [oLine setObject:@0 forKey:@"number"];
                [oLine setObject:[NSString stringWithFormat:NSLocalizedString(@"%@ de regalo",nil),c.gift] forKey:@"name"];
            }else if(c.percentageAmount.floatValue > 0 && c.productId){
                NSPredicate *p = [NSPredicate predicateWithFormat:@"products.variants.identifier == %@",c.productId];
                NSArray *sResult = [data filteredArrayUsingPredicate:p];
                p = [NSPredicate predicateWithFormat:@"variants.identifier == %@",c.productId];
                sResult = [(NSArray *)[sResult firstObject] filteredArrayUsingPredicate:p];
                PNPCProduct *product = [sResult firstObject];
                p = [NSPredicate predicateWithFormat:@"identifier == %@",c.productId];
                sResult = [[sResult firstObject] filteredArrayUsingPredicate:p];
                PNPCVariant *variant = [sResult firstObject];
                NSNumber *priceWithDiscount = [NSNumber numberWithDouble:[variant.price doubleValue] - [variant.price doubleValue] * [c.percentageAmount doubleValue]/100];
                [oLine setObject:priceWithDiscount forKey:@"amount"];
                [oLine setObject:[NSNumber numberWithDouble:[c.percentageAmount doubleValue] * 100] forKey:@"number"];
                [oLine setObject:[NSString stringWithFormat:NSLocalizedString(@"Descuento aplicado al producto %@",nil),product.name] forKey:@"name"];
            }else if(c.percentageAmount.floatValue > 0){
                [oLine setObject:[[cart getDiscount] getPrice] forKey:@"amount"];
                [oLine setObject:[NSNumber numberWithDouble:[c.percentageAmount doubleValue] * 100] forKey:@"number"];
                [oLine setObject:NSLocalizedString(@"Descuento aplicado a la compra",nil) forKey:@"name"];
            }
            [orderLines addObject:oLine];
        }
        NSError *jerror;
        NSString *jOrderLines = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:orderLines
                                                                                           options:0
                                                                                             error:&jerror]
                                                  encoding:NSUTF8StringEncoding];
        
        
    

        [NXOAuth2Request performMethod:@"POST"
                            onResource:[self generateUrl:@"orders/create"]
                       usingParameters: @{@"concept":concept,@"amount":amount,@"net_amount":netAmount,@"lines":jOrderLines,@"type":type}
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
                                                                       objectForKey:@"create"];
                                   if(parseError){
                                       if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                          code:[parseError code]
                                                                                                      userInfo:parseError.userInfo]);
                                       return;
                                   }
                                   
                                   if([[responseDictionary objectForKey:@"success"] boolValue]){

                                       if(successHandler) successHandler([[responseDictionary objectForKey:@"data"] objectForKey:@"reference"]);
                                       
                                   }else{
                                       if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                     initWithDomain:@"PNPGenericWebserviceError"
                                                                     code:-6060
                                                                     userInfo:responseDictionary]);
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
        
    } andErrorCallback:errorHandler];
    
}


-(void) checkIfOrderIsPaid:(NSString *) orderReference
       withSuccessCallback:(PnPCommerceOrderSuccessHandler) successHandler
          andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"orders/get_orders"]
                   usingParameters: @{@"reference":orderReference}
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
                                                                   objectForKey:@"get_orders"];
                               
                               NSLog(@"%@",responseDictionary);
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }

                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   NSDictionary *orderDic = [[[responseDictionary objectForKey:@"data"] objectAtIndex:0] objectForKey:@"order"];
                                   if(![[orderDic objectForKey:@"status"] isEqualToString:@"AC"]){
                                       if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                     initWithDomain:@"PNPGenericWebserviceError"
                                                                     code:-6060
                                                                     userInfo:responseDictionary]);
                                       return;
                                   }
                                   NSDateFormatter *df = [[NSDateFormatter alloc] init];
                                   [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                                   [df setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Madrid"]];
                                   NSDictionary *payerDic = [orderDic objectForKey:@"payer"];
                                   NSLog(@"%@",payerDic);
                                   PNPCommerceOrder *o = [[PNPCommerceOrder alloc] initWithIdentifier:[orderDic objectForKey:@"id"] reference:[orderDic objectForKey:@"reference"] type:[orderDic objectForKey:@"type"] concept:[orderDic objectForKey:@"concept"] status:[orderDic objectForKey:@"status"] amount:[self clearAmount:[orderDic objectForKey:@"amount"]] netAmount:[self clearAmount:[orderDic objectForKey:@"net_amount"]] currencySymbol:[[orderDic objectForKey:@"currency"] objectForKey:@"symbol"] mail:[payerDic objectForKey:@"mail"] userId:[payerDic objectForKey:@"user_id"] name:[payerDic objectForKey:@"name"] surname:[payerDic objectForKey:@"surname"] prefix:[payerDic objectForKey:@"prefix"] phone:[payerDic objectForKey:@"phone"] created:[df dateFromString:[orderDic objectForKey:@"created"]] orderLines:[[[responseDictionary objectForKey:@"data"] objectAtIndex:0] objectForKey:@"order_lines"]];
                                   if(successHandler) successHandler(o);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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

    




-(void) sendMailForOrder:(NSString *) orderReference
                  toMail:(NSString *) mail
                    type:(NSString *) mailType
                  userId:(NSNumber *) userId
     withSuccessCallback:(PnPSuccessHandler) successHandler
        andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    if(userId == nil ){
        [NXOAuth2Request performMethod:@"POST"
                            onResource:[self generateUrl:@"orders/mail"]
                       usingParameters: @{@"reference":orderReference,@"mail":mail,@"type":mailType}
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
                                                                       objectForKey:@"mail"];
                                   if(parseError){
                                       if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                          code:[parseError code]
                                                                                                      userInfo:parseError.userInfo]);
                                       return;
                                   }
                                   
                                   if([[responseDictionary objectForKey:@"success"] boolValue]){
                                       
                                       if(successHandler) successHandler();
                                       
                                   }else{
                                       if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                     initWithDomain:@"PNPGenericWebserviceError"
                                                                     code:-6060
                                                                     userInfo:responseDictionary]);
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

    }else{
        
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"orders/mail"]
                   usingParameters: @{@"reference":orderReference,@"mail":mail,@"type":mailType,@"user_id":userId}
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
                                                                   objectForKey:@"mail"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   
                                   if(successHandler) successHandler();
                                   
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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
}

-(void) refundOrder:(NSNumber *) orderId
                pin:(NSString *) pin
withSuccessCallback:(PnPSuccessHandler) successHandler
   andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    if(pin == nil){
        
        [NXOAuth2Request performMethod:@"POST"
                            onResource:[self generateUrl:@"orders/cancel"]
                       usingParameters: @{@"order_id":orderId}
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
                                   NSLog(@"%@",responseDictionary);
                                   if(parseError){
                                       if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                          code:[parseError code]
                                                                                                      userInfo:parseError.userInfo]);
                                       return;
                                   }
                                   
                                   if([[responseDictionary objectForKey:@"success"] boolValue]){
                                       
                                       if(successHandler) successHandler();
                                       
                                   }else{
                                       if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                     initWithDomain:@"PNPGenericWebserviceError"
                                                                     code:-6060
                                                                     userInfo:responseDictionary]);
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
        
        
    }else{
        
        [NXOAuth2Request performMethod:@"POST"
                            onResource:[self generateUrl:@"transactions/refund"]
                       usingParameters: @{@"order_id":orderId,@"pin":pin}
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
                                                                       objectForKey:@"refund"];
                                   if(parseError){
                                       if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                          code:[parseError code]
                                                                                                      userInfo:parseError.userInfo]);
                                       return;
                                   }
                                   
                                   if([[responseDictionary objectForKey:@"success"] boolValue]){
                                       
                                       if(successHandler) successHandler();
                                       
                                   }else{
                                       if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                     initWithDomain:@"PNPGenericWebserviceError"
                                                                     code:-6060
                                                                     userInfo:responseDictionary]);
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
    

}

#pragma mark - Wallet
-(void) rechargeWalletWithAmount:(NSNumber *) amount
							 pin:(NSString*) pin
			 withSuccessCallback:(PnPSuccessHandler) successHandler
				andErrorCallback:(PnPGenericErrorHandler) errorHandler {
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
	
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"referenced_payments/send_mx"]
                   usingParameters:@{
									 @"amount":[NSString stringWithFormat:@"%f",[amount doubleValue] *100],
									 @"pin":pin,
									 }
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
					   
					   
					   if(!error){
						   
                           NSError *parseError;
                           NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                               options:0
                                                                                                 error:&parseError]
                                                               objectForKey:@"send_mx"];
                           if(parseError){
                               if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                               
                                                                                                  code:[parseError code]
                                                                                              userInfo:parseError.userInfo]);
                               return;
                           }
						   
                           if([[responseDictionary objectForKey:@"success"] boolValue]){
							   
							   NSString* barCodeURL = [[responseDictionary objectForKey:@"data"] valueForKey:@"url"];
							   
                               if(successHandler)successHandler(barCodeURL);
                           }else{
                               if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                          code:-6060
                                                                                                      userInfo:responseDictionary]);
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                       }
                   }];
	
}


-(void) getWalletRechargesWithSuccessCallback:(PnPSuccessHandler) successHandler
							 andErrorCallback:(PnPGenericErrorHandler) errorHandler {
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
	
	NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
	[nf setNumberStyle:NSNumberFormatterNoStyle];
	
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateFormat:@"yyyy-mm-dd HH:mm:ss"];
	
	
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"referenced_payments/get"]
                   usingParameters:nil
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
					   
					   if(!error){
						   
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
							   
							   
							   NSMutableArray *list = [NSMutableArray new];
							   
							   list = [responseDictionary objectForKey:@"data"];
							   NSMutableArray *recharges = [NSMutableArray new];
							   
							   
							   for (NSDictionary *p in list) {
								   
								   PNPTransactionEmitterRecharge *recharge = [[PNPTransactionEmitterRecharge alloc]init];
								   recharge.amount = [nf numberFromString:[p valueForKey:@"amount"]];
								   recharge.created = [df dateFromString:[p valueForKey:@"created"]];
								   recharge.currencyCode = [[p valueForKey:@"currency"] valueForKey:@"code"];
								   recharge.currencySymbol = [[p valueForKey:@"currency"] valueForKey:@"symbol"];
								   recharge.status = [p valueForKey:@"status"];
								   recharge.barcode = [NSURL URLWithString:[p valueForKey:@"url"]];
								   
								   [recharges addObject:recharge];
							   }
							   
                               if(successHandler)successHandler(recharges);
                           }else{
                               if(errorHandler) errorHandler([[PNPGenericWebserviceError alloc] initWithDomain:@"PNPGenericWebserviceError"
                                                                                                          code:-6060
                                                                                                      userInfo:responseDictionary]);
                           }
                       }else{
                           if(errorHandler) errorHandler([self handleErrors:error]);
                       }
                   }];
}


#pragma mark - Coupons & Fidelity

-(void) shareCoupon:(PNPCoupon *) coupon toMail:(NSString *) mail withSuccessCallback:(PnPSuccessHandler) successHandler andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [self getUserDataWithSuccessCallback:^(PNPUser *user) {
        NSError *jerror;
        NSMutableDictionary *paramDicc = [NSMutableDictionary new];
        [paramDicc setObject:coupon.ccode forKey:@"coupon_code"];
        [paramDicc setObject:mail forKey:@"to"];
        [paramDicc setObject:@"no-reply@aywant.com" forKey:@"from"];
        [paramDicc setObject:[NSString stringWithFormat:NSLocalizedString(@"%@ %@ te comparte un cupón a través de Aywant", nil),user.name,user.surname] forKey:@"subject"];
        
        NSString *pparams = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:paramDicc
                                                                                           options:0
                                                                                             error:&jerror]
                                                  encoding:NSUTF8StringEncoding];
        NSLog(@"%@",pparams);
        
        [NXOAuth2Request performMethod:@"POST"
                            onResource:[self generateUrl:@"coupons/user_call"]
                       usingParameters:@{
                                         @"action":@"notifications/share_coupon.json",
                                         @"method": @"post",
                                         @"fields": pparams,
                                         }
                           withAccount:self.userAccount
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
                                                                       objectForKey:@"user_call"];
                                   if(parseError){
                                       if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                          code:[parseError code]
                                                                                                      userInfo:parseError.userInfo]);
                                       return;
                                   }
                                   if([[responseDictionary objectForKey:@"success"] boolValue]){
                                       if(successHandler) successHandler();
                                   }else{
                                       if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                     initWithDomain:@"PNPGenericWebserviceError"
                                                                     code:-6060
                                                                     userInfo:responseDictionary]);
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


    } andErrorCallback:errorHandler];
    
    
}

-(void) getCouponsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                         andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"coupons/user_call"]
                   usingParameters:@{
                                        @"action":@"coupons.json",
                                        @"method": @"get",
                                        @"fields": @"{}",
                                    }
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
                                                                   objectForKey:@"user_call"];
                               NSLog(@"%@",responseDictionary);
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   NSLog(@"%@",responseDictionary);
                                   NSDictionary *dataDic = [responseDictionary objectForKey:@"data"];
                                   NSMutableArray *coupons = [NSMutableArray new];
                                   NSDateFormatter *df = [[NSDateFormatter alloc] init];
                                   [df setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Madrid"]];
                                   [df setDateFormat:@"yyyy-MM-dd"];
                                   for (NSDictionary *d in dataDic) {
                                       @try {
                                           Class class = [PNPCoupon class];
                                           NSString *type =[d objectForKey:@"type"];
                                           if([type isEqualToString:@"coupon"]){
                                               if([[d objectForKey:@"limit_uses"] intValue] == 1){
                                                   class = [PNPCPOneTime class];
                                               }else{
                                                   class = [PNPCPMultiUssage class];
                                               }
                                           }else if ( [type isEqualToString:@"onceaday"]){
                                               class = [PNPCPDaily class];
                                           }else if([type isEqualToString:@"stamp"]){
                                               class = [PNPCPStampCard class];
                                           }else if ([type isEqualToString:@"exchange"]){
                                               class = [PNPCPExchange class];
                                           }else if ([type isEqualToString:@"loyalty"]){
                                               class = [PNPCPLoyalty class ];
                                           }
                                           PNPCoupon *c = [[class alloc] initWithCode:NULL_TO_NIL([d objectForKey:@"code"]) identifier:NULL_TO_NIL([d objectForKey:@"coupon_id"]) loyaltyIdentifier:NULL_TO_NIL([d objectForKey:@"loyalty_id"]) actualUses:NULL_TO_NIL([d objectForKey:@"actual_uses"]) limitUses:NULL_TO_NIL([d objectForKey:@"limit_uses"]) companyName:NULL_TO_NIL([d objectForKey:@"company_name"]) title:NULL_TO_NIL([d objectForKey:@"title"]) description:NULL_TO_NIL([d objectForKey:@"description"]) shortDescription:NULL_TO_NIL([d objectForKey:@"description_short"]) logoUrl:NULL_TO_NIL([d objectForKey:@"logo"]) brandLogoUrl:NULL_TO_NIL([d objectForKey:@"logo_brand"]) startDate:[df dateFromString:NULL_TO_NIL([d objectForKey:@"start_date"])] endDate:[df dateFromString:NULL_TO_NIL([d objectForKey:@"end_date"])] validDays:NULL_TO_NIL([d objectForKey:@"valid_days"]) timeRanges:NULL_TO_NIL([d objectForKey:@"time_ranges"]) fixedAmount:[self clearAmount:NULL_TO_NIL([d objectForKey:@"fixed_amount"])] percentageAmount:[self clearAmount:NULL_TO_NIL([d objectForKey:@"percentage_amount"])] gift:NULL_TO_NIL([d objectForKey:@"gift"]) favorite:[[d objectForKey:@"favorite"] boolValue] viewed:[[d objectForKey:@"viewed"] boolValue] status:NULL_TO_NIL([d objectForKey:@"status"] )  products:NULL_TO_NIL([d objectForKey:@"products"]) giftProducts:NULL_TO_NIL([d objectForKey:@"gift_products"])  type:type];

                                           [coupons addObject:c];
                                       }
                                       @catch (NSException *exception) {
                                           NSLog(@"no se ha podido parsear el coupon %@ por el error %@",d,exception);
                                       }


                                   }
                                   if(successHandler) successHandler(coupons);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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
                       NSLog(@"%@",[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                   }];
}

-(void) deleteCoupon:(PNPCoupon *) coupon
 withSuccessCallback:(PnPSuccessHandler) successHandler
    andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"coupons/user_call"]
                   usingParameters:@{
                                        @"action":[NSString stringWithFormat:@"coupons/%@/delete.json",coupon.ccode],
                                        @"method": @"post",
                                        @"fields": @"{}",
                                    }
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
                                                                   objectForKey:@"user_call"];
                               
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   successHandler();
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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

-(void) markCouposAsRead:(PNPCoupon *) coupon
     withSuccessCallback:(PnPSuccessHandler) successHandler
        andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    NSError *jerror;
    NSDictionary *paramDicc = @{@"code":coupon.ccode};
    NSString *pparams = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:paramDicc
                                                                                       options:0
                                                                                         error:&jerror]
                                              encoding:NSUTF8StringEncoding];
    NSLog(@"%@",pparams);
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"coupons/user_call"]
                   usingParameters:@{
                                     @"action":@"coupons/viewed.json",
                                     @"method": @"post",
                                     @"fields": pparams,
                                     }
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
                                                                   objectForKey:@"user_call"];
                               
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   successHandler();
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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

-(void) addCouponToFavorites:(PNPCoupon *) coupon
         withSuccessCallback:(PnPSuccessHandler) successHandler
            andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    NSError *jerror;
    NSString *pparams;

    if(coupon.favorite){
        NSDictionary *paramDicc = @{@"remove":@1};
        pparams=[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:paramDicc
                                                                                       options:0
                                                                                         error:&jerror]
                                              encoding:NSUTF8StringEncoding];
    }else{
        pparams = @"{}";
    }



    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"coupons/user_call"]
                   usingParameters:@{
                                     @"action":[NSString stringWithFormat:@"coupons/%@/favorite.json",coupon.ccode],
                                     @"method": @"post",
                                     @"fields": pparams,
                                     }
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
                                                                   objectForKey:@"user_call"];
                               
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   successHandler();
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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

-(void) getLoyaltiesWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                       andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"coupons/user_call"]
                   usingParameters:@{
                                     @"action":@"loyalties.json",
                                     @"method": @"get",
                                     @"fields": @"{}",
                                     }
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
                                                                   objectForKey:@"user_call"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   NSDictionary *dataDic = [responseDictionary objectForKey:@"data"];
                                   NSMutableArray *loyalties = [NSMutableArray new];
                                   NSDateFormatter *df = [[NSDateFormatter alloc] init];
                                   [df setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Madrid"]];
                                   [df setDateFormat:@"yyyy-MM-dd"];
                                   for (NSDictionary *d in dataDic) {
                                       @try {
                                           NSMutableArray *memberFields = [NSMutableArray new];
                                           for (id key in [d objectForKey:@"member_fields"]) {
                                               if([[[d objectForKey:@"member_fields"] objectForKey:key] boolValue]){
                                                   NSString *mf = key;
                                                   if([mf isEqualToString:@"gender"]){
                                                       [memberFields addObject:[[PNPLoyaltySuscriptionFieldSelect alloc] initWithName:NSLocalizedString(@"Sexo", nil) attribute:mf options:@[NSLocalizedString(@"Hombre", nil),NSLocalizedString(@"Mujer", nil)] andOptionValues:@[@"M",@"F"] order:4]];
                                                   }else if ([mf isEqualToString:@"name"]){
                                                       [memberFields addObject:[[PNPLoyaltySuscriptionFieldText alloc] initWithName:NSLocalizedString(@"Nombre", nil) attribute:mf order:1]];
                                                   }else if ([mf isEqualToString:@"surname"]){
                                                       [memberFields addObject:[[PNPLoyaltySuscriptionFieldText alloc] initWithName:NSLocalizedString(@"Primer apellido", nil) attribute:mf order:2]];
                                                   }else if ([mf isEqualToString:@"surname2"]){
                                                       [memberFields addObject:[[PNPLoyaltySuscriptionFieldText alloc] initWithName:NSLocalizedString(@"Segundo apellido", nil) attribute:mf order:3]];
                                                   }else if([mf isEqualToString:@"country"]){
                                                       [memberFields addObject:[[PNPLoyaltySuscriptionFieldText alloc] initWithName:NSLocalizedString(@"País", nil) attribute:mf order:7]];
                                                   }
                                                   else if([mf isEqualToString:@"province"]){
                                                       [memberFields addObject:[[PNPLoyaltySuscriptionFieldText alloc] initWithName:NSLocalizedString(@"Provincia", nil) attribute:mf order:8]];
                                                   }
                                                   else if([mf isEqualToString:@"locality"]){
                                                       [memberFields addObject:[[PNPLoyaltySuscriptionFieldText alloc] initWithName:NSLocalizedString(@"Localidad", nil) attribute:mf order:9]];
                                                   }
                                                   else if([mf isEqualToString:@"zip_code"]){
                                                       [memberFields addObject:[[PNPLoyaltySuscriptionFieldText alloc] initWithName:NSLocalizedString(@"Código postal", nil) attribute:mf order:10]];
                                                   }
                                                   else if([mf isEqualToString:@"birthdate"]){
                                                       [memberFields addObject:[[PNPLoyaltySuscriptionFieldText alloc] initWithName:NSLocalizedString(@"Fecha de nacimiento", nil) attribute:mf order:5]];
                                                   }
                                                   else if([mf isEqualToString:@"dni"]){
                                                       [memberFields addObject:[[PNPLoyaltySuscriptionFieldText alloc] initWithName:NSLocalizedString(@"DNI", nil) attribute:mf order:6]];
                                                   }
                                               }
                                           }
                                           NSSortDescriptor *s = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
                                           memberFields = [NSMutableArray arrayWithArray:[memberFields sortedArrayUsingDescriptors:@[s]]];
                                           
                                           NSMutableArray *exchangeableCoupons = [NSMutableArray new];
                                           for (NSDictionary *pe in [d objectForKey:@"points_exchanges"]) {
                                               PNPLoyaltyExchanges *p = [[PNPLoyaltyExchanges alloc] initWithIdentifier:[pe objectForKey:@"id"] loyaltyIdentifier:[pe objectForKey:@"loyalty_id"] points:[pe objectForKey:@"points"] fixedAmount:[self clearAmount:NULL_TO_NIL([pe objectForKey:@"fixed_amount"])] percentageAmount:[self clearAmount:NULL_TO_NIL([pe objectForKey:@"percentage_amount"])] gift:NULL_TO_NIL([pe objectForKey:@"gift"])];
                                               [exchangeableCoupons addObject:p];
                                           }
                                           
                                           NSMutableArray *commerces = [NSMutableArray new];
                                           for (NSDictionary *co in [d objectForKey:@"commerces"]) {
                                               [commerces addObject:[[PNPLoyaltyCommerce alloc] initWithIdentifier:[co objectForKey:@"id"] name:[co objectForKey:@"name"]]];
                                           }


                                           PNPLoyaltyCompany *company = [[PNPLoyaltyCompany alloc] initWithName:[[d objectForKey:@"company"] objectForKey:@"name"]];

                                           
                                           NSMutableArray *benefits = [NSMutableArray new];
                                           for (NSDictionary *be in [d objectForKey:@"loyalty_benefits"]) {
                                               [benefits addObject:[[PNPLoyaltyBenefits alloc] initWithIdentifier:[be objectForKey:@"id"] percentageAmount:[be objectForKey:@"percentage_amount"] startDate:[df dateFromString:[be objectForKey:@"start_date"]] endDate:[df dateFromString:[be objectForKey:@"end_date"]]]];
                                           }
                                           
                                           PNPLoyalty *l = [[PNPLoyalty alloc] initWithIdentifier:[[d objectForKey:@"loyalty"] objectForKey:@"id"] userId:[[d objectForKey:@"loyalty"] objectForKey:@"user_id"] title:[[d objectForKey:@"loyalty"] objectForKey:@"title"] description:[[d objectForKey:@"loyalty"] objectForKey:@"description"] shortDescription:[[d objectForKey:@"loyalty"] objectForKey:@"description_short"] logoUrl:[[d objectForKey:@"loyalty"] objectForKey:@"logo"] status:[[d objectForKey:@"loyalty"] objectForKey:@"status"] startDate:[df dateFromString:[[d objectForKey:@"loyalty"] objectForKey:@"start_date"]] endDate:[df dateFromString:[[d objectForKey:@"loyalty"] objectForKey:@"end_data"]] amount:[[d objectForKey:@"loyalty"] objectForKey:@"amount"] points:[[d objectForKey:@"loyalty"] objectForKey:@"points"] suscriptionFields:memberFields exchangableCoupons:exchangeableCoupons commerces:commerces company:company benefits:benefits registered:[[d objectForKey:@"registered"] boolValue]];
                                           [loyalties addObject:l];
                                           if(successHandler) successHandler(loyalties);
                                       }

                                       @catch (NSException *exception) {
                                           NSLog(@"no se ha podido parsear la fidelity %@ por el error %@",d,exception);
                                       }
                                   }
                                   if(successHandler) successHandler(loyalties);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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

-(void) subscribeToLoyalty:(PNPLoyalty *) loyalty
                    params:(NSDictionary *) params
       withSuccessCallback:(PnPSuccessHandler) successHandler
          andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    NSError *jerror;
    NSMutableDictionary *paramDicc = [[NSMutableDictionary alloc] initWithDictionary:params];
    [paramDicc setObject:loyalty.identifier forKey:@"loyalty_id"];
    NSString *pparams = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:paramDicc
                                                                                       options:0
                                                                                         error:&jerror]
                                              encoding:NSUTF8StringEncoding];
    NSLog(@"%@",pparams);
    
    
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"coupons/user_call"]
                   usingParameters:@{
                                     @"action":@"loyalty_member.json",
                                     @"method": @"post",
                                     @"fields": pparams,
                                     }
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
                                                                   objectForKey:@"user_call"];
                               NSLog(@"%@",responseDictionary);
                               
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler) successHandler();
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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


-(void) getUserDataForLoyalty:(PNPLoyalty *) loyalty
          withSuccessCallback:(PnPLoyaltyUserDataSuccessHandler) successHandler
             andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"coupons/user_call"]
                   usingParameters:@{
                                     @"action":[NSString stringWithFormat:@"loyalties/%@/member_view.json",loyalty.identifier],
                                     @"method": @"get",
                                     @"fields": @"{}",
                                     }
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
                                                                   objectForKey:@"user_call"];
                               
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   PNPLoyaltyUserData *u = [[PNPLoyaltyUserData alloc] initWithLoyaltyId:loyalty.identifier actualPoints:[[responseDictionary objectForKey:@"data"] objectForKey:@"actual_points"] lastPoints:[[responseDictionary objectForKey:@"data"] objectForKey:@"last_points"] code:[[responseDictionary objectForKey:@"data"] objectForKey:@"code"]];
                                   successHandler(u);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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

-(void) getCouponWithCode:(NSString *) code
            withSuccessCallback:(PnPCouponSuccessHandler) successHandler
               andErrorCallback:(PnPGenericErrorHandler) errorHandler{

    NSPredicate *p = [NSPredicate predicateWithFormat:@"ccode == %@",code];
    [self getCouponsWithSuccessCallback:^(NSArray *data) {
        NSLog(@"%@",code);
        NSLog(@"%@",data);
        PNPCoupon *c = [[data filteredArrayUsingPredicate:p] firstObject];
        if(!c){
            if(errorHandler) return errorHandler([[PNPGenericWebserviceError alloc]
                                                  initWithDomain:@"PNPGenericWebserviceError"
                                                  code:-6060
                                                  userInfo:nil]);
        }
        if (successHandler)successHandler(c);
    } andErrorCallback:errorHandler];
}

-(void) exchangeCouponForPNPLoyaltyExchange:(PNPLoyaltyExchanges *) exchange
                                 memberCode:(NSString * )code
                        withSuccessCallback:(PnPNSStringSucceddHandler) successHandler
                           andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    NSError *jerror;
    NSMutableDictionary *paramDicc = [NSMutableDictionary new];
    [paramDicc setObject:exchange.identifier forKey:@"points_exchange_id"];
    NSString *pparams = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:paramDicc
                                                                                       options:0
                                                                                         error:&jerror]
                                              encoding:NSUTF8StringEncoding];
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"coupons/user_call"]
                   usingParameters:@{
                                     @"action":[NSString stringWithFormat:@"loyalty_member/%@/exchange.json",code],
                                     @"method": @"post",
                                     @"fields": pparams,
                                     }
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
                                                                   objectForKey:@"user_call"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler)successHandler([[[responseDictionary objectForKey:@"data"] objectForKey:@"coupon"] objectForKey:@"code"]);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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

-(void) getCouponDetailsForCode:(NSString *) couponCode
            withSuccessCallback:(PnPCouponSuccessHandler) successHandler
               andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }

    
    [self getCommerceDataWithSuccessCallback:^(PNPCommerce *commerce) {
        NSError *jerror;
        NSMutableDictionary *paramDicc = [NSMutableDictionary new];
        [paramDicc setObject:commerce.commerceId forKey:@"commerce_id"];
        NSString *pparams = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:paramDicc
                                                                                           options:0
                                                                                             error:&jerror]
                                                  encoding:NSUTF8StringEncoding];
        NSLog(@"%@",pparams);
        
        [NXOAuth2Request performMethod:@"POST"
                            onResource:[self generateUrl:@"coupons/commerce_call"]
                       usingParameters:@{
                                         @"action":[NSString stringWithFormat:@"coupons/%@.json",couponCode],
                                         @"method": @"get",
                                         @"fields": pparams,
                                         }
                           withAccount:self.userAccount
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
                                                                       objectForKey:@"commerce_call"];
                                   if(parseError){
                                       if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                          code:[parseError code]
                                                                                                      userInfo:parseError.userInfo]);
                                       return;
                                   }
                                   if([[responseDictionary objectForKey:@"success"] boolValue]){
                                       NSDateFormatter *df = [[NSDateFormatter alloc] init];
                                       [df setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Madrid"]];
                                       [df setDateFormat:@"yyyy-MM-dd"];
                                       NSDictionary *d = [responseDictionary objectForKey:@"data"];
                                       NSLog(@"%@",d);
                                       @try {
                                               Class class = [PNPCoupon class];
                                               NSString *type =[d objectForKey:@"type"];
                                               if([type isEqualToString:@"coupon"]){
                                                   if([[d objectForKey:@"limit_uses"] intValue] == 1){
                                                       class = [PNPCPOneTime class];
                                                   }else{
                                                       class = [PNPCPMultiUssage class];
                                                   }
                                               }else if ( [type isEqualToString:@"onceaday"]){
                                                   class = [PNPCPDaily class];
                                               }else if([type isEqualToString:@"stamp"]){
                                                   class = [PNPCPStampCard class];
                                               }else if ([type isEqualToString:@"exchange"]){
                                                   class = [PNPCPExchange class];
                                               }else if ([type isEqualToString:@"loyalty"]){
                                                   class = [PNPCPLoyalty class ];
                                               }
                                           PNPCoupon *c = [[class alloc] initWithCode:couponCode identifier:nil loyaltyIdentifier:nil actualUses:NULL_TO_NIL([d objectForKey:@"actual_uses"]) limitUses:NULL_TO_NIL([d objectForKey:@"limit_uses"]) companyName:nil title:nil description:nil shortDescription:nil logoUrl:nil brandLogoUrl:nil startDate:nil endDate:[df dateFromString:NULL_TO_NIL([d objectForKey:@"end_date"])] validDays:NULL_TO_NIL([d objectForKey:@"valid_days"]) timeRanges:NULL_TO_NIL([d objectForKey:@"time_ranges"]) fixedAmount:[self clearAmount:NULL_TO_NIL([d objectForKey:@"fixed_amount"])] percentageAmount:[self clearAmount:NULL_TO_NIL([d objectForKey:@"percentage_amount"])] gift:NULL_TO_NIL([d objectForKey:@"gift"]) favorite:NO viewed:NO status:nil  products:NULL_TO_NIL([d objectForKey:@"products"]) giftProducts:NULL_TO_NIL([d objectForKey:@"gift_products"]) type:NULL_TO_NIL([d objectForKey:@"type"])];
                                               if(successHandler) successHandler(c);

                                           }
                                           @catch (NSException *exception) {
                                               NSLog(@"no se ha podido parsear el coupon %@ por el error %@",d,exception);
                                               if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                             initWithDomain:@"PNPGenericWebserviceError"
                                                                             code:-6060
                                                                             userInfo:responseDictionary]);
                                           }
                                   }else{
                                       if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                     initWithDomain:@"PNPGenericWebserviceError"
                                                                     code:-6060
                                                                     userInfo:responseDictionary]);
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


    } andErrorCallback:errorHandler];
    

    
    
}


-(void) exchangeCoupon:(NSString *) couponCode
   withSuccessCallback:(PnPSuccessHandler)successHandler
      andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    
    [self getCommerceDataWithSuccessCallback:^(PNPCommerce *commerce) {
        NSError *jerror;
        NSMutableDictionary *paramDicc = [NSMutableDictionary new];
        [paramDicc setObject:commerce.commerceId forKey:@"commerce_id"];
        NSString *pparams = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:paramDicc
                                                                                           options:0
                                                                                             error:&jerror]
                                                  encoding:NSUTF8StringEncoding];
        
        [NXOAuth2Request performMethod:@"POST"
                            onResource:[self generateUrl:@"coupons/commerce_call"]
                       usingParameters:@{
                                         @"action":[NSString stringWithFormat:@"coupons/%@.json",couponCode],
                                         @"method": @"post",
                                         @"fields": pparams,
                                         }
                           withAccount:self.userAccount
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
                                                                       objectForKey:@"commerce_call"];
                                   if(parseError){
                                       if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                          code:[parseError code]
                                                                                                      userInfo:parseError.userInfo]);
                                       return;
                                   }
                                   if([[responseDictionary objectForKey:@"success"] boolValue]){
                                       if(successHandler) successHandler();
                                   }else{
                                       if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                     initWithDomain:@"PNPGenericWebserviceError"
                                                                     code:-6060
                                                                     userInfo:responseDictionary]);
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
        
        
    } andErrorCallback:errorHandler];
}


-(void) getFidelityForCode:(NSString *) code
       withSuccessCallback:(PnPNSNumberSucceddHandler)successHandler
          andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    [self getCommerceDataWithSuccessCallback:^(PNPCommerce *commerce) {
        NSError *jerror;
        NSMutableDictionary *paramDicc = [NSMutableDictionary new];
        [paramDicc setObject:commerce.commerceId forKey:@"commerce_id"];
        NSString *pparams = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:paramDicc
                                                                                           options:0
                                                                                             error:&jerror]
                                                  encoding:NSUTF8StringEncoding];
        [NXOAuth2Request performMethod:@"POST"
                            onResource:[self generateUrl:@"coupons/user_call"]
                       usingParameters:@{
                                         @"action":[NSString stringWithFormat:@"loyalty_member/%@/info.json",code],
                                         @"method": @"get",
                                         @"fields":pparams,
                                         }
                           withAccount:self.userAccount
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
                                                                       objectForKey:@"user_call"];
                                   if(parseError){
                                       if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                          code:[parseError code]
                                                                                                      userInfo:parseError.userInfo]);
                                       return;
                                   }
                                   if([[responseDictionary objectForKey:@"success"] boolValue]){
                                       
                                       NSArray *beneFits =[[[responseDictionary objectForKey:@"data"] objectForKey:@"Loyalty"]  objectForKey:@"LoyaltyBenefit"];
                                       if(beneFits.count > 0){
                                           NSDictionary *loyaltyBenefit = [[[[responseDictionary objectForKey:@"data"] objectForKey:@"Loyalty"]  objectForKey:@"LoyaltyBenefit"] firstObject];
                                           NSNumber *percentageDiscount = [ self clearAmount:[loyaltyBenefit objectForKey:@"percentage_amount"]];
                                           if(successHandler) successHandler(percentageDiscount);
                                       }else{
                                           if(successHandler) successHandler(@0);
                                       }
                                       

                                   }else{
                                       if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                     initWithDomain:@"PNPGenericWebserviceError"
                                                                     code:-6060
                                                                     userInfo:responseDictionary]);
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

        
        
        
        
    } andErrorCallback:errorHandler];
        
    }





#pragma mark - Festivals

-(void) registerFestivalUserWithEmail:(NSString *) email
                             password:(NSString *) password
                                 name:(NSString *) name
                              surname:(NSString *) surname
                               prefix:(NSString *) prefix
                                phone:(NSString *) phone
                                  pin:(NSNumber *) pin
                                 male:(BOOL ) isMale
                            birthdate:(NSDate *) date
                            reference:(NSString *) reference
                  withSuccessCallback:(PnPSuccessHandler) successHandler
                     andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd"];
    [params setObject:email  forKey:@"username"];
    [params setObject:password  forKey:@"password"];
    [params setObject:email     forKey:@"email"];
    [params setObject:name      forKey:@"name"];
    [params setObject:surname   forKey:@"surname"];
    [params setObject:prefix    forKey:@"prefix"];
    [params setObject:phone     forKey:@"phone"];
    [params setObject:pin       forKey:@"pin"];
    [params setObject:reference forKey:@"reference"];
    [params setObject:[df stringFromDate:date] forKey:@"birthdate"];
    
    if(isMale){
        [params setObject:@"M" forKey:@"sex"];
    }else{
        [params setObject:@"F" forKey:@"sex"];
    }
    
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[NSURL URLWithString:@"https://electrogateway.paynopain.com/users/add"]
                   usingParameters:params
                       withAccount:nil
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       NSLog(@"%@",[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                       if(!error){
                           @try {
                               NSError *parseError;
                               
                               
                               NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError];
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
                                                                       userInfo:@{@"errors":[responseDictionary objectForKey:@"data"],@"message":[responseDictionary objectForKey:@"message"],@"code":[responseDictionary objectForKey:@"code"]}]);
                                   
                                   
                                   
                                   
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

-(void) checkFestivalGift{
    if(!self.userAccount.accessToken) return;
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[NSURL URLWithString:@"https://electrogateway.paynopain.com/gifts/add"]
                   usingParameters:@{@"access_token":self.userAccount.accessToken.accessToken}
                       withAccount:nil
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       NSLog(@"%@",[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                   }];

    
}

#pragma mark - Promotions

-(void) getPromotions:(PnPPromoSuccessHandler) successHandler
     andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"promos/get"]
                   usingParameters: @{@"type":@"customRecharge"}
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

                                   PNPPromo *p = [[PNPPromo alloc] initWithUserCount:[[responseDictionary objectForKey:@"data"] objectForKey:@"user_count"] maxUserCount:[[responseDictionary objectForKey:@"data"] objectForKey:@"max_user_count"] active:[[[responseDictionary objectForKey:@"data"] objectForKey:@"active"] boolValue] amount:[self clearAmount:[[responseDictionary objectForKey:@"data"] objectForKey:@"number"]] minAmount:nil identifier:[[responseDictionary objectForKey:@"data"] objectForKey:@"id"]];
                                   if(successHandler) successHandler(p);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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

-(void) getRechargePromotions:(PnPPromoSuccessHandler) successHandler
     andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"promos/get"]
                   usingParameters: @{@"type":@"extraRecharge"}
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
                               NSLog(@"%@",responseDictionary);
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   NSLog(@"%@",responseDictionary);
                                   PNPPromo *p = [[PNPPromo alloc] initWithUserCount:[[responseDictionary objectForKey:@"data"] objectForKey:@"user_count"] maxUserCount:[[responseDictionary objectForKey:@"data"] objectForKey:@"max_user_count"] active:[[[responseDictionary objectForKey:@"data"] objectForKey:@"active"] boolValue] amount:[self clearAmount:[[responseDictionary objectForKey:@"data"] objectForKey:@"number"]] minAmount:[self clearAmount:[[responseDictionary objectForKey:@"data"] objectForKey:@"min_number"]] identifier:[[responseDictionary objectForKey:@"data"] objectForKey:@"id"]];
                                   if(successHandler) successHandler(p);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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

-(void) exchangePromo:(PNPPromo *) promo
  withSuccessCallback: (PnPSuccessHandler) successHandler
     andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"promos/exchange"]
                   usingParameters: @{@"type":@"customRecharge",@"number":@0}
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
                                                                   objectForKey:@"exchange"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler) successHandler();
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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

#pragma mark - Catalogue

-(void) getProductCategoriesWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                        andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    NSError *jerror;
    NSMutableDictionary *paramDicc = [NSMutableDictionary new];
    [paramDicc setObject:@1 forKey:@"products"];
    NSString *pparams = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:paramDicc
                                                                                       options:0
                                                                                         error:&jerror]
                                              encoding:NSUTF8StringEncoding];
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"ProductCatalog/call.json"]
                   usingParameters:@{
                                     @"action":[NSString stringWithFormat:@"list/categories.json"],
                                     @"fields": pparams,
                                     }
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
                                                                   objectForKey:@"call"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   NSArray *data = [responseDictionary objectForKey:@"data"];
                                   NSMutableArray *categories = [NSMutableArray new];
                                   NSPredicate *categoryPredicate = [NSPredicate predicateWithFormat:@"Category.parent_id == %@",[NSNull null]];
                                   NSArray *fcategories = [data filteredArrayUsingPredicate:categoryPredicate];
                                   for (NSDictionary *d in fcategories){
                                       NSString *cname =[[d objectForKey:@"Category"] objectForKey:@"name"];
                                       if (cname.length > 0) {
                                           cname = [cname stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                                                  withString:[[cname substringToIndex:1] uppercaseString]];
                                       }
                                       
                                       [categories addObject:[[PNPCCategory alloc] initWithIdentifier:[[d objectForKey:@"Category"] objectForKey:@"id"] name:cname imgUrl:[[d objectForKey:@"Category"] objectForKey:@"img_url"] products:nil]];
                                   }
                                   
                                   NSPredicate *productsPredicate = [NSPredicate predicateWithFormat:@"Category.parent_id != %@",[NSNull null]];
                                   NSArray *products = [data filteredArrayUsingPredicate:productsPredicate];

                                   for (NSDictionary *p in products) {
                                       NSMutableArray *pproducts = [NSMutableArray new];

                                       NSMutableArray *variants = [NSMutableArray new];
                                       for (NSDictionary * v in [p objectForKey:@"Product"]){
                                           [variants addObject:[[PNPCVariant alloc] initWithName:[[v objectForKey:@"name"] stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[[v objectForKey:@"name"] substringToIndex:1] uppercaseString]] price:[self clearAmount:[v objectForKey:@"price"]] identifier:[v objectForKey:@"id"]]];
                                       }
                                       [pproducts addObject:[[PNPCProduct alloc] initWithIdentifier:[[p objectForKey:@"Category"] objectForKey:@"id"] name:[[[p objectForKey:@"Category"] objectForKey:@"name"] stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[[[p objectForKey:@"Category"] objectForKey:@"name"] substringToIndex:1] uppercaseString]] imgUrl:[[p objectForKey:@"Category"] objectForKey:@"img_url"] variants:variants]];
                                       
                                       NSPredicate *categoryPredicate = [NSPredicate predicateWithFormat:@"identifier == %@",[[p objectForKey:@"Category"] objectForKey:@"parent_id"]];
                                       
                                       NSArray *ccc = [categories filteredArrayUsingPredicate:categoryPredicate];
                                       
                                       if(ccc.count == 1){
                                           PNPCCategory *c = [ccc firstObject];
                                           [categories removeObject:c];
                                           NSMutableArray *oldProduct = [NSMutableArray arrayWithArray:c.products];
                                           for (PNPCProduct *pp in pproducts) {
                                               [oldProduct addObject:pp];
                                           }
                                           c.products = oldProduct;
                                           [categories addObject:c];
                                       }else{
                                           categoryPredicate = [NSPredicate predicateWithFormat:@"Category.id == %@",[[p objectForKey:@"Category"] objectForKey:@"parent_id"]];
                                           ccc = [data filteredArrayUsingPredicate:categoryPredicate];
                                           if(ccc.count == 1){
                                               NSDictionary *category = [ccc firstObject];
                                               [categories addObject:[[PNPCCategory alloc] initWithIdentifier:[[category objectForKey:@"Category"] objectForKey:@"id"] name:[[category objectForKey:@"Category"] objectForKey:@"name"] imgUrl:[[category objectForKey:@"Category"] objectForKey:@"img_url"] products:pproducts]];
                                           }
                                       }
                                   }
                                   if(successHandler) successHandler(categories);
                                   
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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


-(void) addCategoryWithName:(NSString *) name
                   andImage:(UIImage *) image
        withSuccessCallback:(PnPNSNumberSucceddHandler) successHandler
           andErrorCallback:(PnPGenericErrorHandler) errorHandler{

    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
    NSString *base64encodedImage = [imageData base64EncodedString];
    
    base64encodedImage = [NSString stringWithFormat:@"data:image/jpg;base64,%@",base64encodedImage];
    
    NSError *jerror;
    
    NSMutableDictionary *paramDicc = [NSMutableDictionary new];
    [paramDicc setObject:name forKey:@"name"];
    [paramDicc setObject:base64encodedImage forKey:@"img_url"];
    
    NSString *pparams = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:paramDicc
                                                                                       options:0
                                                                                         error:&jerror]
                                              encoding:NSUTF8StringEncoding];
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"ProductCatalog/call.json"]
                   usingParameters:@{
                                     @"action":[NSString stringWithFormat:@"categories.json"],
                                     @"fields": pparams,
                                     }
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
                                                                   objectForKey:@"call"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){

                                   if(successHandler) successHandler([responseDictionary objectForKey:@"data"]);
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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

-(void) deleteCategory:(PNPCCategory *) category
   withSuccessCallback:(PnPSuccessHandler) successHandler
      andErrorCallback:(PnPGenericErrorHandler ) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }

    
    NSError *jerror;
    
    NSMutableDictionary *paramDicc = [NSMutableDictionary new];

    [paramDicc setObject:@"remove" forKey:@"reason"];
    [paramDicc setObject:@1 forKey:@"removeProducts"];
    
    NSString *pparams = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:paramDicc
                                                                                       options:0
                                                                                         error:&jerror]
                                              encoding:NSUTF8StringEncoding];
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"ProductCatalog/call.json"]
                   usingParameters:@{
                                     @"action":[NSString stringWithFormat:@"categories/%@/delete.json",category.identifier],
                                     @"fields": pparams,
                                     }
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
                                                                   objectForKey:@"call"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler) successHandler();
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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



-(void) deleteProduct:(PNPCProduct *) product
  withSuccessCallback:(PnPSuccessHandler) successHandler
     andErrorCallback:(PnPGenericErrorHandler ) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    
    NSError *jerror;
    
    NSMutableDictionary *paramDicc = [NSMutableDictionary new];
    
    [paramDicc setObject:@"remove" forKey:@"reason"];
    [paramDicc setObject:@1 forKey:@"removeProducts"];
    
    NSString *pparams = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:paramDicc
                                                                                       options:0
                                                                                         error:&jerror]
                                              encoding:NSUTF8StringEncoding];
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"ProductCatalog/call.json"]
                   usingParameters:@{
                                     @"action":[NSString stringWithFormat:@"categories/%@/delete.json",product.identifier],
                                     @"fields": pparams,
                                     }
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
                                                                   objectForKey:@"call"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler) successHandler();
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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


-(void) deleteVariant:(PNPCVariant *) variant
  withSuccessCallback:(PnPSuccessHandler) successHandler
     andErrorCallback:(PnPGenericErrorHandler ) errorHandler{
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    
    NSError *jerror;
    
    NSMutableDictionary *paramDicc = [NSMutableDictionary new];
    
    [paramDicc setObject:@"remove" forKey:@"reason"];
    
    NSString *pparams = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:paramDicc
                                                                                       options:0
                                                                                         error:&jerror]
                                              encoding:NSUTF8StringEncoding];
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"ProductCatalog/call.json"]
                   usingParameters:@{
                                     @"action":[NSString stringWithFormat:@"products/%@/delete.json",variant.identifer],
                                     @"fields": pparams,
                                     }
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           @try {
                               NSError *parseError;
                               NSLog(@"%@",[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"call"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler) successHandler();
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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


-(void) updateCategory:(PNPCCategory *) category
                 image:(UIImage *) image
   withSuccessCallback:(PnPSuccessHandler) successHandler
      andErrorCallback:(PnPGenericErrorHandler ) errorHandler{
    
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    
    NSError *jerror;
    
    NSMutableDictionary *paramDicc = [NSMutableDictionary new];
    
    [paramDicc setObject:category.name forKey:@"name"];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
    NSString *base64encodedImage = [imageData base64EncodedString];
    
    base64encodedImage = [NSString stringWithFormat:@"data:image/jpg;base64,%@",base64encodedImage];
    
    [paramDicc setObject:base64encodedImage forKey:@"img_url"];
    
    NSString *pparams = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:paramDicc
                                                                                       options:0
                                                                                         error:&jerror]
                                              encoding:NSUTF8StringEncoding];
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"ProductCatalog/call.json"]
                   usingParameters:@{
                                     @"action":[NSString stringWithFormat:@"categories/%@/edit.json",category.identifier],
                                     @"fields": pparams,
                                    }
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
                                                                   objectForKey:@"call"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler) successHandler();
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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


-(void) addProduct:(PNPCProduct *) product
       forCategory:(PNPCCategory *) category
             image:(UIImage *) image
withSuccessCallback:(PnPSuccessHandler) successHandler
  andErrorCallback:(PnPGenericErrorHandler ) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    NSError *jerror;
    NSMutableDictionary *paramDicc = [NSMutableDictionary new];
    [paramDicc setObject:product.name forKey:@"name"];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
    NSString *base64encodedImage = [imageData base64EncodedString];
    base64encodedImage = [NSString stringWithFormat:@"data:image/jpg;base64,%@",base64encodedImage];
    [paramDicc setObject:base64encodedImage forKey:@"img_url"];
    [paramDicc setObject:category.identifier forKey:@"category_id"];
    
    NSString *pparams = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:paramDicc
                                                                                       options:0
                                                                                         error:&jerror]
                                              encoding:NSUTF8StringEncoding];
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"ProductCatalog/call.json"]
                   usingParameters:@{
                                     @"action":[NSString stringWithFormat:@"categories.json"],
                                     @"fields": pparams,
                                     }
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
                                                                   objectForKey:@"call"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   product.identifier = [responseDictionary objectForKey:@"data"];
                                   int __block count = 0;
                                   for (PNPCVariant *v in product.variants) {
                                       [self addProductVariant:v forProduct:product withSuccessHandler:^{
                                           if(++count == product.variants.count){
                                               if(successHandler) successHandler();
                                           }
                                       } andErrorHandler:errorHandler];
                                   }
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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

-(void) updateProduct:(PNPCProduct *) product
                image:(UIImage *) image
  withSuccessCallback:(PnPSuccessHandler) successHandler
     andErrorCallback:(PnPGenericErrorHandler ) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    NSError *jerror;
    NSMutableDictionary *paramDicc = [NSMutableDictionary new];
    [paramDicc setObject:product.name forKey:@"name"];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
    NSString *base64encodedImage = [imageData base64EncodedString];
    base64encodedImage = [NSString stringWithFormat:@"data:image/jpg;base64,%@",base64encodedImage];
    [paramDicc setObject:base64encodedImage forKey:@"img_url"];
    
    NSString *pparams = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:paramDicc
                                                                                       options:0
                                                                                         error:&jerror]
                                              encoding:NSUTF8StringEncoding];
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"ProductCatalog/call.json"]
                   usingParameters:@{
                                     @"action":[NSString stringWithFormat:@"categories/%@/edit.json",product.identifier],
                                     @"fields": pparams,
                                     }
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           
                           @try {
                               NSError *parseError;
                               NSLog(@"%@",[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"call"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   int __block count = 0;
                                   for (PNPCVariant *v in product.variants) {
                                       
                                       if(v.identifer == nil){
                                           [self addProductVariant:v forProduct:product withSuccessHandler:^{
                                               if(++count == product.variants.count){
                                                   if(successHandler) successHandler();
                                               }
                                           } andErrorHandler:errorHandler];
                                       }else{
                                           [self updateVariant:v fromProduct:product withSuccessHandler:^{
                                               if(++count == product.variants.count){
                                                   if(successHandler) successHandler();
                                               }
                                           } andErrorHandler:errorHandler];
                                       }

                                   }
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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

-(void) addProductVariant:(PNPCVariant *) variant
               forProduct:(PNPCProduct *) product
       withSuccessHandler:(PnPSuccessHandler ) successHandler
          andErrorHandler:(PnPGenericErrorHandler) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    
    
    
    NSError *jerror;
    NSMutableDictionary *paramDicc = [NSMutableDictionary new];
    [paramDicc setObject:variant.name forKey:@"name"];
    NSLog(@"PRODUCTO %@",product);
    [paramDicc setObject:product.identifier forKey:@"category_id"];
    
    NSNumber *price = [NSNumber numberWithFloat:variant.price.floatValue * 100];
    
    [paramDicc setObject:price forKey:@"price"];
    
    NSString *pparams = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:paramDicc
                                                                                       options:0
                                                                                         error:&jerror]
                                              encoding:NSUTF8StringEncoding];
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"ProductCatalog/call.json"]
                   usingParameters:@{
                                     @"action":[NSString stringWithFormat:@"products.json"],
                                     @"fields": pparams,
                                     }
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
                                                                   objectForKey:@"call"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   
                                   if(successHandler) successHandler();
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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


-(void) updateVariant:(PNPCVariant *) variant
          fromProduct:(PNPCProduct *) product
   withSuccessHandler:(PnPSuccessHandler ) successHandler
      andErrorHandler:(PnPGenericErrorHandler) errorHandler{
    
    if(![self userIsLoggedIn]){
        NSLog(@"No user logged in.");
        return;
    }
    NSError *jerror;
    NSMutableDictionary *paramDicc = [NSMutableDictionary new];
    [paramDicc setObject:variant.name forKey:@"name"];
    NSNumber *price = [NSNumber numberWithFloat:variant.price.floatValue * 100];
    [paramDicc setObject:product.identifier forKey:@"category_id"];

    [paramDicc setObject:price forKey:@"price"];
    
    NSString *pparams = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:paramDicc
                                                                                       options:0
                                                                                         error:&jerror]
                                              encoding:NSUTF8StringEncoding];
    
    NSLog(@"%@",pparams);
    
    [NXOAuth2Request performMethod:@"POST"
                        onResource:[self generateUrl:@"ProductCatalog/call.json"]
                   usingParameters:@{
                                     @"action":[NSString stringWithFormat:@"products/%@/edit.json",variant.identifer],
                                     @"fields": pparams,
                                     }
                       withAccount:self.userAccount
                           timeout:PNP_REQUEST_TIMEOUT
               sendProgressHandler:nil
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       if(!error){
                           
                           @try {
                               NSError *parseError;
                               NSLog(@"%@",[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                               NSDictionary *responseDictionary = [[NSJSONSerialization JSONObjectWithData:responseData
                                                                                                   options:0
                                                                                                     error:&parseError]
                                                                   objectForKey:@"call"];
                               if(parseError){
                                   if(errorHandler) errorHandler( [[PNPNotAJsonError alloc] initWithDomain:parseError.domain
                                                                                                      code:[parseError code]
                                                                                                  userInfo:parseError.userInfo]);
                                   return;
                               }
                               if([[responseDictionary objectForKey:@"success"] boolValue]){
                                   if(successHandler) successHandler();
                               }else{
                                   if(errorHandler)errorHandler([[PNPGenericWebserviceError alloc]
                                                                 initWithDomain:@"PNPGenericWebserviceError"
                                                                 code:-6060
                                                                 userInfo:responseDictionary]);
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

@implementation PNPPreProductionEnvironment

-(id) init{
    self=[super initWithUrl:[NSURL URLWithString:@"https://pre-core.paynopain.com"]];
    return self;
}

@end


