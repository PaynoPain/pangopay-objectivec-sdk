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

@implementation PNPCommerce

-(void) encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeObject:_commerceId forKey:@"commerceId"];
    [encoder encodeObject:_identifier forKey:@"identifier"];
    [encoder encodeObject:_name forKey:@"name"];
}

-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if (!self) {
        return nil;
    }
    _identifier = [decoder decodeObjectForKey:@"identifier"];
    _commerceId = [decoder decodeObjectForKey:@"commerceId"];
    _name = [decoder decodeObjectForKey:@"name"];
    return self;
}

-(id) initWithIdentifier:(NSNumber *) identifier
              commerceId:(NSNumber *) commerceId
                    name:(NSString *)name{
    self = [super init];
    if (!self) {
        return nil;
    }
    _commerceId = commerceId;
    _identifier = identifier;
    _name = name;
    return self;
}

@end

@implementation PNPUserCommerce

-(id) initWithAddress: (NSString *) address
                  cif: (NSString *) cif
                 city: (NSString *) city
           commerceId: (NSNumber *) commerceId
         contactPhone: (NSNumber *) contactPhone
              created: (NSDate *) dateCreated
             distance: (NSNumber *) distance
           identifier: (NSString *) identifier
                  lat: (NSNumber *) lat
                  lon: (NSNumber *) lon
             modified: (NSDate *) modified
                 name: (NSString *) name
             province: (NSString *) province
          totalPoints: (NSNumber *) totalPoints
          totalPromos: (NSNumber *) totalPromos
              zipCode: (NSNumber *) zipCode
         commerceLogo:(NSString *)commerceLogo
   commerceBackground:(NSString *)commerceBackground
           hasLoyalty:(BOOL)hasLoyalty
      promoRegistered:(BOOL)promoRegistered
           isFavorite:(BOOL)favorite{
    
    self = [super init];
    if (!self) {
        return nil;
    }
    _address = address;
    _cif = cif;
    _city = city;
    _commerceId = commerceId;
    _contactPhone = contactPhone;
    _dateCreated = dateCreated;
    _distance = distance;
    _identifier = identifier;
    _lat = lat;
    _lon = lon;
    _modified = modified;
    _name = name;
    _province = province;
    _totalPoints = totalPoints;
    _totalPromos = totalPromos;
    _zipCode = zipCode;
    _commerceBackground = commerceBackground;
    _commerceLogo = commerceLogo;
    _hasLoyalty = hasLoyalty;
    _promoRegistered = promoRegistered;
    _favorite = favorite;
    return self;
}

-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if (!self) {
        return nil;
    }
    _address = [decoder decodeObjectForKey:@"address"];
    _cif = [decoder decodeObjectForKey:@"cif"];
    _city = [decoder decodeObjectForKey:@"city"];
    _commerceId = [decoder decodeObjectForKey:@"commerceId"];
    _contactPhone = [decoder decodeObjectForKey:@"contactPhone"];
    _dateCreated = [decoder decodeObjectForKey:@"dateCreated"];
    _distance = [decoder decodeObjectForKey:@"distance"];
    _identifier = [decoder decodeObjectForKey:@"identifier"];
    _lat = [decoder decodeObjectForKey:@"lat"];
    _lon = [decoder decodeObjectForKey:@"lon"];
    _modified = [decoder decodeObjectForKey:@"modified"];
    _name = [decoder decodeObjectForKey:@"name"];
    _province = [decoder decodeObjectForKey:@"province"];
    _totalPoints = [decoder decodeObjectForKey:@"totalPoints"];
    _totalPromos = [decoder decodeObjectForKey:@"totalPromos"];
    _zipCode = [decoder decodeObjectForKey:@"zipCode"];
    _commerceLogo = [decoder decodeObjectForKey:@"logo"];
    _commerceBackground = [decoder decodeObjectForKey:@"background"];
    return self;
}
-(void) encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeObject:_address forKey:@"address"];
    [encoder encodeObject:_cif forKey:@"cif"];
    [encoder encodeObject:_city forKey:@"city"];
    [encoder encodeObject:_commerceId forKey:@"commerceId"];
    [encoder encodeObject:_contactPhone forKey:@"contactPhone"];
    [encoder encodeObject:_dateCreated forKey:@"dateCreated"];
    [encoder encodeObject:_distance forKey:@"distance"];
    [encoder encodeObject:_identifier forKey:@"identifier"];
    [encoder encodeObject:_lat forKey:@"lat"];
    [encoder encodeObject:_lon forKey:@"lon"];
    [encoder encodeObject:_modified forKey:@"modified"];
    [encoder encodeObject:_name forKey:@"name"];
    [encoder encodeObject:_province forKey:@"province"];
    [encoder encodeObject:_totalPoints forKey:@"totalPoints"];
    [encoder encodeObject:_totalPromos forKey:@"totalPromos"];
    [encoder encodeObject:_zipCode forKey:@"zipCode"];
    [encoder encodeObject:_commerceBackground forKey:@"background"];
    [encoder encodeObject:_commerceLogo forKey:@"logo"];
}


@end

@implementation PNPSector
-(id) initWithIdentifier:(NSNumber *) identifier
             description:(NSString *) desc{
    self = [super init];
    if(self){
        self.identifier = identifier;
        self.desc = desc;
    }
    return self;
}

-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if (!self) {
        return nil;
    }
    _identifier = [decoder decodeObjectForKey:@"identifier"];
    _desc = [decoder decodeObjectForKey:@"desc"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeObject:_identifier forKey:@"identifier"];
    [encoder encodeObject:_desc forKey:@"desc"];
}

