//
//  PNPUser.h
//  PaynoPain
//
//  Created by Christian Bongardt on 03/12/13.
//  Copyright (c) 2013 PaynoPain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PNPWallet : NSObject
-(id) initWithAmount:(NSNumber *) amount
      retainedAmount:(NSNumber *) retained
     availableAmount:(NSNumber *) available
        currencyCode:(NSString *) currencyCode
      currencySymbol:(NSString *) currencySymbol;

@property (strong,nonatomic) NSNumber *amount;
@property (strong,nonatomic) NSNumber *available;
@property (strong,nonatomic) NSNumber *retained;
@property (strong,nonatomic) NSString *currencyCode;
@property (strong,nonatomic) NSString *currencySymbol;
@end


@interface PNPUser : NSObject
-(id) initWithUsername:(NSString *) username
                  name:(NSString *) name
               surname:(NSString *) surname
                 email:(NSString *) email
                prefix:(NSString *) prefix
                 phone:(NSString *) phone
              timezone:(NSTimeZone *) timezone
                wallet:(PNPWallet *) wallet;

@property (strong,nonatomic) PNPWallet *wallet;
@property (strong,nonatomic) NSString *name;
@property (strong,nonatomic) NSString *surname;
@property (strong,nonatomic) NSString *prefix;
@property (strong,nonatomic) NSString *phone;
@property (strong,nonatomic) NSTimeZone *timezone;
@property (strong,nonatomic) NSString *username;
@property (strong,nonatomic) NSString *email;
@property (strong,nonatomic) NSArray *limits;
@end

#define PNPNotificationSendPayment          @"sendPayment"
#define PNPNotificationRequestPayment       @"requestPayment"
#define PNPNotificationNewGroupPayment      @"groupPayment"
#define PNPNotificationFamilyRequest        @"familyRequest"
#define PNPNotificationFamilyDestroyed      @"destroyFamily"
#define PNPNotificationFamilyLeave          @"leaveFamily"
#define PNPNotificationPangoLinked          @"newPango"
#define PNPNotificationPangoRecharged       @"rechargePango"
#define PNPNotificationPangoPayment         @"pangoPayment"

@interface PNPNotification : NSObject
-(id) initWithId:(NSNumber *) identifier
    creationDate:(NSDate *) created
         message:(NSString *) message
     referenceId:(NSNumber *) referenceId
          userId:(NSNumber *) userId
            type:(NSString *) type;

@property (strong,nonatomic) NSNumber *identifier;
@property (strong,nonatomic) NSDate *created;
@property (strong,nonatomic) NSString *message;
@property (strong,nonatomic) NSString *type;
@property (strong,nonatomic) NSNumber *userId;
@property (strong,nonatomic) NSNumber *referenceId;
@end

#define PNPPangoStatusUnblocked @"AC"
#define PNPPangoStatusBlocked @"BL"

@interface PNPPango : NSObject
@property (strong,nonatomic) NSNumber *identifier;
@property (strong,nonatomic) NSString *serial;
@property (strong,nonatomic) NSString *alias;
@property (strong,nonatomic) NSString *status;
@property (strong,nonatomic) NSString *creator;
@property (strong,nonatomic) NSString *currencyCode;
@property (strong,nonatomic) NSNumber *amount;
@property (strong,nonatomic) NSNumber *limit;
@property (strong,nonatomic) NSDate *created;

-(id) initWithIdentifier:(NSNumber *) identifier
                   alias:(NSString *) alias
                  serial:(NSString *) serial
                  status:(NSString *) status
                 creator:(NSString *) creator
            currencyCode:(NSString *) currencyCode
                  amount:(NSNumber *) amount
                   limit:(NSNumber *) limit
                 created:(NSDate *) created;

@end

@interface PNPPangoMovementEntity : NSObject
@property (strong,nonatomic) NSNumber *identifier;
@property (strong,nonatomic) NSString *description;

-(id) initWithIdentifier:(NSNumber *)identifier;

@end

@interface PNPPangoMovementWallet : PNPPangoMovementEntity

@end

@interface PNPPangoMovementCommerce : PNPPangoMovementEntity
@property (strong,nonatomic) NSString *name;
@property (strong,nonatomic) NSString *surname;

-(id) initWithIdentifier:(NSNumber *) identifier
                    name:(NSString *) name
              andSurname:(NSString *) surname;

@end

@interface PNPPangoMovementPango : PNPPangoMovementEntity
@property (strong,nonatomic) NSString *alias;

-(id) initWithIdentifier:(NSNumber *)identifier
                andAlias:(NSString *) alias;

@end

#define PNPPangoMovementTypeWalletToPango           @"UserPango"
#define PNPPangoMovementTypePangoToWallet           @"PangoUser"
#define PNPPangoMovementTypeCommerceToPango         @"CommerceRecharge"
#define PNPPangoMovementTypePangoToCommerce         @"PangoPayment"
#define PNPPangoMovementTypePangoChargeback         @"CancelPayment"
#define PNPPangoMovementTypePangoRechargeChargeback @"CancelRecharge"

#define PNPPangoMovementStatusOK  @"OK"

@interface PNPPangoMovement : NSObject
@property (strong,nonatomic) PNPPangoMovementEntity *emitter;
@property (strong,nonatomic) PNPPangoMovementEntity *receiver;

@property (strong,nonatomic) NSString  *type;
@property (strong,nonatomic) NSString  *status;
@property (strong,nonatomic) NSString  *concept;
@property (strong,nonatomic) NSNumber  *amount;
@property (strong,nonatomic) NSString  *currencySymbol;
@property (strong,nonatomic) NSDate    *date;


-(id) initWithEmitter:(PNPPangoMovementEntity *) emitter
             receiver:(PNPPangoMovementEntity *) receiver
                 type: (NSString *) type
               status:(NSString *) status
              concept:(NSString *) concept
               amount:(NSNumber *) amount
       currencySymbol:(NSString *) currencySymbol
                 date:(NSDate *) date;



@end

@interface PNPPangoMovementExpense : PNPPangoMovement

@end

@interface PNPPangoMovementIncome : PNPPangoMovement

@end





