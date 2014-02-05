//
//  PNPUser.h
//  PaynoPain
//
//  Created by Christian Bongardt on 03/12/13.
//  Copyright (c) 2013 PaynoPain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>

@interface PNPWallet : NSObject <NSCoding>
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


@interface PNPUser : NSObject <NSCoding>
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

@interface PNPNotification : NSObject <NSCoding>
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

@interface PNPPango : NSObject <NSCoding>
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

@interface PNPPangoMovementEntity : NSObject <NSCoding>
@property (strong,nonatomic) NSNumber *identifier;
@property (strong,nonatomic) NSString *description;

-(id) initWithIdentifier:(NSNumber *)identifier;

@end

@interface PNPPangoMovementWallet : PNPPangoMovementEntity <NSCoding>

@end

@interface PNPPangoMovementCommerce : PNPPangoMovementEntity <NSCoding>
@property (strong,nonatomic) NSString *name;
@property (strong,nonatomic) NSString *surname;

-(id) initWithIdentifier:(NSNumber *) identifier
                    name:(NSString *) name
              andSurname:(NSString *) surname;

@end

@interface PNPPangoMovementPango : PNPPangoMovementEntity <NSCoding>
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

@interface PNPPangoMovement : NSObject <NSCoding>
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

@interface PNPPangoMovementExpense : PNPPangoMovement <NSCoding>

@end

@interface PNPPangoMovementIncome : PNPPangoMovement <NSCoding>

@end


@interface PNPTransactionEntity : NSObject <NSCoding>
-(NSString *) tableString;
@end


@interface PNPTransactionReceiver : PNPTransactionEntity <NSCoding>

@end

@interface  PNPTransactionReceiverHalcash : PNPTransactionReceiver

@end

@interface  PNPTransactionReceiverCommerce : PNPTransactionReceiver<NSCoding>

@property (strong,nonatomic) NSString *name;

-(id) initWithName:(NSString *)name;

@end

@interface PNPTransactionEmitter : PNPTransactionEntity <NSCoding>

@end

@interface PNPTransactionReceiverUser : PNPTransactionReceiver <NSCoding>

@property (strong,nonatomic) NSString *name;
@property (strong,nonatomic) NSString *prefix;
@property (strong,nonatomic) NSString *phone;
@property (strong,nonatomic) NSString *email;

-(id) initWithName:(NSString *) name
            prefix:(NSString *) prefix
             phone:(NSString *) phone
             email:(NSString *) email;
@end

@interface PNPTransactionReceiverUnregistered : PNPTransactionReceiver <NSCoding>
@property (strong,nonatomic) NSString *prefix;
@property (strong,nonatomic) NSString *phone;

-(id) initWithPrefix:(NSString *) prefix
            andPhone:(NSString *) phone;


@end

@interface PNPTransactionEmitterRecharge : PNPTransactionEmitter <NSCoding>

@end

@interface PNPTransactionEmitterUser : PNPTransactionEmitter <NSCoding>

@property (strong,nonatomic) NSString *name;
@property (strong,nonatomic) NSString *prefix;
@property (strong,nonatomic) NSString *phone;
@property (strong,nonatomic) NSString *email;
@property (strong,nonatomic) NSURL *avatarUrl;

-(id) initWithName:(NSString *) name
            prefix:(NSString *) prefix
             phone:(NSString *) phone
             email:(NSString *) email
         avatarUrl:(NSURL *) avatar;
@end

@interface PNPTransactionEmitterPango : PNPTransactionEmitter

@end


@interface PNPTransactionEmitterHalcash : PNPTransactionEmitter

@end


#define PNPTransactionStatusOK @"OK";
#define PNPTransactionStatusCancelled @"CA";

@interface PNPTransaction : NSObject <NSCoding>

@property (strong,nonatomic) NSNumber *identifier;
@property (strong,nonatomic) NSNumber *amount;
@property (strong,nonatomic) NSString *currencyCode;
@property (strong,nonatomic) NSString *currencySymbol;
@property (strong,nonatomic) NSString *concept;
@property (strong,nonatomic) NSString *status;
@property (strong,nonatomic) NSDate *created;
@property (strong,nonatomic) PNPTransactionEntity *entity;

-(id) initWithIdentifier:(NSNumber *) identifier
                  amount:(NSNumber *) amount
           currencyCode :(NSString *) currencyCode
          currencySymbol:(NSString *) currencySymbol
                 concept:(NSString *) concept
                  status:(NSString *) status
                 created:(NSDate *) created
               andEntity:(PNPTransactionEntity *) entity;

@end

@interface PNPTransactionReceived : PNPTransaction <NSCoding>

@end

@interface PNPTransactionSent : PNPTransaction <NSCoding>

@end

@interface PNPTransactionPending : PNPTransaction <NSCoding>

@end


@interface PNPPaymentRequest : NSObject <NSCoding>