@end

@implementation PNPNotification
-(id) initWithId:(NSNumber *) identifier
    creationDate:(NSDate *) created
         message:(NSString *) message
     referenceId:(NSNumber *) referenceId
          userId:(NSNumber *) userId
            type:(NSString *) type
            read:(BOOL)read{
    
    self = [super init];
    if(self){
        self.identifier = identifier;
        self.created = created;
        self.message = message;
        self.referenceId = referenceId;
        self.userId = userId;
        self.type = type;
        self.read = read;
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
    self.read = [decoder decodeBoolForKey:@"read"];
    return self;
}
-(void) encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeObject:self.identifier forKey:@"identifier"];
    [encoder encodeObject:self.created forKey:@"created"];
    [encoder encodeObject:self.message forKey:@"message"];
    [encoder encodeObject:self.referenceId forKey:@"referenceId"];
    [encoder encodeObject:self.userId forKey:@"userId"];
    [encoder encodeObject:self.type forKey:@"type"];
    [encoder encodeBool:self.read forKey:@"read"];
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
    return [NSString stringWithFormat:@"%@",self.name];
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
    return NSLocalizedString(@"Tipo de transacción desconocido", nil);
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

@implementation PNPTransactionReceiverCommerce

-(id) initWithName:(NSString *)name{
    self = [super init];
    if(!self) return nil;
    self.name = name;
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(!self) return nil;
    self.name = [aDecoder decodeObjectForKey:@"name"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.name forKey:@"name"];
}

-(NSString *) description{
    return _name;
}

