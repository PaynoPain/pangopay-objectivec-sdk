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

-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if (!self) {
        return nil;
    }
    self.amount         = [decoder decodeObjectForKey:@"amount"        ];
    self.retained       = [decoder decodeObjectForKey:@"retained"      ];
    self.currencyCode   = [decoder decodeObjectForKey:@"currencyCode"  ];
    self.currencySymbol = [decoder decodeObjectForKey:@"currencySymbol"];
    self.available      = [decoder decodeObjectForKey:@"available"     ];
    return self;
}


-(NSString *) description{
    return [NSString stringWithFormat:@" Amount: %@ \n  Retained: %@ \n  Available: %@ \n  Currency code: %@ \n  Currency Symbol: %@",self.amount,self.retained,self.available,self.currencyCode,self.currencySymbol];
}

-(void) encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeObject:self.amount forKey:@"amount"];
    [encoder encodeObject:self.retained forKey:@"retained"];
    [encoder encodeObject:self.currencyCode forKey:@"currencyCode"];
    [encoder encodeObject:self.currencySymbol forKey:@"currencySymbol"];
    [encoder encodeObject:self.available forKey:@"available"];
}

@end

@implementation PNPUser


-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.username   = [decoder decodeObjectForKey:@"username"];
    self.name       = [decoder decodeObjectForKey:@"name"    ];
    self.surname    = [decoder decodeObjectForKey:@"surname" ];
    self.email      = [decoder decodeObjectForKey:@"email"   ];
    self.prefix     = [decoder decodeObjectForKey:@"prefix"  ];
    self.phone      = [decoder decodeObjectForKey:@"phone"   ];
    self.timezone   = [decoder decodeObjectForKey:@"timezone"];
    self.wallet     = [decoder decodeObjectForKey:@"wallet"];
    return self;
}


-(void) encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeObject:self.username forKey:@"username"];
    [encoder encodeObject:self.name     forKey:@"name"    ];
    [encoder encodeObject:self.surname  forKey:@"surname" ];
    [encoder encodeObject:self.email    forKey:@"email"   ];
    [encoder encodeObject:self.prefix   forKey:@"prefix"  ];
    [encoder encodeObject:self.phone    forKey:@"phone"   ];
    [encoder encodeObject:self.timezone forKey:@"timezone"];
    [encoder encodeObject:self.wallet   forKey:@"wallet"  ];
}

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


-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if (!self) {
        return nil;
    }
    self.identifier = [decoder decodeObjectForKey:@"identifier"];
    self.created = [decoder decodeObjectForKey:@"created"];
    self.message = [decoder decodeObjectForKey:@"message"];
    self.referenceId = [decoder decodeObjectForKey:@"referenceId"];
    self.userId = [decoder decodeObjectForKey:@"userId"];
    self.type = [decoder decodeObjectForKey:@"type"];
    return self;
}
-(void) encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeObject:self.identifier forKey:@"identifier"];
    [encoder encodeObject:self.created forKey:@"created"];
    [encoder encodeObject:self.message forKey:@"message"];
    [encoder encodeObject:self.referenceId forKey:@"referenceId"];
    [encoder encodeObject:self.userId forKey:@"userId"];
    [encoder encodeObject:self.type forKey:@"type"];
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


-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if(!self) return nil;
    self.identifier     = [decoder decodeObjectForKey:@"identifier"];
    self.alias          = [decoder decodeObjectForKey:@"alias"];
    self.serial         = [decoder decodeObjectForKey:@"serial"];
    self.status         = [decoder decodeObjectForKey:@"status"];
    self.creator        = [decoder decodeObjectForKey:@"creator"];
    self.currencyCode   = [decoder decodeObjectForKey:@"currencyCode"];
    self.amount         = [decoder decodeObjectForKey:@"amount"];
    self.limit          = [decoder decodeObjectForKey:@"limit"];
    self.created        = [decoder decodeObjectForKey:@"created"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeObject:self.identifier forKey:@"identifier"];
    [encoder encodeObject:self.alias forKey:@"alias"];
    [encoder encodeObject:self.serial forKey:@"serial"];
    [encoder encodeObject:self.status forKey:@"status"];
    [encoder encodeObject:self.creator forKey:@"creator"];
    [encoder encodeObject:self.currencyCode forKey:@"currencyCode"];
    [encoder encodeObject:self.amount forKey:@"amount"];
    [encoder encodeObject:self.limit forKey:@"limit"];
    [encoder encodeObject:self.created forKey:@"created"];
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
-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if(!self) return nil;
    self.identifier = [decoder decodeObjectForKey:@"identifier"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeObject:self.identifier forKey:@"identifier"];
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

