//
//  PNPUser.m
//  PaynoPain
//
//  Created by Christian Bongardt on 03/12/13.
//  Copyright (c) 2013 PaynoPain. All rights reserved.
//

#import "PNPDataContainer.h"

@implementation PNPWallet

-(id) initWithAmount:(NSNumber *) amount
      retainedAmount:(NSNumber *) retained
     availableAmount:(NSNumber *) available
        currencyCode:(NSString *) currencyCode
      currencySymbol:(NSString *) currencySymbol
{
    
    self = [super init];
    if(self){
        self.amount =  amount;
        self.retained  =  retained;
        self.available = available;
        self.currencyCode = currencyCode;
        self.currencySymbol = currencySymbol;
    }
    return self;
}

-(NSString *) description{
    return [NSString stringWithFormat:@" Amount: %@ \n  Retained: %@ \n  Available: %@ \n  Currency code: %@ \n  Currency Symbol: %@",self.amount,self.retained,self.available,self.currencyCode,self.currencySymbol];
}

@end

@implementation PNPUser

-(id) initWithUsername:(NSString *) username
                  name:(NSString *) name
               surname:(NSString *) surname
                 email:(NSString *) email
                prefix:(NSString *) prefix
                 phone:(NSString *) phone
              timezone:(NSTimeZone *) timezone
                wallet:(PNPWallet *) wallet{
    
    self= [super init];
    if (self){
        self.username = username;
        self.name = name;
        self.surname = surname;
        self.prefix = prefix;
        self.phone = phone;
        self.timezone = timezone;
        self.wallet = wallet;
        self.email = email;
    }
    return self;
}

-(NSString *) description{
    return [NSString stringWithFormat:@"\n Username: %@ \n Name: %@ \n Surname: %@ \n Prefix: %@ \n Phone: %@ \n Timezone: %@ \n Wallet: \n %@",self.username,self.name,self.surname,self.prefix,self.phone,self.timezone,self.wallet];
}


@end


@implementation PNPNotification
-(id) initWithId:(NSNumber *) identifier
    creationDate:(NSDate *) created
         message:(NSString *) message
     referenceId:(NSNumber *) referenceId
          userId:(NSNumber *) userId
            type:(NSString *) type{
    
    self = [super init];
    if(self){
        self.identifier = identifier;
        self.created = created;
        self.message = message;
        self.referenceId = referenceId;
        self.userId = userId;
        self.type = type;
    }
    return self;
}
-(NSString *) description{
    return [NSString stringWithFormat:@"\n ID: %@ \n Created: %@ \n Message: %@ \n ReferenceID: %@ \n UserID: %@ \n Type: %@ \n",self.identifier,self.created,self.message,self.referenceId,self.userId,self.type];
}
@end

@implementation PNPPango

-(id) initWithIdentifier:(NSNumber *) identifier
                   alias:(NSString *) alias
                  serial:(NSString *) serial
                  status:(NSString *) status
                 creator:(NSString *) creator
            currencyCode:(NSString *) currencyCode
                  amount:(NSNumber *) amount
                   limit:(NSNumber *) limit
                 created:(NSDate *) created{
    self = [super init];
    if(self){
        self.identifier = identifier;
        self.alias = alias;
        self.serial = serial;
        self.status = status;
        self.creator = creator;
        self.currencyCode = currencyCode;
        self.amount = amount;
        self.limit = limit;
        self.created = created;
    }
    return self;
}

-(NSString *) description{
    return [NSString stringWithFormat:@"\n ID: %@ \n Alias: %@ \n Serial: %@ \n Amount: %@ \n Limit: %@ \n Currency: %@ \n Status: %@ \n Creator: %@ \n Created %@",self.identifier,self.alias,self.serial,self.amount,self.limit,self.currencyCode,self.status,self.creator,self.created];
}

@end


@implementation PNPPangoMovementEntity
-(id) initWithIdentifier:(NSNumber *)identifier{
    self = [super init];
    if(self){
        self.identifier = identifier;
    }
    return self;
}
@end

@implementation PNPPangoMovementWallet
-(NSString *) description{
    return @"Pango Pay Wallet";
}
@end
@implementation PNPPangoMovementPango

-(id) initWithIdentifier:(NSNumber *)identifier andAlias:(NSString *)alias{
    self = [super init];
    if(self){
        self.alias = alias;
        self.identifier = identifier;
    }
    return self;
}
-(NSString *) description{
    return [NSString stringWithFormat:@"%@",self.alias];
}

@end
@implementation PNPPangoMovementCommerce
-(id) initWithIdentifier:(NSNumber *)identifier name:(NSString *)name andSurname:(NSString *)surname{
    self = [super init];
    if(self){
        self.identifier = identifier;
        self.name = name;
        self.surname = surname;
    }
    return self;
}
-(NSString *) description{
    return [NSString stringWithFormat:@"%@ %@",self.name,self.surname];
}
@end

@implementation PNPPangoMovement
-(id) initWithEmitter:(PNPPangoMovementEntity *)emitter
             receiver:(PNPPangoMovementEntity *)receiver
                 type:(NSString *)type
               status:(NSString *)status
              concept:(NSString *)concept
               amount:(NSNumber *)amount
       currencySymbol:(NSString *)currencySymbol
                 date:(NSDate *)date{
    self = [super init];
    if(self){
        self.emitter = emitter;
        self.receiver = receiver;
        self.type = type;
        self.concept = concept;
        self.amount = amount;
        self.currencySymbol = currencySymbol;
        self.date = date;
    }
    return self;
    
}
-(NSString *) description{
    return [NSString stringWithFormat:@"\n Emitter: %@ \n Receiver: %@ \n Amount: %@ %@ \n Concept: %@ \n Date: %@ \n Type:%@",self.emitter,self.receiver,self.amount,self.currencySymbol,self.concept,self.date,self.type];
}
@end

@implementation PNPPangoMovementExpense
@end

@implementation PNPPangoMovementIncome
@end






