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


@interface PNPCommerce : NSObject <NSCoding>

-(id) initWithIdentifier:(NSNumber *) identifier
              commerceId:(NSNumber *) commerceId
                    name:(NSString *) name;

@property (strong,nonatomic) NSNumber *identifier;
@property (strong,nonatomic) NSNumber *commerceId;
@property (strong,nonatomic) NSString *name;

@end

@interface PNPUserCommerce : NSObject <NSCoding>

-(id) initWithAddress: (NSString *) address
                  cif: (NSString *) cif
                 city: (NSString *) city
           commerceId: (NSNumber *) commerceId
         contactPhone: (NSNumber *) contactPhone
              created: (NSDate *) dateCreated
             distance: (NSNumber *) distance
                   id: (NSNumber *) identifier
                  lat: (NSNumber *) lat
                  lon: (NSNumber *) lon
             modified: (NSDate *) modified
                 name: (NSString *) name
             province: (NSString *) province
          totalPoints: (NSNumber *) totalPoints
          totalPromos: (NSNumber *) totalPromos
              zipCode: (NSNumber *) zipCode;


@property (strong,nonatomic) NSString *address;
@property (strong,nonatomic) NSString *cif;
@property (strong,nonatomic) NSString *city;
@property (strong,nonatomic) NSNumber *commerceId;
@property (strong,nonatomic) NSNumber *contactPhone;
@property (strong,nonatomic) NSDate *dateCreated;
@property (strong,nonatomic) NSNumber *distance;
@property (strong,nonatomic) NSNumber *identifier;
@property (strong,nonatomic) NSNumber *lat;
@property (strong,nonatomic) NSNumber *lon;
@property (strong,nonatomic) NSDate *modified;
@property (strong,nonatomic) NSString *name;
@property (strong,nonatomic) NSString *province;
@property (strong,nonatomic) NSNumber *totalPoints;
@property (strong,nonatomic) NSNumber *totalPromos;
@property (strong,nonatomic) NSNumber *zipCode;
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
            type:(NSString *) type
            read:(BOOL) read;

@property (strong,nonatomic) NSNumber *identifier;
@property (strong,nonatomic) NSDate *created;
@property (strong,nonatomic) NSString *message;
@property (strong,nonatomic) NSString *type;
@property (strong,nonatomic) NSNumber *userId;
@property (strong,nonatomic) NSNumber *referenceId;
@property BOOL read;
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

@interface  PNPTransactionEmitterCommerce : PNPTransactionEmitter<NSCoding>

@property (strong,nonatomic) NSString *name;

-(id) initWithName:(NSString *)name;

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

@interface PNPTransactionReceiverPango : PNPTransactionEmitter

@end

@interface PNPTransactionReceiverUnregistered : PNPTransactionReceiver <NSCoding>
@property (strong,nonatomic) NSString *prefix;
@property (strong,nonatomic) NSString *phone;

-(id) initWithPrefix:(NSString *) prefix
            andPhone:(NSString *) phone;


@end

@interface PNPTransactionEmitterRecharge : PNPTransactionEmitter <NSCoding>
@property (strong, nonatomic) NSNumber *amount;
@property (strong, nonatomic) NSDate *created;
@property (strong, nonatomic) NSString *currencyCode;
@property (strong, nonatomic) NSString *currencySymbol;
@property (strong, nonatomic) NSString *status;
@property (strong, nonatomic) NSURL *barcode;
@end

@interface PNPTransactionEmitterRechargePromo : PNPTransactionEmitterRecharge

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


#define PNPTransactionStatusOK @"OK"
#define PNPTransactionStatusCancelled @"CA"

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
@property (strong,nonatomic) NSString *status;

-(id) initWithIdentifier:(NSNumber *) identifier
                  amount:(NSNumber *) amount
          currencySymbol:(NSString *) currencySymbol
            creationDate:(NSDate *) created
                 concept:(NSString *) concept
                  prefix:(NSString *) prefix
                   phone:(NSString *) phone
                    name:(NSString *) name
                    status:(NSString *) status;


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
@property (strong,nonatomic) NSNumber *netAmount;
@property (strong,nonatomic) NSNumber *loyaltyPercentage;
@property (strong,nonatomic) NSNumber *loyaltyDiscountAmount;
@property (strong,nonatomic) NSString *currency;
@property (strong,nonatomic) NSDate *created;
@property (strong,nonatomic) NSString *commerce;