-(NSString *) tableString{
    return [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Pago en", nil),_name];
}
@end

@implementation PNPTransactionEmitterCommerce

-(id) initWithName:(NSString *)name{
    self = [super init];
    if(!self) return nil;
    self.name = name;
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(!self) return nil;
    self.name = [aDecoder decodeObjectForKey:@"name"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.name forKey:@"name"];
}

-(NSString *) description{
    return _name;
}

-(NSString *) tableString{
    return [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Cancelación en",nil),_name];
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
    return NSLocalizedString(@"Extracción Hal-Cash", nil);
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

@implementation PNPTransactionReceiverPango

-(NSString *) tableString{
    return @"Pango";
}

-(NSString *) description{
    return @"Pango";
}

@end

@implementation PNPTransactionEmitterRecharge

-(id) initWithAmount:(NSNumber *) amount
	   currencyCode :(NSString *) currencyCode
	  currencySymbol:(NSString *) currencySymbol
			  status:(NSString *) status
			 created:(NSDate *) created
			 barcode:(NSURL*) barcode {
	
    self = [super init];
    if(!self) return nil;
    
	_amount = amount;
	_currencyCode = currencyCode;
	_currencySymbol = currencySymbol;
	_status = status;
	_created = created;
	_barcode = barcode;
	
    return self;
}


-(id) initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if(!self) return nil;
	_amount = [decoder decodeObjectForKey:@"amount"];
	_created = [decoder decodeObjectForKey:@""];
	_currencyCode = [decoder decodeObjectForKey:@"currencyCode"];
	_currencySymbol = [decoder decodeObjectForKey:@"currencySymbol"];
	_barcode = [decoder decodeObjectForKey:@"barcode"];
	_status = [decoder decodeObjectForKey:@"status"];
	return self;
	
}

-(void) encodeWithCoder:(NSCoder *) encoder{
    [encoder encodeObject:self.amount forKey:@"amount"];
    [encoder encodeObject:self.currencyCode forKey:@"currencyCode"];
    [encoder encodeObject:self.currencySymbol forKey:@"currencySymbol"];
    [encoder encodeObject:self.status forKey:@"status"];
    [encoder encodeObject:self.created forKey:@"created"];
    [encoder encodeObject:self.barcode forKey:@"barcode"];
}


-(NSString *) tableString{
    return NSLocalizedString(@"Recarga monedero", nil);
}

-(NSString *) description{
    return @"Wallet Recharge";
}

@end

@implementation PNPTransactionEmitterRechargePromo

-(NSString *) tableString{
    return NSLocalizedString(@"Recarga promoción", nil);
}

@end

@implementation PNPTransactionEmitterHalcash

-(NSString *) tableString{
    return NSLocalizedString(@"Cancelación Hal-Cash",nil);
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
                    name:(NSString *) name
                  status:(NSString *) status{
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
    self.status         = status;
    return self;
}

-(NSString *) description{
    return [NSString stringWithFormat:@"\n ID: %@ \n Amount: %@ %@ \n Created: %@ \n Concept: %@ \n Phone: +%@ %@ \n Name: %@ \n",self.identifier,self.amount,self.currencySymbol,self.created,self.concept,self.prefix,self.phone,self.name];
}

-(BOOL) isEqual:(id)object{
    return [self.identifier intValue] == [((PNPPaymentRequest *)object).identifier intValue];
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
    self.status = [decoder decodeObjectForKey:@"status"];
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
    [encoder encodeObject:self.status forKey:@"status"];
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

@implementation PNPOrder

-(id) initWithIdentifier:(NSNumber *) identifier
               reference:(NSString *) reference
                 concept:(NSString *) concept
                 created:(NSDate *)   created
                commerce:(NSString *) commerce
                  amount:(NSNumber *) amount
               netAmount:(NSNumber *) netAmount
       loyaltyPercentage:(NSNumber *) loyaltyPercentage
   loyaltyDiscountAmount:(NSNumber *) loyaltyDiscountAmount
                currency:(NSString *) currency
              orderLines:(NSArray *) orderLines{
    self = [super init];
    if(!self) return nil;
    self.identifier = identifier;
    self.reference  = reference;
    self.concept = concept;
    self.created = created;
    self.commerce = commerce;
    self.amount = amount;
    self.netAmount = netAmount;
    self.loyaltyPercentage = loyaltyPercentage;
    self.loyaltyDiscountAmount = loyaltyDiscountAmount;
    self.currency = currency;
    self.orderLines = orderLines;
    
    return self;
    
}

-(NSString *) description{
    return [NSString stringWithFormat:@"\n ID: %@ \n Reference: %@ Concept: %@ \n Created: %@ \n Commerce: %@ \n Amount: %@ %@ OrderLines: %@\n ",_identifier,_reference,_concept,_created,_commerce,_amount,_currency,_orderLines];
}
@end

@implementation PNPOrderLine

-(id) initWithIdentifier:(NSNumber *) identifier
                   name:(NSString *) name
                  amount:(NSNumber *) amount
               netAmount:(NSNumber *) netAmount
                 orderId:(NSNumber *) orderId
                  number:(NSNumber *) number
                refunded:(BOOL) refunded
                    type:(NSString *)type
              externalId:(NSNumber *)externalId{
    self = [super init];
    if(!self) return nil;
    self.identifier = identifier;
    self.name = name;
    self.amount = amount;
    self.netAmount = netAmount;
    self.orderId = orderId;
    self.number = number;
    self.refunded = refunded;
    self.type = type;
    self.externalId = externalId;
    return self;
}


-(NSString *) description{
    return [NSString stringWithFormat:@"\n ID: %@ \n Name: %@ Amount: %@ \n NetAmount: %@ \n OrderId: %@ \n number: %@ refunded:%d type:%@ externalId: %@\n ",_identifier,_name,_amount,_netAmount,_orderId,_number,_refunded,_type,_externalId];
}

-(id)copyWithZone:(NSZone *)zone
{
    PNPOrderLine *newOrderLine = [[PNPOrderLine allocWithZone:zone] init];
    newOrderLine.identifier = _identifier;
    newOrderLine.name = _name ;
    newOrderLine.amount = _amount ;
    newOrderLine.netAmount = _netAmount ;
    newOrderLine.orderId = _orderId ;
    newOrderLine.number = _number ;
    newOrderLine.type = _type ;
    newOrderLine.externalId = _externalId ;
    newOrderLine.refunded = self.refunded;
    return newOrderLine;
}

@end

@implementation PNPCommerceOrder

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
              orderLines:(NSArray *) orderLines{
    self = [super  init];
    if(!self) return nil;
    self.identifier = identifier;
    self.reference = reference;
    self.type = type;
    self.concept = concept;
    self.status = status;
    self.amount = amount;
    self.netAmount = netAmount;
    self.refundAmount = refundAmount;
    self.currencySymbol = currencySymbol;
    self.mail = mail;
    self.userId = userId;
    self.name = name;
    self.surname = surname;
    self.phone = phone;
    self.prefix = prefix;
    self.created = created;
    self.orderLines = orderLines;
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super  init];
    if(!self) return nil;
    
    self.identifier = [aDecoder decodeObjectForKey:@"identifier"];
    self.reference = [aDecoder decodeObjectForKey:@"reference"];
    self.type = [aDecoder decodeObjectForKey:@"type"];
    self.concept = [aDecoder decodeObjectForKey:@"concept"];
    self.status = [aDecoder decodeObjectForKey:@"status"];
    self.amount = [aDecoder decodeObjectForKey:@"amount"];
    self.netAmount = [aDecoder decodeObjectForKey:@"netAmount"];
    self.currencySymbol = [aDecoder decodeObjectForKey:@"currencySymbol"];
    self.orderLines = [aDecoder decodeObjectForKey:@"orderLines"];
    
    self.mail = [aDecoder decodeObjectForKey:@"mail"];
    self.userId = [aDecoder decodeObjectForKey:@"userId"];
    self.name = [aDecoder decodeObjectForKey:@"name"];
    self.surname = [aDecoder decodeObjectForKey:@"surname"];
    self.prefix =[aDecoder decodeObjectForKey:@"prefix"];
    self.phone =[aDecoder decodeObjectForKey:@"phone"];
    self.created=[aDecoder decodeObjectForKey:@"created"];
    
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_identifier forKey:@"identifier"];
    [aCoder encodeObject:_reference forKey:@"reference"];
    [aCoder encodeObject:_type forKey:@"type"];
    [aCoder encodeObject:_concept forKey:@"concept"];
    [aCoder encodeObject:_status forKey:@"status"];
    [aCoder encodeObject:_amount forKey:@"amount"];
    [aCoder encodeObject:_netAmount forKey:@"netAmount"];
    [aCoder encodeObject:_currencySymbol forKey:@"currencySymbol"];
    [aCoder encodeObject:_orderLines forKey:@"orderLines"];
    
    [aCoder encodeObject:_mail forKey:@"mail"];
    [aCoder encodeObject:_userId forKey:@"userId"];
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_surname forKey:@"surname"];
    [aCoder encodeObject:_prefix forKey:@"prefix"];
    [aCoder encodeObject:_phone forKey:@"phone"];
    [aCoder encodeObject:_created forKey:@"created"];
}

-(NSString *) description{
    return [NSString stringWithFormat:@"\n ID: %@ \n Reference: %@ \n Mail: %@ \n UserId: %@ \n name: %@ \n surname: %@ \n Prefix: %@ \n Phone: %@ \n Status: %@ \n Created: %@",_identifier,_reference,_mail,_userId,_name,_surname,_prefix,_phone,_status,_created];
}


@end

@implementation PNPUserOrder

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
               reference:(NSString *)reference{
    
    self = [super  init];
    if(!self) return nil;
    
    self.identifier = identifier;
    self.commerceName = commerceName;
    self.concept = concept;
    self.created = created;
    self.currencySymbol = currencySymbol;
    self.amount = amount;
    self.netAmount = netAmount;
    self.mail = mail;
    self.orderLines = orderLines;
    self.type = type;
    self.reference = reference;
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super  init];
    if(!self) return nil;
    self.identifier = [aDecoder decodeObjectForKey:@"identifier"];
    self.commerceName = [aDecoder decodeObjectForKey:@"commerceName"];
    self.concept = [aDecoder decodeObjectForKey:@"concept"];
    self.created = [aDecoder decodeObjectForKey:@"created"];
    self.currencySymbol = [aDecoder decodeObjectForKey:@"currencySymbol"];
    self.amount = [aDecoder decodeObjectForKey:@"amount"];
    self.netAmount = [aDecoder decodeObjectForKey:@"netAmount"];
    self.mail = [aDecoder decodeObjectForKey:@"mail"];
    self.orderLines = [aDecoder decodeObjectForKey:@"orderLines"];
    self.type = [aDecoder decodeObjectForKey:@"type"];
    self.reference = [aDecoder decodeObjectForKey:@"reference"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_identifier forKey:@"identifier"];
    [aCoder encodeObject:_commerceName forKey:@"commerceName"];
    [aCoder encodeObject:_concept forKey:@"concept"];
    [aCoder encodeObject:_created forKey:@"created"];
    [aCoder encodeObject:_currencySymbol forKey:@"currencySymbol"];
    [aCoder encodeObject:_amount forKey:@"amount"];
    [aCoder encodeObject:_netAmount forKey:@"netAmount"];
    [aCoder encodeObject:_mail forKey:@"mail"];
    [aCoder encodeObject:_orderLines forKey:@"orderLines"];
    [aCoder encodeObject:_type forKey:@"type"];
    [aCoder encodeObject:_reference forKey:@"reference"];
}

