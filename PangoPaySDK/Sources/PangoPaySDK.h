//
//  PangoPaySDK.h
//  PaynoPain
//
//  Created by Christian Bongardt on 21/11/13.
//  Copyright (c) 2013 PaynoPain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PNPConnectionError.h"
#import "PNPWebserviceErrors.h"
#import "PNPDataContainer.h"
#import "Base64.h"
#import <CoreLocation/CLLocation.h>

#pragma mark - Client definitions


#pragma mark - PangoPaySDK Declaration

@class PNPEnvironment;
@interface PangoPaySDK : NSObject

typedef void(^PnPSuccessHandler)();
typedef void(^PnPLoginSuccessHandler)();
typedef void(^PnPLoginErrorHandler)(NSError *error);
typedef void(^PnPLogoutHandler)();
typedef void(^PnPGenericErrorHandler)(NSError *error);
typedef void(^PnpUserDataSuccessHandler)(PNPUser *user);
typedef void(^PnpUserValidationSuccessHandler)(PNPUserValidation *val);
typedef void(^PnpPangoDataSuccessHandler)(PNPPango *pango);
typedef void(^PnpUserAvatarSuccessHandler)(UIImage *avatar);
typedef void(^PnPGenericNSAarraySucceddHandler)(NSArray * data);
typedef void(^PnPNSNumberSucceddHandler)(NSNumber * number);
typedef void(^PnPTransactionReceiverSuccessHandler)(PNPTransactionReceiverUser * receiver);
typedef void(^PnPPaymentRequestSuccessHandler)(PNPPaymentRequest * request);
+ (instancetype)sharedInstance;


-(void) setupWithClientId:(NSString *) clientId secret:(NSString *) secret environment:(PNPEnvironment *) environment scope:(NSArray *) scope;


#pragma mark - Authentication Methods
-(NSArray *) setupLoginObserversWithSuccessCallback:(PnPLoginSuccessHandler)successHandler
                                   andErrorCallback:(PnPLoginErrorHandler)errorHandler;
-(void) addAccesRefreshTokenExpiryObserver:(PnPLogoutHandler) callback;

-(void) loginWithUsername:(NSString *) username
              andPassword:(NSString *) password;
-(BOOL) isUserLoggedIn;
-(void) logout;

#pragma mark - User Methods
-(void) getUserDataWithSuccessCallback:(PnpUserDataSuccessHandler) successHandler
                      andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) getUserAvatarWithSuccessCallback:(PnpUserAvatarSuccessHandler) successHandler
                        andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) deleteUserAvatarWithSuccessCallback:(PnPSuccessHandler) successHandler
                           andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) uploadAvatar:(UIImage *)avatar
 withSuccessCallback:(PnPSuccessHandler) successHandler
    andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(NSURL *) generateAvatarUrlFromPrefix:(NSString *) prefix
                              andPhone:(NSString *) phone;


-(void) registerUserWithUsername:(NSString *) username
                        password:(NSString *) password
                            name:(NSString *) name
                         surname:(NSString *) surname
                           email:(NSString *) email
                          prefix:(NSString *) prefix
                           phone:(NSString *) phone
                             pin:(NSNumber *) pin
                            male:(BOOL) isMale
             withSuccessCallback:(PnPSuccessHandler) successHandler
                andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) resendTokenWithSuccessCallback:(NSString *) prefix
                                 phone:(NSString *) phone
                   withSuccessCallback:(PnPSuccessHandler) successHandler
                      andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) confirmUserWithToken:(NSString *) token
         withSuccessCallback:(PnPSuccessHandler) successHandler
            andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) requestRecoverPinWithSuccessCallback:(PnPSuccessHandler) successHandler
                            andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) recoverPinwithNewPin:(NSString *) pin
                    andToken:(NSString *) token
         withSuccessCallback:(PnPSuccessHandler) successHandler
            andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) registerDevice:(NSData *) deviceToken
   withSuccessCallback:(PnPSuccessHandler) successHandler
      andErrorCallback:(PnPGenericErrorHandler) errorHandler;


-(void) requestRecoverPassword:(NSString *)email
           withSuccessCallback:(PnPSuccessHandler) successHandler
              andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) recoverPassword:(NSString *) password
                  token:(NSString *) token
    withSuccessCallback:(PnPSuccessHandler) successHandler
       andErrorCallback:(PnPGenericErrorHandler) errorHandler;


-(void) changePhone:(NSString *)prefix
              phone:(NSString *)phone
                pin:(NSString *)pin
         confirmUrl:(NSURL *)confirmUrl
withSuccessCallback:(PnPSuccessHandler)successHandler
   andErrorCallback:(PnPGenericErrorHandler)errorHandler;

-(void) confirmChangePhone:(NSString *)token
       withSuccessCallback:(PnPSuccessHandler) successHandler
          andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) getUserValidationStatusWithSuccessCallback:(PnpUserValidationSuccessHandler) successHandler
                                  andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) uploadIdCard:(UIImage *) front
             andBack:(UIImage *) back
 withSuccessCallback:(PnPSuccessHandler) successHandler
    andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) changePassword:(NSString * ) password
            toPassword:(NSString *) newpassword
   withSuccessCallback:(PnPSuccessHandler) successHandler
      andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) changePin:(NSString * ) pin
            toPin:(NSString *) newpin
withSuccessCallback:(PnPSuccessHandler) successHandler
 andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) editUserSetName:(NSString *) name
                surname:(NSString *) surname
                  email:(NSString *) email
                 prefix:(NSString *) prefix
                  phone:(NSString *) phone
                withPin:(NSString *) pin
             confirmUrl:(NSURL *) url
    withSuccessCallback:(PnPSuccessHandler) successHandler
       andErrorCallback:(PnPGenericErrorHandler) errorHandler;