-(id) initWithIdentifier:(NSNumber *) identifier
               reference:(NSString *) reference
                 concept:(NSString *) concept
                 created:(NSDate *)   created
                commerce:(NSString *) commerce
                  amount:(NSNumber *) amount
               netAmount:(NSNumber *) netAmount
       loyaltyPercentage:(NSNumber *) loyaltyPercentage
       loyaltyDiscountAmount:(NSNumber *) loyaltyDiscountAmount
                currency:(NSString *) currency;

@end

@interface PNPOrderLine : NSObject <NSCopying>
@property (strong,nonatomic) NSNumber *identifier;
@property (strong,nonatomic) NSString *name;
@property (strong,nonatomic) NSNumber *amount;
@property (strong,nonatomic) NSNumber *netAmount;
@property (strong,nonatomic) NSNumber *orderId;
@property (strong,nonatomic) NSNumber *number;
@property BOOL refunded;
@property (strong,nonatomic) NSString *type;
@property (strong,nonatomic) NSNumber *externalId;
@property (strong,nonatomic) NSString *desc;

-(id) initWithIdentifier:(NSNumber *) identifier
                   name:(NSString *) name
                  amount:(NSNumber *) amount
               netAmount:(NSNumber *) netAmount
                 orderId:(NSNumber *) orderId
                  number:(NSNumber *) number
                refunded:(BOOL) refunded
                    type:(NSString *) type
              externalId:(NSNumber *) externalId;

@end

#define PNPCommerceOrderStatusOk @"AC"
#define PNPCommerceOrderStatusCancelled @"CA"

@interface PNPCommerceOrder : NSObject <NSCoding>
@property (strong,nonatomic) NSNumber *identifier;
@property (strong,nonatomic) NSString *reference;
@property (strong,nonatomic) NSString *type;
@property (strong,nonatomic) NSString *concept;
@property (strong,nonatomic) NSString *status;

@property (strong,nonatomic) NSDate *created;


@property (strong,nonatomic) NSNumber *amount;
@property (strong,nonatomic) NSNumber *netAmount;
@property (strong,nonatomic) NSNumber *refundAmount;
@property (strong,nonatomic) NSString *currencySymbol;

@property (strong,nonatomic) NSString *mail;
@property (strong,nonatomic) NSNumber *userId;
@property (strong,nonatomic) NSString *name;
@property (strong,nonatomic) NSString *surname;
@property (strong,nonatomic) NSString *prefix;
@property (strong,nonatomic) NSString *phone;
@property (strong,nonatomic) NSArray *orderLines;

-(id) initWithIdentifier:(NSNumber *) identifier
               reference:(NSString *) reference
                    type:(NSString *) type
                 concept:(NSString *) concept
                  status:(NSString *) status
                  amount:(NSNumber *) amount
               netAmount:(NSNumber *) netAmount
               refundAmount:(NSNumber *) refundAmount
          currencySymbol:(NSString *) currencySymbol
                    mail:(NSString *) mail
                  userId:(NSNumber *) userId
                    name:(NSString *) name
                 surname:(NSString *) surname
                  prefix:(NSString *) prefix
                   phone:(NSString *) phone
                 created:(NSDate *) created
              orderLines:(NSArray *) orderLines;
@end

@interface PNPUserOrder : NSObject<NSCoding>
@property (strong,nonatomic) NSString *commerceName;
@property (strong,nonatomic) NSString *concept;
@property (strong,nonatomic) NSDate *created;
@property (strong,nonatomic) NSString *currencySymbol;
@property (strong,nonatomic) NSNumber *identifier;
@property (strong,nonatomic) NSNumber *amount;
@property (strong,nonatomic) NSNumber *netAmount;
@property (strong,nonatomic) NSNumber *refundAmount;
@property (strong,nonatomic) NSString *mail;
@property (strong,nonatomic) NSArray *orderLines;
@property (strong,nonatomic) NSString *type;
@property (strong,nonatomic) NSString *reference;

-(id) initWithIdentifier:(NSNumber *) identifier
            commerceName:(NSString *) commerceName
                 concept:(NSString *) concept
                 created:(NSDate *) created
          currencySymbol:(NSString *) currencySymbol
                  amount:(NSNumber *) amount
               netAmount:(NSNumber *) netAmount
                    mail:(NSString *) mail
              orderLines:(NSArray *) orderLines
                    type:(NSString *) type
               reference:(NSString *) reference;