-(NSString *) description{
    return [NSString stringWithFormat:@"\nID: %@ \n Commerce Name: %@ Mail: %@ \n Concept: %@ \n Currency Symbol: %@ \n Amount: %@ \n Net Amount: %@ \n Order Lines: %@ \n Created: %@ type: %@ reference: %@" ,_identifier,_commerceName,_mail,_concept,_currencySymbol,_amount,_netAmount,_orderLines,_created,_type,_reference];
}



@end

@implementation PNPCoupon

-(id) initWithCode:(NSString *)code
        identifier:(NSNumber *)identifier
           promoId:(NSNumber *) promoId
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
              type:(NSString *)type{
    
    self = [super init];
    if(!self) return nil;
    
    _ccode = code;
    _favorite = favorite;
    _promoId = promoId;
    _identifier = identifier;
    _loyaltyIdentifier = loyaltyIdentifier;
    _actualUses = actualUses;
    _limitUses = limitUses;
    _companyName = companyName;
    _title = title;
    _viewed = viewed;
    _longDescription = description;
    _shortDescription = shortDescription;
    _logoUrl = logoUrl;
    _brandLogoUrl = brandLogoUrl;
    _startDate = startDate;
    _endDate = endDate;
    _validDays = validDays;
    _timeRanges = timeRanges;
    _fixedAmount = fixedAmount;
    _percentageAmount = percentageAmount;
    _gift = gift;
    _status = status;
    _products = products;
    _giftProducts = giftProducts;
    _type = type;
    
    return self;
}
-(BOOL) isEqual:(id)object{
    return [self.ccode isEqualToString:((PNPCoupon *)object).ccode];
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(!self) return nil;
    _ccode = [aDecoder decodeObjectForKey:@"code"];
    _status = [aDecoder decodeObjectForKey:@"status"];
    _promoId = [aDecoder decodeObjectForKey:@"promoId"];
    _identifier = [aDecoder decodeObjectForKey:@"identifier"];
    _loyaltyIdentifier = [aDecoder decodeObjectForKey:@"loyaltyIdentifier"];
    _actualUses = [aDecoder decodeObjectForKey:@"actualUses"];
    _limitUses = [aDecoder decodeObjectForKey:@"limitUses"];
    _companyName = [aDecoder decodeObjectForKey:@"companyName"];
    _title = [aDecoder decodeObjectForKey:@"title"];
    _longDescription = [aDecoder decodeObjectForKey:@"longDescription"];
    _shortDescription = [aDecoder decodeObjectForKey:@"shortDescription"];
    _logoUrl = [aDecoder decodeObjectForKey:@"logoUrl"];
    _brandLogoUrl = [aDecoder decodeObjectForKey:@"brandLogoUrl"];
    _startDate = [aDecoder decodeObjectForKey:@"startDate"];
    _favorite = [aDecoder decodeBoolForKey:@"favorite"];
    _viewed = [aDecoder decodeBoolForKey:@"viewed"];
    _endDate = [aDecoder decodeObjectForKey:@"endDate"];
    _gift = [aDecoder decodeObjectForKey:@"gift"];
    _percentageAmount = [aDecoder decodeObjectForKey:@"percentageAmount"];
    _fixedAmount = [aDecoder decodeObjectForKey:@"fixedAmount"];
    _giftProducts =[aDecoder decodeObjectForKey:@"giftProducts"];
    _products = [aDecoder decodeObjectForKey:@"products"];
    _type = [aDecoder decodeObjectForKey:@"type"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_ccode forKey:@"code"];
    [aCoder encodeObject:_promoId forKey:@"promoId"];
    [aCoder encodeObject:_identifier forKey:@"identifier"];
    [aCoder encodeObject:_loyaltyIdentifier forKey:@"loyaltyIdentifier"];
    [aCoder encodeObject:_actualUses forKey:@"actualUses"];
    [aCoder encodeObject:_limitUses forKey:@"limitUses"];
    [aCoder encodeObject:_companyName forKey:@"companyName"];
    [aCoder encodeBool:_favorite forKey:@"favorite"];
    [aCoder encodeBool:_viewed forKey:@"viewed"];
    [aCoder encodeObject:_title forKey:@"title"];
    [aCoder encodeObject:_longDescription forKey:@"longDescription"];
    [aCoder encodeObject:_status forKey:@"status"];
    [aCoder encodeObject:_shortDescription forKey:@"shortDescription"];
    [aCoder encodeObject:_logoUrl forKey:@"logoUrl"];
    [aCoder encodeObject:_brandLogoUrl forKey:@"brandLogoUrl"];
    [aCoder encodeObject:_startDate forKey:@"startDate"];
    [aCoder encodeObject:_endDate forKey:@"endDate"];
    [aCoder encodeObject:_fixedAmount forKey:@"fixedAmount"];
    [aCoder encodeObject:_percentageAmount forKey:@"percentageAmount"];
    [aCoder encodeObject:_gift forKey:@"gift"];
    [aCoder encodeObject:_type forKey:@"type"];
    [aCoder encodeObject:_giftProducts forKey:@"giftProducts"];
    [aCoder encodeObject:_products forKey:@"products"];
}