@property (strong,nonatomic) NSNumber *identifier;
@property (strong,nonatomic) NSNumber *amount;
@property (strong,nonatomic) NSString *currencySymbol;
@property (strong,nonatomic) NSDate *created;
@property (strong,nonatomic) NSString *concept;
@property (strong,nonatomic) NSString *prefix;
@property (strong,nonatomic) NSString *phone;
@property (strong,nonatomic) NSString *name;

-(id) initWithIdentifier:(NSNumber *) identifier
                  amount:(NSNumber *) amount
          currencySymbol:(NSString *) currencySymbol
            creationDate:(NSDate *) created
                 concept:(NSString *) concept
                  prefix:(NSString *) prefix
                   phone:(NSString *) phone
                    name:(NSString *) name;


@end


@interface PNPCountry : NSObject <NSCoding>

-(id) initWithName:(NSString *) name
            prefix:(NSString *) prefix
              code:(NSString *) code
    currencySymbol:(NSString *) currencySymbol
      currencyCode:(NSString *) currencyCode;

@property NSString *prefix;
@property NSString *name;
@property NSString *code;
@property NSString *currencySymbol;
@property NSString *currencyCode;


@end

@interface PNPUserValidationItem : NSObject <NSCoding>

-(id) initWithStatus:(NSString *) status;

@property BOOL isUploaded;
@property BOOL isValidated;
@property BOOL isDeclined;

@end


@interface PNPUserValidation : NSObject <NSCoding>

-(id) initWithStatus:(BOOL) status
          andFrontId:(PNPUserValidationItem *) front
              rearId:(PNPUserValidationItem *) rear
                bill:(PNPUserValidationItem *) bill
        andAgreement:(PNPUserValidationItem *) agreement;

@property BOOL isValidated;

@property (strong,nonatomic) PNPUserValidationItem * idCardFront;
@property (strong,nonatomic) PNPUserValidationItem * idCardRear;
@property (strong,nonatomic) PNPUserValidationItem * bill;
@property (strong,nonatomic) PNPUserValidationItem * agreement;

@end


@interface PNPCreditCard : NSObject <NSCoding>

-(id) initWithIdentifier:(NSNumber *) identifier
                  number:(NSString *) number
                    year:(NSNumber *) year
                   month:(NSNumber *) month
                   alias:(NSString *) alias
                    type:(NSString *) type
               isDefault:(BOOL) def;

@property (strong,nonatomic) NSNumber *identifier;
@property (strong,nonatomic) NSString *number;
@property (strong,nonatomic) NSNumber *year;
@property (strong,nonatomic) NSNumber *month;
@property (strong,nonatomic) NSString *alias;
@property (strong,nonatomic) NSString *type;
@property BOOL isDefault;



@end


#define PNPHalcashExtractionStatusPending @"PE"
#define PNPHalcashExtractionStatusDenied @"DE"
#define PNPHalcashExtractionStatusCancelled @"CA"
#define PNPHalcashExtractionStatusFinished @"AC"

@interface PNPHalcashExtraction : NSObject <NSCoding>

@property (strong,nonatomic) NSNumber *amount;
@property (strong,nonatomic) NSDate *date;
@property (strong,nonatomic) NSString *currency;
@property (strong,nonatomic) NSDate *expirationDate;
@property (strong,nonatomic) NSNumber *identifier;
@property (strong,nonatomic) NSString *status;
@property (strong,nonatomic) NSString *ticket;
@property (strong,nonatomic) NSNumber *transactioId;

-(id) initWithIdentifier:(NSNumber *) identifier
                  amount:(NSNumber *)amount
          currencySymbol:(NSString *)currencySymbol
                  status:(NSString *)status
                 created:(NSDate *)created
                  expiry:(NSDate *)expiry
                  ticket:(NSString *)ticket
           transactionId:(NSNumber *)transactionId;

-(BOOL) isCancellable;
@end

@interface PNPLocation : NSObject
@property (strong,nonatomic) CLLocation *location;
@property (strong,nonatomic) NSString *city;
@property (strong,nonatomic) NSString *address;
@property (strong,nonatomic) NSString *name;
-(id) initWithLocation:(CLLocation *) location
                  city:(NSString *)city
               address:(NSString *) address
                  name:(NSString *) name;

@end


@interface PNPOrder : NSObject
@property (strong,nonatomic) NSString *concept;
@property (strong,nonatomic) NSString *reference;
@property (strong,nonatomic) NSNumber *identifier;
@property (strong,nonatomic) NSNumber *amount;
@property (strong,nonatomic) NSString *currency;
@property (strong,nonatomic) NSDate *created;
@property (strong,nonatomic) NSString *commerce;

-(id) initWithIdentifier:(NSNumber *) identifier
               reference:(NSString *) reference
                 concept:(NSString *) concept
                 created:(NSDate *)   created
                commerce:(NSString *) commerce
                  amount:(NSNumber *) amount
                currency:(NSString *) currency;

@end