@end


@interface PNPCoupon : NSObject <NSCoding>

@property (strong,nonatomic) NSString *ccode;

@property BOOL favorite;
@property BOOL viewed;

@property (strong,nonatomic) NSNumber *identifier;
@property (strong,nonatomic) NSNumber *loyaltyIdentifier;
@property (strong,nonatomic) NSNumber * promoId;

@property (strong,nonatomic) NSNumber *actualUses;
@property (strong,nonatomic) NSNumber *limitUses;

@property (strong,nonatomic) NSString *companyName;
@property (strong,nonatomic) NSString *title;
@property (strong,nonatomic) NSString *longDescription;
@property (strong,nonatomic) NSString *shortDescription;

@property (strong,nonatomic) NSString *logoUrl;
@property (strong,nonatomic) NSString *brandLogoUrl;

@property (strong,nonatomic) NSNumber *productId;

@property (strong,nonatomic) NSDate *startDate;
@property (strong,nonatomic) NSDate *endDate;

@property (strong,nonatomic) NSArray *validDays;
@property (strong,nonatomic) NSArray *timeRanges;

@property (strong,nonatomic) NSNumber * fixedAmount;

@property (strong,nonatomic) NSNumber * percentageAmount;
@property (strong,nonatomic) NSString * gift;
@property (strong,nonatomic) NSString * status;
@property (strong,nonatomic) NSArray * products;
@property (strong,nonatomic) NSString * type;
@property (strong,nonatomic) NSArray *giftProducts;
@property (strong,nonatomic) NSString  *web;




-(id) initWithCode:(NSString *)code
        identifier:(NSNumber *)identifier
        promoId:(NSNumber *)promoId
 loyaltyIdentifier:(NSNumber *)loyaltyIdentifier
        actualUses:(NSNumber *)actualUses
         limitUses:(NSNumber *)limitUses
       companyName:(NSString *)companyName
             title:(NSString *)title
       description:(NSString *)description
  shortDescription:(NSString *)shortDescription
           logoUrl:(NSString *)logoUrl
      brandLogoUrl:(NSString *)brandLogoUrl
         startDate:(NSDate *)startDate
           endDate:(NSDate *)endDate
        validDays:(NSArray *)validDays
       timeRanges:(NSArray *)timeRanges
       fixedAmount:(NSNumber *) fixedAmount
  percentageAmount:(NSNumber *) percentageAmount
              gift:(NSString *) gift
          favorite:(BOOL) favorite
            viewed:(BOOL) viewed
            status:(NSString *) status
          products:(NSArray *) products
      giftProducts:(NSArray *) giftProducts
              type:(NSString *)type;


@end

@interface PNPCPDaily : PNPCoupon
@end

@class CartItem;
@interface PNPCPStampCard : PNPCoupon
@property (strong,nonatomic) CartItem *cartItem;
@end

@interface PNPCPMultiUssage : PNPCoupon
@end

@interface PNPCPOneTime : PNPCoupon
@end

@interface PNPCPExchange : PNPCoupon
@end

@interface PNPCPLoyalty : PNPCoupon
@end

@interface PNPCouponPromotion : NSObject <NSCoding>

@property (strong,nonatomic) NSString *identifier;
@property (strong,nonatomic) NSString *title;
@property (strong,nonatomic) NSString *longDescription;
@property (strong,nonatomic) NSString *shortDescription;
@property (strong,nonatomic) NSString *type;
@property (strong,nonatomic) NSArray *validDays;
@property (strong,nonatomic) NSArray *products;
@property (strong,nonatomic) NSString *logoUrl;
@property (strong,nonatomic) NSString *brandLogoUrl;
@property (strong,nonatomic) NSNumber * fixedAmount;
@property (strong,nonatomic) NSNumber * percentageAmount;
@property (strong,nonatomic) NSString * gift;
@property (strong,nonatomic) NSArray *giftProducts;
@property (strong,nonatomic) NSNumber *actualUses;
@property (strong,nonatomic) NSNumber *limitUses;
@property (strong,nonatomic) NSDate *startDate;
@property (strong,nonatomic) NSDate *endDate;
@property (strong,nonatomic) NSDate *created;
@property (strong,nonatomic) NSString * status;
@property (strong,nonatomic) NSString * company;
@property (strong,nonatomic) NSString * user;
@property (strong,nonatomic) NSArray * timeRanges;
@property (strong,nonatomic) NSString  *web;
@property (strong,nonatomic) NSString *province;
@property (strong,nonatomic) NSString *city;
@property (strong,nonatomic) NSNumber *minimumAge;
@property (strong,nonatomic) NSNumber *maximumAge;
@property (strong,nonatomic) NSString *gender;