-(NSString *) description{
    return [NSString stringWithFormat:@"CODE: %@,FAVORITE: %hhd, Viewed: %hhd , Id:%@, promoId:%@, actualUses:%@, limitUses:%@, companyName:%@, Title:%@, longDescr:%@, shortDescr:%@, logoUrl:%@, brandLogoUrl:%@, startDate:%@, endDate:%@ products: %@  gift_products: %@ type:%@",_ccode,_favorite,_viewed,_identifier,_promoId,_actualUses,_limitUses,_companyName,_title,_longDescription,_shortDescription,_logoUrl,_brandLogoUrl,_startDate,_endDate,_products,_giftProducts,_type];
}


@end


@implementation PNPCPDaily
@end

@implementation PNPCPStampCard
@end

@implementation PNPCPMultiUssage
@end

@implementation PNPCPOneTime
@end

@implementation PNPCPExchange
@end

@implementation PNPCPLoyalty
@end

@implementation PNPCouponPromotion


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
                     web:(NSString *) web{
    self= [super init];
    if(!self) return nil;
    _identifier = identifier;
    _title = title;
    _longDescription = longDescription;
    _shortDescription = shortDescription;
    _type = type;
    _validDays = validDays;
    _products = products;
    _logoUrl = logoUrl;
    _brandLogoUrl = brandLogoUrl;
    _fixedAmount =fixedAmount;
    _percentageAmount = percentageAmount;
    _gift = gift;
    _giftProducts =giftProducts;
    _actualUses = actualUses;
    _limitUses = limitUses;
    _status = status;
    _startDate = startDate;
    _endDate = endDate;
    _company = company;
    _user = user;
    _created = created;
    _timeRanges = timeRanges;
    _web = web;
    return self;
}
-(BOOL) isEqual:(id)object{
    return [self.identifier isEqualToString:((PNPCouponPromotion *)object).identifier];
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(!self) return nil;
    _identifier = [aDecoder decodeObjectForKey:@"identifier"];
    _title = [aDecoder decodeObjectForKey:@"title"];
    _company = [aDecoder decodeObjectForKey:@"company"];
    _longDescription = [aDecoder decodeObjectForKey:@"longDescription"];
    _shortDescription = [aDecoder decodeObjectForKey:@"shortDescription"];
    _type = [aDecoder decodeObjectForKey:@"type"];
    _validDays = [aDecoder decodeObjectForKey:@"validDays"];
    _products = [aDecoder decodeObjectForKey:@"products"];
    _logoUrl = [aDecoder decodeObjectForKey:@"logoUrl"];
    _brandLogoUrl = [aDecoder decodeObjectForKey:@"brandLogoUrl"];
    _fixedAmount =[aDecoder decodeObjectForKey:@"fixedAmount"];
    _percentageAmount = [aDecoder decodeObjectForKey:@"percentageAmount"];
    _gift = [aDecoder decodeObjectForKey:@"gift"];
    _giftProducts = [aDecoder decodeObjectForKey:@"giftProducts"];
    _actualUses = [aDecoder decodeObjectForKey:@"actualUses"];
    _limitUses = [aDecoder decodeObjectForKey:@"limitUses"];
    _status = [aDecoder decodeObjectForKey:@"status"];
    _startDate = [aDecoder decodeObjectForKey:@"startDate"];
    _endDate = [aDecoder decodeObjectForKey:@"endDate"];
    _created = [aDecoder decodeObjectForKey:@"created"];
    _user = [aDecoder decodeObjectForKey:@"user"];
    _timeRanges = [aDecoder decodeObjectForKey:@"timeRanges"];
    _web = [aDecoder decodeObjectForKey:@"web"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_identifier forKey:@"identifier"];
    [aCoder encodeObject:_title forKey:@"title"];
    [aCoder encodeObject:_company forKey:@"company"];
    [aCoder encodeObject:_longDescription forKey:@"longDescription"];
    [aCoder encodeObject:_shortDescription forKey:@"shortDescription"];
    [aCoder encodeObject:_type forKey:@"type"];
    [aCoder encodeObject:_products forKey:@"products"];
    [aCoder encodeObject:_logoUrl forKey:@"logoUrl"];
    [aCoder encodeObject:_brandLogoUrl forKey:@"brandLogoUrl"];
    [aCoder encodeObject:_fixedAmount forKey:@"fixedAmount"];
    [aCoder encodeObject:_percentageAmount forKey:@"percentageAmount"];
    [aCoder encodeObject:_gift forKey:@"gift"];
    [aCoder encodeObject:_giftProducts forKey:@"giftProducts"];
    [aCoder encodeObject:_actualUses forKey:@"actualUses"];
    [aCoder encodeObject:_limitUses forKey:@"limitUses"];
    [aCoder encodeObject:_validDays forKey:@"validDays"];
    [aCoder encodeObject:_status forKey:@"status"];
    [aCoder encodeObject:_startDate forKey:@"startDate"];
    [aCoder encodeObject:_endDate forKey:@"endDate"];
    [aCoder encodeObject:_created forKey:@"created"];
    [aCoder encodeObject:_user forKey:@"user"];
    [aCoder encodeObject:_timeRanges forKey:@"timeRanges"];
    [aCoder encodeObject:_web forKey:@"web"];

}