-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if(!self) return nil;
    self.identifier = [decoder decodeObjectForKey:@"identifier"];
    self.alias = [decoder decodeObjectForKey:@"alias"];
    return self;
}
-(void) encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeObject:self.alias forKey:@"alias"];
    [encoder encodeObject:self.identifier forKey:@"identifier"];
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

-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if(!self) return nil;
    self.identifier = [decoder decodeObjectForKey:@"identifier"];
    self.name = [decoder decodeObjectForKey:@"name"];
    self.surname = [decoder decodeObjectForKey:@"surname"];
    return self;
}
-(void) encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeObject:self.identifier forKey:@"identifier"];
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.surname forKey:@"surname"];
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

-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if(!self) return nil;
    self.emitter = [decoder decodeObjectForKey:@"emitter"];
    self.receiver = [decoder decodeObjectForKey:@"receiver"];
    self.type = [decoder decodeObjectForKey:@"type"];
    self.concept = [decoder decodeObjectForKey:@"concept"];
    self.amount = [decoder decodeObjectForKey:@"amount"];
    self.currencySymbol = [decoder decodeObjectForKey:@"currencySymbol"];
    self.date = [decoder decodeObjectForKey:@"date"];
    
    return self;
}

-(void) encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeObject:self.emitter forKey:@"emitter"];
    [encoder encodeObject:self.receiver forKey:@"receiver"];
    [encoder encodeObject:self.type forKey:@"type"];
    [encoder encodeObject:self.concept forKey:@"concept"];
    [encoder encodeObject:self.amount forKey:@"amount"];
    [encoder encodeObject:self.currencySymbol forKey:@"currencySymbol"];
    [encoder encodeObject:self.date forKey:@"date"];
}

-(NSString *) description{
    return [NSString stringWithFormat:@"\n Emitter: %@ \n Receiver: %@ \n Amount: %@ %@ \n Concept: %@ \n Date: %@ \n Type:%@",self.emitter,self.receiver,self.amount,self.currencySymbol,self.concept,self.date,self.type];
}
@end

@implementation PNPPangoMovementExpense
@end

@implementation PNPPangoMovementIncome
@end



@implementation PNPTransactionEntity

-(NSString *) tableString{
    return @"";
}

-(id) initWithCoder:(NSCoder *) decoder{
    self = [super init];
    if(!self) return nil;
    return self;
}

-(void) encodeWithCoder:(NSCoder *) encoder{
    
}

@end


@implementation PNPTransactionReceiver

@end

@implementation PNPTransactionEmitter

@end


@implementation PNPTransactionReceiverUser

-(id) initWithName:(NSString *) name
            prefix:(NSString *) prefix
             phone:(NSString *) phone
             email:(NSString *) email{
    self = [super init];
    if(!self) return nil;
    
    self.name = name;
    self.prefix = prefix;
    self.phone = phone;
    self.email = email;
    
    return self;
}

-(NSString *) description{
    return [NSString stringWithFormat:@"\n Name: %@ \n Phone: +%@ %@ \n Email: %@ \n",self.name,self.prefix,self.phone,self.email];
}

-(NSString *) tableString{
    return [NSString stringWithFormat:@"%@",self.name];
}


-(id) initWithCoder:(NSCoder *) decoder{
    self = [super init];
    if(!self) return nil;
    
    self.name      = [decoder decodeObjectForKey:@"name"];
    self.prefix    = [decoder decodeObjectForKey:@"prefix"];
    self.phone     = [decoder decodeObjectForKey:@"phone"];
    self.email     = [decoder decodeObjectForKey:@"email"];
    
    return self;
}

-(void) encodeWithCoder:(NSCoder *) encoder{
    [encoder encodeObject:self.name   forKey:@"name"];
    [encoder encodeObject:self.prefix forKey:@"prefix"];
    [encoder encodeObject:self.phone  forKey:@"phone"];
    [encoder encodeObject:self.email  forKey:@"email"];
}