-(id) initWithIdentifier:(NSString *) identifier
                   title:(NSString *) title
                 company:(NSString *) company
         longDescription:(NSString *) longDescription
        shortDescription:(NSString *) shortDescription
                    type:(NSString *) type
               validDays:(NSArray *) validDays
                products:(NSArray *) products
                 logoUrl:(NSString *) logoUrl
            brandLogoUrl:(NSString *) brandLogoUrl
             fixedAmount:(NSNumber *) fixedAmount
        percentageAmount:(NSNumber *) percentageAmount
                    gift:(NSString *) gift
            giftProducts:(NSArray *) giftProducts
              actualUses:(NSNumber *) actualUses
               limitUses:(NSNumber *) limitUses
               startDate:(NSDate *)startDate
                 endDate:(NSDate *)endDate
                 created:(NSDate *)created
                  status:(NSString *) status
                    user:(NSString *) user
              timeRanges:(NSArray *) timeRanges
                     web:(NSString *) web;
@end


@interface PNPPromotionStatistic : NSObject <NSCoding>

@property(strong, nonatomic) NSDictionary *exchanges;
@property(strong, nonatomic) NSNumber *notificationsOpened;
@property(strong, nonatomic) NSNumber *notificationsSended;

-(id) initWithExchanges:(NSDictionary *) exchanges
    notificationsOpened:(NSNumber *) notificationsOpened
    notificationsSended:(NSNumber *) notificationsSended;

@end


@interface PNPLoyaltySuscriptionField : NSObject <NSCoding>

@property (strong,nonatomic) NSString *attribute;
@property (strong,nonatomic) NSString *name;
@property int order;

-(id) initWithName:(NSString *) name attribute:(NSString *) attribute order:(int) order;

@end

@interface PNPLoyaltySuscriptionFieldText : PNPLoyaltySuscriptionField

@end

@interface PNPLoyaltySuscriptionFieldSelect : PNPLoyaltySuscriptionField

@property (strong,nonatomic) NSArray *options;
@property (strong,nonatomic) NSArray *optionValues;
-(id) initWithName:(NSString *)name
         attribute:(NSString *)attribute
           options:(NSArray *)options
   andOptionValues:(NSArray *)optionValues
             order:(int) order;
@end


@interface PNPLoyaltyExchanges : NSObject <NSCoding>

@property (strong,nonatomic) NSNumber *identifier;
@property (strong,nonatomic) NSNumber *loyaltyIdentifier;
@property (strong,nonatomic) NSNumber *points;
@property (strong,nonatomic) NSNumber *fixedAmount;
@property (strong,nonatomic) NSNumber *percentageAmount;
@property (strong,nonatomic) NSString *gift;

-(id) initWithIdentifier:(NSNumber *) identifier
         loyaltyIdentifier:(NSNumber *) loyaltyIdentifier
                    points:(NSNumber *) points
               fixedAmount:(NSNumber *) fixedAmount
          percentageAmount:(NSNumber *) percentageAmount
                  gift:(NSString *) gift;


@end

@interface PNPLoyaltyCommerce : NSObject <NSCoding>

@property (strong,nonatomic) NSNumber *identifier;
@property (strong,nonatomic) NSString *name;

-(id) initWithIdentifier:(NSNumber *) identifier
                      name:(NSString *) name;

@end

@interface PNPLoyaltyCompany : NSObject <NSCoding>

@property (strong,nonatomic) NSString *name;

-(id) initWithName:(NSString *) name;

@end

@interface PNPLoyaltyBenefits : NSObject <NSCoding>

@property (strong,nonatomic) NSNumber * identifier;
@property (strong,nonatomic) NSNumber * percentageAmount;
@property (strong,nonatomic) NSDate * startDate;
@property (strong,nonatomic) NSDate * endDate;