-(NSString *) description{
    return [NSString stringWithFormat:@"Id: %@, Company:%@, title: %@, longDescription: %@ , shortDescription:%@,actualUses:%@, limitUses:%@, gift:%@, logoUrl:%@, brandLogoUrl:%@, startDate:%@, endDate:%@ products: %@ , gift_products: %@ ,type:%@ ,fixedAmount: %@, percentageAmount: %@, validDays: %@, status: %@, user: %@, created: %@, timeRanges: %@, web: %@",_identifier,_company,_title,_longDescription,_shortDescription,_actualUses, _limitUses, _gift,_logoUrl,_brandLogoUrl,_startDate,_endDate,_products,_giftProducts,_type,_fixedAmount,_percentageAmount,_validDays, _status, _user, _created, _timeRanges, _web];


}
    @end



@implementation PNPLoyalty

-(id) initWithIdentifier:(NSNumber *)identifier
                  userId:(NSNumber *)userId
                   title:(NSString *)title
             description:(NSString *)description
        shortDescription:(NSString *)shortDescription
                 logoUrl:(NSString *)logoUrl
                  status:(NSString *)status
               startDate:(NSDate *)startDate
                 endDate:(NSDate *)endDate
                  amount:(NSNumber *)amount
                  points:(NSNumber *)points
       suscriptionFields:(NSArray *)suscriptionFields
      exchangableCoupons:(NSArray *)exchangableCoupons
               commerces:(NSArray *)commerces
            company:(PNPLoyaltyCompany *)company
                benefits:(NSArray *)benefits
              registered:(BOOL)registered{
    
    self = [super init];
    if (!self) return nil;
    _identifier = identifier;
    _userId = userId;
    _title = title;
    _descr = description;
    _shortDescription = shortDescription;
    _logoUrl = logoUrl;
    _status = status;
    _startDate = startDate;
    _endDate = endDate;
    _amount = amount;
    _points = points;
    _suscriptionFields = suscriptionFields;
    _exchangableCoupons = exchangableCoupons;
    _commerces = commerces;
    _company = company;
    _benefits = benefits;
    _registered = registered;
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if (!self) return nil;
    _identifier = [aDecoder decodeObjectForKey:@"identifier"];
    _userId = [aDecoder decodeObjectForKey:@"userId"];
    _title = [aDecoder decodeObjectForKey:@"title"];
    _descr = [aDecoder decodeObjectForKey:@"description"];
    _shortDescription = [aDecoder decodeObjectForKey:@"shortDescription"];
    _logoUrl = [aDecoder decodeObjectForKey:@"logoUrl"];
    _status = [aDecoder decodeObjectForKey:@"status"];
    _startDate = [aDecoder decodeObjectForKey:@"startDate"];
    _endDate = [aDecoder decodeObjectForKey:@"endDate"];
    _amount = [aDecoder decodeObjectForKey:@"amount"];
    _points = [aDecoder decodeObjectForKey:@"points"];
    _suscriptionFields = [aDecoder decodeObjectForKey:@"suscriptionFields"];
    _exchangableCoupons = [aDecoder decodeObjectForKey:@"exchangableCoupons"];
    _commerces = [aDecoder decodeObjectForKey:@"commerces"];
    _company = [aDecoder decodeObjectForKey:@"company"];
    _benefits = [aDecoder decodeObjectForKey:@"benefits"];
    _registered = [aDecoder decodeBoolForKey:@"registered"];
    return self;
}

-(BOOL) isEqual:(id)object{
    return [self.identifier intValue] == [((PNPLoyalty *)object).identifier intValue];
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_identifier forKey:@"identifier"];
    [aCoder encodeObject:_userId forKey:@"userId"];
    [aCoder encodeObject:_title forKey:@"title"];
    [aCoder encodeObject:_descr forKey:@"description"];
    [aCoder encodeObject:_shortDescription forKey:@"shortDescription"];
    [aCoder encodeObject:_logoUrl forKey:@"logoUrl"];
    [aCoder encodeObject:_status forKey:@"status"];
    [aCoder encodeObject:_startDate forKey:@"startDate"];
    [aCoder encodeObject:_endDate forKey:@"endDate"];
    [aCoder encodeObject:_amount forKey:@"amount"];
    [aCoder encodeObject:_points forKey:@"points"];
    [aCoder encodeObject:_suscriptionFields forKey:@"suscriptionFields"];
    [aCoder encodeObject:_exchangableCoupons forKey:@"exchangableCoupons"];
    [aCoder encodeObject:_commerces forKey:@"commerces"];
    [aCoder encodeObject:_company forKey:@"company"];
    [aCoder encodeObject:_benefits forKey:@"benefits"];
    [aCoder encodeBool:_registered forKey:@"registered"];
}