@end

@implementation PNPTransactionReceiverUnregistered

-(id) initWithPrefix:(NSString *)prefix
            andPhone:(NSString *)phone{
    
    self = [super init];
    if(!self) return nil;
    self.prefix = prefix;
    self.phone = phone;
    return self;
    
}

-(NSString *) description{
    return [NSString stringWithFormat:@"+%@ %@",self.prefix,self.phone];
}

-(NSString *) tableString{
    return [self description];
}


-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if(!self) return nil;
    self.prefix = [decoder decodeObjectForKey:@"prefix"];
    self.phone = [decoder decodeObjectForKey:@"phone"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeObject:self.prefix forKey:@"prefix"];
    [encoder  encodeObject:self.phone forKey:@"phone"];
}

@end


@implementation PNPTransactionReceiverHalcash

-(NSString *) description{
    return @"Hal-Cash";
}

-(NSString *) tableString{
    return [self description];
}
@end





@implementation PNPTransactionEmitterUser

-(id) initWithName:(NSString *) name
            prefix:(NSString *) prefix
             phone:(NSString *) phone
             email:(NSString *) email
         avatarUrl:(NSURL *) avatar{
    self = [super init];
    if(!self) return nil;
    
    self.name = name;
    self.prefix = prefix;
    self.phone = phone;
    self.email = email;
    self.avatarUrl = avatar;
    
    return self;
}

-(NSString *) description{
    return [NSString stringWithFormat:@"\n Name: %@ \n Phone: +%@ %@ \n Email: %@ \n Avatar Url: %@ \n",self.name,self.prefix,self.phone,self.email,self.avatarUrl];
}

-(NSString *) tableString{
    return [NSString stringWithFormat:@"%@",self.name];
}

-(id) initWithCoder:(NSCoder *) decoder{
    self = [super init];
    if(!self) return nil;
    
    self.name      = [decoder decodeObjectForKey:@"name"];
    self.prefix    = [decoder decodeObjectForKey:@"prefix"];
    self.phone     = [decoder decodeObjectForKey:@"phone"];
    self.email     = [decoder decodeObjectForKey:@"email"];
    self.avatarUrl = [decoder decodeObjectForKey:@"avatarUrl"];
    
    return self;
}

-(void) encodeWithCoder:(NSCoder *) encoder{
    [encoder encodeObject:self.name   forKey:@"name"];
    [encoder encodeObject:self.prefix forKey:@"prefix"];
    [encoder encodeObject:self.phone  forKey:@"phone"];
    [encoder encodeObject:self.email  forKey:@"email"];
    [encoder encodeObject:self.avatarUrl forKey:@"avatarUrl"];
}

@end

@implementation PNPTransactionEmitterPango

-(NSString *) tableString{
    return @"Pango";
}

-(NSString *) description{
    return @"Pango";
}

@end

@implementation PNPTransactionEmitterHalcash

-(NSString *) tableString{
    return @"Hal-Cash cancellation";
}

-(NSString *) description{
    return @"Hal-Cash cancellation";
}

@end


@implementation PNPTransaction

-(id) initWithIdentifier:(NSNumber *) identifier
                  amount:(NSNumber *) amount
           currencyCode :(NSString *) currencyCode
          currencySymbol:(NSString *) currencySymbol
                 concept:(NSString *) concept
                  status:(NSString *) status
                 created:(NSDate *) created
               andEntity:(PNPTransactionEntity *) entity{
    self = [super init];
    if(! self) return nil;
    self.identifier = identifier;
    self.amount = amount;
    self.currencyCode = currencyCode;
    self.currencySymbol = currencySymbol;
    self.concept = concept;
    self.status = status;
    self.created= created;
    self.entity = entity;
    return self;
}


-(NSString *) description{
    return [NSString stringWithFormat:@"\n ID: %@ \n Amount: %@ %@ \n Concept: %@ \n Status: %@ \n Created: %@ \n Entity: %@ \n",self.identifier,self.amount,self.currencySymbol,self.concept,self.status,self.created,self.entity];
}