-(id) initWithIdentifier:(NSNumber *) identifier
          percentageAmount:(NSNumber *) percentageAmount
                 startDate:(NSDate *) startDate
                   endDate:(NSDate *) endDate;

@end

@interface PNPLoyalty : NSObject <NSCoding>

@property (strong,nonatomic) NSNumber *identifier;
@property (strong,nonatomic) NSNumber *userId;

@property (strong,nonatomic) NSString *title;
@property (strong,nonatomic) NSString *descr;
@property (strong,nonatomic) NSString *shortDescription;

@property (strong,nonatomic) NSString *logoUrl;

@property (strong,nonatomic) NSString *status;

@property (strong,nonatomic) NSDate *startDate;
@property (strong,nonatomic) NSDate *endDate;

@property (strong,nonatomic) NSNumber *amount;
@property (strong,nonatomic) NSNumber *points;

@property (strong,nonatomic) NSArray *suscriptionFields;
@property (strong,nonatomic) NSArray *exchangableCoupons;
@property (strong,nonatomic) NSArray *commerces;
@property (strong,nonatomic) PNPLoyaltyCompany *company;
@property (strong,nonatomic) NSArray *benefits;



@property BOOL registered;

-(id) initWithIdentifier:(NSNumber *) identifier
                  userId:(NSNumber *) userId
                   title:(NSString *) title
             description:(NSString *) description
        shortDescription:(NSString *) shortDescription
                 logoUrl:(NSString *) logoUrl
                  status:(NSString *) status
               startDate:(NSDate *)   startDate
                 endDate:(NSDate *)   endDate
                  amount:(NSNumber *) amount
                  points:(NSNumber *) points
       suscriptionFields:(NSArray *)  suscriptionFields
      exchangableCoupons:(NSArray *)  exchangableCoupons
               commerces:(NSArray *)  commerces
                 company:(PNPLoyaltyCompany *)  company
                benefits:(NSArray *)  benefits
              registered:(BOOL)  registered;
@end


@interface PNPLoyaltyUserData: NSObject <NSCoding>
@property (strong,nonatomic) NSNumber *actualPoints;
@property (strong,nonatomic) NSNumber *lastPoints;
@property (strong,nonatomic) NSString *code;
@property (strong,nonatomic) NSNumber *loyaltyId;

-(id) initWithLoyaltyId:(NSNumber *) identifier
           actualPoints:(NSNumber *) actualPoints
             lastPoints:(NSNumber *) lastPoints
                   code:(NSString *) code;
@end

@interface PNPCCategory : NSObject <NSCoding>

-(id) initWithIdentifier:(NSNumber *) identifier
                    name:(NSString *) name
                  imgUrl:(NSString *) url
                products:(NSArray *) products;

@property (strong,nonatomic) NSString *name;
@property (strong,nonatomic) NSString *imgUrl;
@property (strong,nonatomic) NSArray *products;
@property (strong,nonatomic) NSNumber *identifier;

@end


@interface PNPCProduct : NSObject <NSCoding>

-(id) initWithIdentifier:(NSNumber *) identifier
                    name:(NSString *) name
                  imgUrl:(NSString *) imgUrl
                variants:(NSArray *) variants;

@property (strong,nonatomic) NSString *name;
@property (strong,nonatomic) NSString *imgUrl;
@property (strong,nonatomic) NSArray *variants;
@property (strong,nonatomic) NSNumber *identifier;

@end

@interface PNPCVariant : NSObject <NSCoding>

-(id) initWithName:(NSString *) name
             price:(NSNumber *) price
        identifier:(NSNumber *) identifier;

@property (strong,nonatomic) NSString *name;
@property (strong,nonatomic) NSNumber *price;
@property (strong,nonatomic) NSNumber *identifer;

@end

@interface PNPPromo : NSObject

@property BOOL active;

@property (strong,nonatomic) NSNumber *userCount;
@property (strong,nonatomic) NSNumber *maxUserCount;

@property (strong,nonatomic) NSNumber *amount;

@property (strong,nonatomic) NSNumber *minAmount;

@property (strong,nonatomic) NSNumber *identifier;

-(id) initWithUserCount:(NSNumber *) userCound maxUserCount:(NSNumber *) maxUserCount active:(BOOL) active amount:(NSNumber *)amount minAmount:(NSNumber *)minAMount identifier:(NSNumber *) identifier;

@end
