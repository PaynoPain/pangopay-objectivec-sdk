//
//  PangoPayDataCacher.h
//  PaynoPain
//
//  Created by Christian Bongardt on 12/12/13.
//  Copyright (c) 2013 PaynoPain. All rights reserved.
//

#import "PangoPaySDK.h"

@interface PangoPayDataCacher : PangoPaySDK

#pragma mark - User Methods
-(void) getUserDataWithSuccessCallback:(PnpUserDataSuccessHandler) successHandler
                      andErrorCallback:(PnPGenericErrorHandler) errorHandler
                    andRefreshCallback:(PnpUserDataSuccessHandler) refreshHandler;

-(void) getUserAvatarWithSuccessCallback:(PnpUserAvatarSuccessHandler) successHandler
                        andErrorCallback:(PnPGenericErrorHandler) errorHandler
                    andRefreshCallback:(PnpUserAvatarSuccessHandler) refreshHandler;

-(void) getUserValidationStatusWithSuccessCallback:(PnpUserValidationSuccessHandler)successHandler
                                  andErrorCallback:(PnPGenericErrorHandler)errorHandler
                                andRefreshCallback:(PnpUserValidationSuccessHandler) refreshHandler;

#pragma mark - Credit cards

-(void) getCreditCardsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                         andErrorCallback:(PnPGenericErrorHandler) errorHandler
                          refreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler;




#pragma mark - Notification Methods
-(void) getNotificationsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                           andErrorCallback:(PnPGenericErrorHandler) errorHandler
                         andRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler;


#pragma mark - Pango Methods

-(void) getPangosWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                    andErrorCallback:(PnPGenericErrorHandler) errorHandler
                  andRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler;


-(void) getPangoMovements:(PNPPango *) pango
      withSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
         andErrorCallback:(PnPGenericErrorHandler) errorHandler
       andRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler;


#pragma mark - Transaction methods


-(void) getTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                          andErrorCallback:(PnPGenericErrorHandler) errorHandler
                        andRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler;

-(void) getReceivedTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                                  andErrorCallback:(PnPGenericErrorHandler) errorHandler
                                andRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler;

-(void) getSentTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                              andErrorCallback:(PnPGenericErrorHandler) errorHandler
                            andRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler;

-(void) getPendingTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                                 andErrorCallback:(PnPGenericErrorHandler) errorHandler
                               andRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler;

#pragma mark - Payment requests

-(void) getPaymentRequestsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler)successHandler
                             andErrorCallback:(PnPGenericErrorHandler)errorHandler
                           andRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler;

-(void) getPaymentRequestsWitId:(NSNumber *)identifier
             andSuccessCallback:(PnPPaymentRequestSuccessHandler) successHandler
               andErrorCallback:(PnPGenericErrorHandler)errorHandler;

#pragma mark - Halcash 

-(void) getHalcashExtractionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler)successHandler
                                andErrorCallback:(PnPGenericErrorHandler)errorHandler
                              andRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler;
    

#pragma mark - Wallet recharge

-(void) getWalletRechargesWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
							 andErrorCallback:(PnPGenericErrorHandler) errorHandler
						   andRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler;

-(void) rechargeWalletWithAmount:(NSNumber *) amount
							 pin:(NSString*) pin
			 withSuccessCallback:(PnPSuccessHandler) successHandler
				andErrorCallback:(PnPGenericErrorHandler) errorHandler;

#pragma mark - Static data

-(void) getCountriesWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                       andErrorCallback:(PnPGenericErrorHandler) errorHandler
                    withRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler;

@end
