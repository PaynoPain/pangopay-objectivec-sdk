//
//  PaynoPainSDK.h
//  PaynoPain
//
//  Created by Christian Bongardt on 21/11/13.
//  Copyright (c) 2013 PaynoPain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PNPConnectionError.h"
#import "PNPWebserviceErrors.h"
#import "PNPDataContainer.h"

#pragma mark - Client definitions

#define     PNP_MOBILE_CLIENT_ID           @""
#define     PNP_MOBILE_CLIENT_SECRET       @""
#define     PNP_MOBILE_BASE_URL            @""
#define     PNP_MOBILE_SCOPES              @[@"basic"]

#pragma mark - PaynoPainSDK Declaration
@interface PaynoPainSDK : NSObject

typedef void(^PnPSuccessHandler)();
typedef void(^PnPLoginSuccessHandler)();
typedef void(^PnPLoginErrorHandler)(NSError *error);
typedef void(^PnPLogoutHandler)();
typedef void(^PnPGenericErrorHandler)(NSError *error);
typedef void(^PnpUserDataSuccessHandler)(PNPUser *user);
typedef void(^PnpPangoDataSuccessHandler)(PNPPango *pango);
typedef void(^PnpUserAvatarSuccessHandler)(UIImage *avatar);
typedef void(^PnPGenericNSAarraySucceddHandler)(NSArray * data);


+ (instancetype)sharedInstance;


#pragma mark - Authentication Methods
-(void) setupLoginObserversWithSuccessCallback:(PnPLoginSuccessHandler)successHandler
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

@end