#pragma mark - Credit cards

-(void) getCreditCardsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                         andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) createCard:(PNPCreditCard *) card
withSuccessCallback:(PnPSuccessHandler) successHandler
  andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) updateCard:(PNPCreditCard *) card
withSuccessCallback:(PnPSuccessHandler) successHandler
  andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) deleteCard:(PNPCreditCard *) card
withSuccessCallback:(PnPSuccessHandler) successHandler
  andErrorCallback:(PnPGenericErrorHandler) errorHandler;





#pragma mark - Notification Methods
-(void) getNotificationsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                           andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) deleteNotifications:(NSSet *) notifications withSuccessCallback:(PnPSuccessHandler)successHandler
           andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) deleteNotification:(PNPNotification *) notification withSuccessCallback:(PnPSuccessHandler)successHandler
          andErrorCallback:(PnPGenericErrorHandler) errorHandler;


#pragma mark - Pango Methods

-(void) getPangosWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                    andErrorCallback:(PnPGenericErrorHandler) errorHandler;
-(void) getPangoWithIdentifier:(NSNumber *) identifier
           withSuccessCallback:(PnpPangoDataSuccessHandler) successHandler
              andErrorCallback:(PnPGenericErrorHandler) errorHandler;
-(void) updatePangoAlias:(PNPPango *) pango
     withSuccessCallback:(PnPSuccessHandler) successHandler
        andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) changeStatusForPango:(PNPPango *) pango
         withSuccessCallback:(PnPSuccessHandler)successHandler
            andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) cancelPango:(PNPPango *) pango
withSuccessCallback:(PnPSuccessHandler)successHandler
   andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) unlinkPango:(PNPPango *) pango
withSuccessCallback:(PnPSuccessHandler)successHandler
   andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) rechargePango:(PNPPango *) pango
           withAmount:(NSNumber *) amount
  withSuccessCallback:(PnPSuccessHandler) successHandler
     andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) extractFromPango:(PNPPango *) pango
                  amount:(NSNumber *) amount
     withSuccessCallback:(PnPSuccessHandler) successHandler
        andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) getPangoMovements:(PNPPango *) pango
      withSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
         andErrorCallback:(PnPGenericErrorHandler) errorHandler;


#pragma mark - Send Payment methods

-(void) getSendTransactionCommissionForAmount:(NSNumber *) amount
                                   withPrefix:(NSString *) prefix
                                     andPhone:(NSString *)phone
                          withSuccessCallback:(PnPNSNumberSucceddHandler) successHandler
                             andErrorCallback:(PnPGenericErrorHandler) errorHandler;



-(void) sendTransactionWithAmount:(NSNumber *) amount
                         toPrefix:(NSString *) prefix
                            phone:(NSString *) phone
                              pin:(NSString *) pin
              withSuccessCallback:(PnPSuccessHandler) successHandler
                 andErrorCallback:(PnPGenericErrorHandler) errorHandler;


-(void) getTransactionReceiverWithPrefix:(NSString *) prefix
                                andPhone:(NSString *) phone
                      andSuccessCallBack:(PnPTransactionReceiverSuccessHandler) successHandler
                        andErrorCallback:(PnPGenericErrorHandler) errorHandler;


#pragma mark - Transaction methods

-(void) getTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                          andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) getReceivedTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                                  andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) getSentTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                              andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) getPendingTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                                 andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) cancelPendingTransaction:(PNPTransactionPending *) transaction
             withSuccessCallback:(PnPSuccessHandler) successHandler
                andErrorCallback:(PnPGenericErrorHandler) errorHandler;




#pragma mark - Payment request methods

-(void) getPaymentRequestsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                             andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) cancelPaymentRequest:(PNPPaymentRequest *) request
         withSuccessCallback:(PnPSuccessHandler) successHandler
            andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) confirmPaymentRequest:(PNPPaymentRequest *) request
                          pin:(NSString *) pin
          withSuccessCallback:(PnPSuccessHandler) successHandler
             andErrorCallback:(PnPGenericErrorHandler) errorHandler;


-(void) requestPaymentFromPrefix:(NSString *) prefix
                           phone:(NSString *) phone
                     withConcept:(NSString *) concept
                       andAmount:(NSNumber *) amount
             withSuccessCallback:(PnPSuccessHandler) successHandler
                andErrorCallback:(PnPGenericErrorHandler) errorHandler;


#pragma mark - Halcash methods


-(void) getHalcashExtractionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                                andErrorCallback:(PnPGenericErrorHandler) errorHandler;


-(void) sendHalcashWithAmount:(NSNumber *) amount
                          pin:(NSString *) pin
                      concept:(NSString *) concept
          withSuccessCallback:(PnPSuccessHandler) successHandler
             andErrorCallback:(PnPGenericErrorHandler) errorHandler;


-(void) cancelHalcashTransaction:(PNPHalcashExtraction *) extraction
             withSuccessCallback:(PnPSuccessHandler) successHandler
                andErrorCallback:(PnPGenericErrorHandler) errorHandler;

-(void) getAtmsNearLocation:(CLLocation *) location
              andRadiusInKm:(float) radius
        withSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
           andErrorCallback:(PnPGenericErrorHandler) errorHandler;





#pragma mark - Static data

-(void) getCountriesWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                       andErrorCallback:(PnPGenericErrorHandler) errorHandler;

@end

@interface PNPEnvironment : NSObject
@property NSURL *url;
-(id) initWithUrl:(NSURL *) url;
@end

@interface PNPSandboxEnvironment : PNPEnvironment

@end

@interface PNPProductionEnvironment : PNPEnvironment

@end