@end

@implementation PNPPromotionStatistic

-(id) initWithExchanges:(NSDictionary *) exchanges notificationsOpened:(NSNumber *) notificationsOpened notificationsSended:(NSNumber *) notificationsSended {
    self = [super init];
    if(!self) return nil;
    _exchanges = exchanges;
    _notificationsOpened = notificationsOpened;
    _notificationsSended = notificationsSended;
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(!self) return nil;
    _exchanges = [aDecoder decodeObjectForKey:@"exchanges"];
    _notificationsOpened = [aDecoder decodeObjectForKey:@"notificationsOpened"];
    _notificationsSended = [aDecoder decodeObjectForKey:@"notificationsSended"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_exchanges forKey:@"exchanges"];
    [aCoder encodeObject:_notificationsOpened forKey:@"notificationsOpened"];
    [aCoder encodeObject:_notificationsSended forKey:@"notificationsSended"];
}


@end




@implementation PNPLoyaltySuscriptionField

-(id) initWithName:(NSString *) name attribute:(NSString *) attribute order:(int) order{
    self = [super init];
    if(!self) return nil;
    _name = name;
    _attribute = attribute;
    _order = order;
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(!self) return nil;
    _name = [aDecoder decodeObjectForKey:@"name"];
    _order = [aDecoder decodeIntForKey:@"order"];
    _attribute = [aDecoder decodeObjectForKey:@"attribute"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeInt:_order forKey:@"order"];
    [aCoder encodeObject:_attribute forKey:@"attribute"];
}

@end

@implementation PNPLoyaltySuscriptionFieldText
@end

@implementation PNPLoyaltySuscriptionFieldSelect

-(id) initWithName:(NSString *)name
         attribute:(NSString *)attribute
        options:(NSArray *)options
andOptionValues:(NSArray *)optionValues
             order:(int) order{
    self = [super init];
    if(!self) return nil;
    self.name = name;
    self.attribute = attribute;
    self.options = options;
    self.optionValues = optionValues;
    self.order = order;
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(!self) return nil;
    self.name = [aDecoder decodeObjectForKey:@"name"];
    self.attribute = [aDecoder decodeObjectForKey:@"attribute"];
    self.options = [aDecoder decodeObjectForKey:@"options"];
    self.order = [aDecoder decodeIntForKey:@"order"];
    self.optionValues = [aDecoder decodeObjectForKey:@"optionValues"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.attribute forKey:@"attribute"];
    [aCoder encodeObject:self.options forKey:@"options"];
    [aCoder encodeInt:self.order forKey:@"order"];
    [aCoder encodeObject:self.optionValues forKey:@"optionValues"];
}

@end

@implementation PNPLoyaltyExchanges

-(id) initWithIdentifier:(NSNumber *)identifier
       loyaltyIdentifier:(NSNumber *)loyaltyIdentifier
                  points:(NSNumber *)points
             fixedAmount:(NSNumber *)fixedAmount
        percentageAmount:(NSNumber *)percentageAmount
                gift:(NSString *)gift{
    self = [super init];
    if(!self) return nil;
    _identifier = identifier;
    _loyaltyIdentifier = loyaltyIdentifier;
    _points = points;
    _fixedAmount = fixedAmount;
    _percentageAmount = percentageAmount;
    _gift = gift;
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(!self) return nil;
    _identifier = [aDecoder decodeObjectForKey:@"identifier"];
    _loyaltyIdentifier = [aDecoder decodeObjectForKey:@"loyaltyIdentifier"];
    _points = [aDecoder decodeObjectForKey:@"points"];
    _fixedAmount = [aDecoder decodeObjectForKey:@"fixedAmount"];
    _percentageAmount = [aDecoder decodeObjectForKey:@"percentageAmount"];
    _gift = [aDecoder decodeObjectForKey:@"gift"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_identifier forKey:@"identifier"];
    [aCoder encodeObject:_loyaltyIdentifier forKey:@"loyaltyIdentifier"];
    [aCoder encodeObject:_points forKey:@"points"];
    [aCoder encodeObject:_fixedAmount forKey:@"fixedAmount"];
    [aCoder encodeObject:_percentageAmount forKey:@"percentageAmount"];
    [aCoder encodeObject:_gift forKey:@"gift"];
}

@end

@implementation PNPLoyaltyCommerce

-(id) initWithIdentifier:(NSNumber *)identifier name:(NSString *)name{
    self = [super init];
    if(!self) return nil;
    _identifier = identifier;
    _name = name;
    return self;
}
-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(!self) return nil;
    _identifier = [aDecoder decodeObjectForKey:@"identifier"];
    _name = [aDecoder decodeObjectForKey:@"name"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_identifier forKey:@"identifier"];
    [aCoder encodeObject:_name forKey:@"name"];
}

@end

@implementation PNPLoyaltyCompany

-(id) initWithName:(NSString *)name{
    self = [super init];
    if(!self) return nil;
    _name = name;
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(!self) return nil;
    _name = [aDecoder decodeObjectForKey:@"name"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_name forKey:@"name"];
}

@end

@implementation PNPLoyaltyBenefits