-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if(! self ) return nil;
    self.identifier = [decoder decodeObjectForKey:@"identifier"];
    self.amount = [decoder decodeObjectForKey:@"amount"];
    self.currencyCode = [decoder decodeObjectForKey:@"currencyCode"];
    self.currencySymbol = [decoder decodeObjectForKey:@"currencySymbol"];
    self.concept = [decoder decodeObjectForKey:@"concept"];
    self.status = [decoder decodeObjectForKey:@"status"];
    self.created = [decoder decodeObjectForKey:@"created"];
    self.entity = [decoder decodeObjectForKey:@"entity"];
    
    return self;
}

-(void) encodeWithCoder:(NSCoder *) encoder{
    [encoder encodeObject:self.identifier forKey:@"identifier"];
    [encoder encodeObject:self.amount forKey:@"amount"];
    [encoder encodeObject:self.currencyCode forKey:@"currencyCode"];
    [encoder encodeObject:self.currencySymbol forKey:@"currencySymbol"];
    [encoder encodeObject:self.concept forKey:@"concept"];
    [encoder encodeObject:self.status forKey:@"status"];
    [encoder encodeObject:self.created forKey:@"created"];
    [encoder encodeObject:self.entity forKey:@"entity"];
}


@end

@implementation PNPTransactionReceived

@end

@implementation PNPTransactionSent

@end

@implementation PNPTransactionPending


@end


@implementation PNPPaymentRequest

-(id) initWithIdentifier:(NSNumber *) identifier
                  amount:(NSNumber *) amount
          currencySymbol:(NSString *) currencySymbol
            creationDate:(NSDate *) created
                 concept:(NSString *) concept
                  prefix:(NSString *) prefix
                   phone:(NSString *) phone
                    name:(NSString *) name{
    self= [super init];
    if(!self) return nil;
    self.identifier     = identifier;
    self.amount         = amount;
    self.currencySymbol = currencySymbol;
    self.created        = created;
    self.concept        = concept;
    self.prefix         = prefix;
    self.phone          = phone;
    self.name           = name;
    return self;
}

-(NSString *) description{
    return [NSString stringWithFormat:@"\n ID: %@ \n Amount: %@ %@ \n Created: %@ \n Concept: %@ \n Phone: +%@ %@ \n Name: %@ \n",self.identifier,self.amount,self.currencySymbol,self.created,self.concept,self.prefix,self.phone,self.name];
}

-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if(!self) return nil;
    self.identifier = [decoder decodeObjectForKey:@"identifier"];
    self.amount = [decoder decodeObjectForKey:@"amount"];
    self.currencySymbol = [decoder decodeObjectForKey:@"currencySymbol"];
    self.created = [decoder decodeObjectForKey:@"created"];
    self.concept = [decoder decodeObjectForKey:@"concept"];
    self.prefix = [decoder decodeObjectForKey:@"prefix"];
    self.phone = [decoder decodeObjectForKey:@"phone"];
    self.name = [decoder decodeObjectForKey:@"name"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeObject:self.identifier forKey:@"identifier"];
    [encoder encodeObject:self.amount forKey:@"amount"];
    [encoder encodeObject:self.currencySymbol forKey:@"currencySymbol"];
    [encoder encodeObject:self.created forKey:@"created"];
    [encoder encodeObject:self.concept forKey:@"concept"];
    [encoder encodeObject:self.prefix  forKey:@"prefix"];
    [encoder encodeObject:self.phone forKey:@"phone"];
    [encoder encodeObject:self.name forKey:@"name"];
}



@end

@implementation PNPCountry

-(id) initWithName:(NSString *) name
            prefix:(NSString *) prefix
              code:(NSString *) code
    currencySymbol:(NSString *) currencySymbol
      currencyCode:(NSString *) currencyCode{
    self = [super init];
    if(! self )return nil;
    self.name = name;
    self.prefix = prefix;
    self.code= code;
    self.currencySymbol = currencySymbol;
    self.currencyCode = currencyCode;
    return self;
}

-(NSString *) description{
    return [NSString stringWithFormat:@"\n Name: %@ \n Prefix: %@ \n Code: %@ \n CurrencySymbol: %@ \n CurrencyCode: %@ \n",self.name,self.prefix,self.code,self.currencySymbol,self.currencyCode];
}

-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if(! self) return nil;
    self.name = [decoder decodeObjectForKey:@"name"];
    self.prefix = [decoder decodeObjectForKey:@"prefix"];
    self.code = [decoder decodeObjectForKey:@"code"];
    self.currencySymbol = [decoder decodeObjectForKey:@"currencySymbol"];
    self.currencyCode = [decoder decodeObjectForKey:@"currencyCode"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.code forKey:@"code"];
    [encoder encodeObject:self.prefix forKey:@"prefix"];
    [encoder encodeObject:self.currencyCode forKey:@"currencyCode"];
    [encoder encodeObject:self.currencySymbol forKey:@"currencySymbol"];
}

@end

@implementation PNPUserValidationItem

-(id) initWithStatus:(NSString *)status{
    self = [super init];
    if(! self ) return nil;
    if(self){
        if([status isEqualToString:@"AC"]){
            self.isUploaded = YES;
            self.isValidated = YES;
            self.isDeclined = NO;
        }else if ([status isEqualToString:@"DE"]){
            self.isUploaded = YES;
            self.isValidated = NO;
            self.isDeclined = YES;
            
        }else if([status isEqualToString:@"PE"]){
            self.isUploaded = YES;
            self.isValidated = NO;
            self.isDeclined = NO;
        }else{
            self.isUploaded = NO;
            self.isValidated = NO;
            self.isDeclined = NO;
        }
    }
    return self;
}

-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if(! self) return nil;
    self.isUploaded = [decoder decodeBoolForKey:@"uploaded"];
    self.isValidated = [decoder decodeBoolForKey:@"validated"];
    self.isDeclined = [decoder decodeBoolForKey:@"declined"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeBool:self.isUploaded forKey:@"uploaded"];
    [encoder encodeBool:self.isValidated forKey:@"validated"];
    [encoder encodeBool:self.isDeclined forKey:@"declined"];
}

-(NSString *) description{
    return [NSString stringWithFormat:@"\n IsValidated: %@ \n IsDeclined: %@ \n IsUploaded: %@ \n",[NSNumber numberWithBool:self.isValidated],[NSNumber numberWithBool:self.isDeclined],[NSNumber numberWithBool:self.isUploaded]];
}

@end

@implementation PNPUserValidation

-(id) initWithStatus:(BOOL)status
          andFrontId:(PNPUserValidationItem *)front
              rearId:(PNPUserValidationItem *)rear
                bill:(PNPUserValidationItem *)bill
        andAgreement:(PNPUserValidationItem *)agreement{
    self = [super init];
    if(! self) return nil;
    self.isValidated = status;
    self.idCardFront = front;
    self.idCardRear = rear;
    self.bill = bill;
    self.agreement = agreement;
    return self;
}

-(NSString *) description{
    return [NSString stringWithFormat:@"\n Validated: %@ \n IDFront: %@ \n IDBack: %@ \n Bill: %@ \n Agreement: %@ \n",[NSNumber numberWithBool:self.isValidated],self.idCardFront,self.idCardRear,self.bill,self.agreement];
}

-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if(! self) return nil;
    self.isValidated = [decoder decodeBoolForKey:@"validated"];
    self.idCardFront = [decoder decodeObjectForKey:@"front"];
    self.idCardRear = [decoder decodeObjectForKey:@"rear"];
    self.bill = [decoder decodeObjectForKey:@"bill"];
    self.agreement = [decoder decodeObjectForKey:@"agreement"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeBool:self.isValidated forKey:@"validated"];
    [encoder encodeObject:self.idCardFront forKey:@"front"];
    [encoder encodeObject:self.idCardRear forKey:@"rear"];
    [encoder encodeObject:self.bill forKey:@"bill"];
    [encoder encodeObject:self.agreement forKey:@"agreement"];
}

@end

@implementation PNPCreditCard

-(id) initWithIdentifier:(NSNumber *) identifier
                  number:(NSString *) number
                    year:(NSNumber *) year
                   month:(NSNumber *) month
                   alias:(NSString *) alias
                    type:(NSString *) type
               isDefault:(BOOL)def{
    self = [super init];
    if(!self) return nil;
    self.identifier = identifier;
    self.number = number;
    self.year = year;
    self.month = month;
    self.alias = alias;
    self.type = type;
    self.isDefault = def;
    
    return self;
}