-(id) initWithIdentifier:(NSNumber *)identifier
        percentageAmount:(NSNumber *)percentageAmount
               startDate:(NSDate *)startDate
                 endDate:(NSDate *)endDate{
    self = [super init];
    if(!self) return nil;
    
    _identifier = identifier;
    _percentageAmount = percentageAmount;
    _startDate = startDate;
    _endDate = endDate;
    
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(!self) return nil;
    _identifier = [aDecoder decodeObjectForKey:@"identifier"];
    _percentageAmount = [aDecoder decodeObjectForKey:@"percentageAmount"];
    _startDate = [aDecoder decodeObjectForKey:@"startDate"];
    _endDate = [aDecoder decodeObjectForKey:@"endDate"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_identifier forKey:@"identifier"];
    [aCoder encodeObject:_percentageAmount forKey:@"percentageAmount"];
    [aCoder encodeObject:_startDate forKey:@"startDate"];
    [aCoder encodeObject:_endDate forKey:@"endDate"];
}



@end

@implementation PNPLoyaltyUserData

-(id) initWithLoyaltyId:(NSNumber *) identifier
           actualPoints:(NSNumber *) actualPoints
             lastPoints:(NSNumber *) lastPoints
                   code:(NSString *) code{
    self = [super init];
    if(!self) return nil;
    _loyaltyId = identifier;
    _actualPoints = actualPoints;
    _lastPoints = lastPoints;
    _code = code;
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(!self) return nil;
    _loyaltyId = [aDecoder decodeObjectForKey:@"loyaltyId"];
    _actualPoints = [aDecoder decodeObjectForKey:@"actualPoints"];
    _lastPoints = [aDecoder decodeObjectForKey:@"lastPoints"];
    _code = [aDecoder decodeObjectForKey:@"code"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_loyaltyId forKey:@"loyaltyId"];
    [aCoder encodeObject:_actualPoints forKey:@"actualPoints"];
    [aCoder encodeObject:_lastPoints forKey:@"lastPoints"];
    [aCoder encodeObject:_code forKey:@"code"];
}
@end

@implementation PNPCCategory

-(id) initWithIdentifier:(NSNumber *)identifier name:(NSString *)name imgUrl:(NSString *)url products:(NSArray *)products{
    self = [super init];
    if(!self) return nil;
    _identifier = identifier;
    _name = name;
    _imgUrl = url;
    _products = products;
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_identifier forKey:@"identifier"];
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_imgUrl forKey:@"imgUrl"];
    [aCoder encodeObject:_products forKey:@"products"];
}
-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(!self) return nil;
    _identifier = [aDecoder decodeObjectForKey:@"identifier"];
    _name = [aDecoder decodeObjectForKey:@"name"];
    _imgUrl = [aDecoder decodeObjectForKey:@"imgUrl"];
    _products = [aDecoder decodeObjectForKey:@"products"];
    return self;
}

-(NSString *) description{
    return [NSString stringWithFormat:@"ID: %@ NAME: %@ IMGURL: %@ PRODUCTS: %@ \n",_identifier,_name,_imgUrl,_products];
}

@end

@implementation PNPCProduct

-(id) initWithIdentifier:(NSNumber *)identifier
                    name:(NSString *)name
                  imgUrl:(NSString *)imgUrl
                variants:(NSArray *)variants{
    self = [super init];
    if(!self) return nil;
    _identifier = identifier;
    _name = name;
    _imgUrl = imgUrl;
    _variants = variants;
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_identifier forKey:@"identifier"];
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_imgUrl forKey:@"imgUrl"];
    [aCoder encodeObject:_variants forKey:@"variants"];
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(!self) return nil;
    _identifier = [aDecoder decodeObjectForKey:@"identifier"];
    _name = [aDecoder decodeObjectForKey:@"name"];
    _imgUrl = [aDecoder decodeObjectForKey:@"imgUrl"];
    _variants = [aDecoder decodeObjectForKey:@"variants"];
    return self;
}

-(NSString *) description{
    return [NSString stringWithFormat:@"ID: %@  NAME: %@ IMGURL: %@ VARIANTS: %@ \n",_identifier,_name,_imgUrl,_variants];
}

@end

@implementation PNPCVariant

-(id) initWithName:(NSString *) name
             price:(NSNumber *) price
        identifier:(NSNumber *) identifier{
    self = [super init];
    if(!self) return nil;
    _name = name;
    _price = price;
    _identifer = identifier;
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_price forKey:@"price"];
    [aCoder encodeObject:_identifer forKey:@"identifier"];
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(!self) return nil;
    _name = [aDecoder decodeObjectForKey:@"name"];
    _price = [aDecoder decodeObjectForKey:@"price"];
    _identifer = [aDecoder decodeObjectForKey:@"identifier"];
    return self;
}
-(NSString *) description{
    return [NSString stringWithFormat:@"NAME: %@ PRICE: %@ IDENTIFIER %@\n",_name,_price,_identifer];
}
@end

@implementation PNPPromo

-(id) initWithUserCount:(NSNumber *) userCound maxUserCount:(NSNumber *) maxUserCount active:(BOOL) active amount:(NSNumber *)amount minAmount:(NSNumber *)minAMount identifier:(NSNumber *) identifier{
    
    self = [super init];
    if(!self) return nil;
    
    _active = active;
    _userCount = userCound;
    _maxUserCount = maxUserCount;
    _amount = amount;
    _minAmount = minAMount;
    _identifier = identifier;
    
    return self;
}

-(NSString *) description{
    return [NSString stringWithFormat:@"UserCount: %@ MaxUserCount: %@ Amount: %@ MinAmount: %@ Identifier: %@",_userCount,_maxUserCount,_amount,_minAmount,_identifier];
}

@end