-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if(!self) return nil;
    self.identifier = [decoder decodeObjectForKey:@"identifier"];
    self.number = [decoder decodeObjectForKey:@"number"];
    self.year = [decoder decodeObjectForKey:@"year"];
    self.month = [decoder decodeObjectForKey:@"month"];
    self.alias = [decoder decodeObjectForKey:@"alias"];
    self.type = [decoder decodeObjectForKey:@"type"];
    self.isDefault = [decoder decodeBoolForKey:@"isDefault"];
    return self;
    
}

-(NSString *) description{
    return [NSString stringWithFormat:@"\n ID: %@ \n Number: %@ \n Expiry: %@ - %@ \n Alias: %@ \n Type: %@ \n isDefault: %@ \n",self.identifier,self.number,self.month,self.year,self.alias,self.type,[NSNumber numberWithBool:self.isDefault]];
}

-(void) encodeWithCoder:(NSCoder *)encoder{
    
    [encoder encodeObject:self.identifier forKey:@"identifier"];
    [encoder encodeObject:self.number forKey:@"number"];
    [encoder encodeObject:self.year forKey:@"year"];
    [encoder encodeObject:self.month forKey:@"month"];
    [encoder encodeObject:self.alias forKey:@"alias"];
    [encoder encodeObject:self.type forKey:@"type"];
    [encoder encodeBool:self.isDefault forKey:@"isDefault"];
    
}

@end

@implementation PNPHalcashExtraction

-(id) initWithIdentifier:(NSNumber *) identifier
                  amount:(NSNumber *)amount
          currencySymbol:(NSString *)currencySymbol
                  status:(NSString *)status
                 created:(NSDate *)created
                  expiry:(NSDate *)expiry
                  ticket:(NSString *)ticket
           transactionId:(NSNumber *)transactionId{
    self = [super init];
    if(!self) return nil;
    self.identifier = identifier;
    self.amount= amount;
    self.currency = currencySymbol;
    self.status = status;
    self.date = created;
    self.expirationDate = expiry;
    self.ticket = ticket;
    self.transactioId = transactionId;
    return self;
    
}
-(BOOL) isCancellable{
    if([self.status isEqualToString:PNPHalcashExtractionStatusPending]){
        return YES;
    }
    return NO;
}

-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if(!self) return nil;
    self.identifier = [decoder decodeObjectForKey:@"identifier"];
    self.amount = [decoder decodeObjectForKey:@"amount"];
    self.currency = [decoder decodeObjectForKey:@"currency"];
    self.status = [decoder decodeObjectForKey:@"status"];
    self.date = [decoder decodeObjectForKey:@"date"];
    self.expirationDate = [decoder decodeObjectForKey:@"expirationDate"];
    self.ticket = [decoder decodeObjectForKey:@"ticket"];
    self.transactioId = [decoder decodeObjectForKey:@"transactionId"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)encoder{
    
    [encoder encodeObject:self.identifier forKey:@"identifier"];
    [encoder encodeObject:self.amount forKey:@"amount"];
    [encoder encodeObject:self.currency forKey:@"currency"];
    [encoder encodeObject:self.status forKey:@"status"];
    [encoder encodeObject:self.date forKey:@"date"];
    [encoder encodeObject:self.expirationDate forKey:@"expirationDate"];
    [encoder encodeObject:self.ticket forKey:@"ticket"];
    [encoder encodeObject:self.transactioId forKey:@"transactionId"];
    
}

-(NSString *)description{
    return [NSString stringWithFormat:@"\n ID: %@ \n Amount: %@ %@ \n Status: %@ \n Date: %@ \n Expiry: %@ \n Ticket: %@ \n TransactionId: %@ \n",_identifier,_amount,_currency,_status,_date,_expirationDate,_ticket,_transactioId];
}



@end

@implementation PNPLocation

-(id) initWithLocation:(CLLocation *)location
                  city:(NSString *)city
               address:(NSString *)address
                  name:(NSString *)name{

    self = [super init];
    
    if (!self) return false;
    
    self.location = location;
    self.city = city;
    self.address = address;
    self.name = name;
    
    return self;
}

-(NSString *) description{
    return [NSString stringWithFormat:@"\n Name: %@ \n City: %@ \n Address: %@ \n",_name,_city,_address];
}

@end
