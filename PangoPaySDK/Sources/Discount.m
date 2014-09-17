//
//  Discount.m
//  GlassPayCommerce
//
//  Created by Christian Bongardt on 26/03/14.
//  Copyright (c) 2014 Christian Bongardt. All rights reserved.
//

#import "Discount.h"

@interface Discount()

@property (strong, nonatomic) NSNumber *basePrice;
@property (strong, nonatomic) NSNumber *discount;

@end


@implementation Discount

-(id)initWithBasePrice:(NSNumber*)price
              discount:(NSNumber*)discount
       comesFromCoupon:(BOOL) comesFromCoupon{
    self = [super init];
    if (self == nil) { return nil; }
    
    _basePrice = price;
    _discount = discount;
    _comesFromCoupon = comesFromCoupon;

    return self;
}
-(id)initWithBasePrice:(NSNumber*)price
              discount:(NSNumber*)discount{
    self = [super init];
    if (self == nil) { return nil; }
    
    _basePrice = price;
    _discount = discount;
    _comesFromCoupon = NO;
    
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if (self == nil) { return nil; }
    
    _basePrice = [aDecoder decodeObjectForKey:@"baseprice"];
    _discount = [aDecoder decodeObjectForKey:@"discount"];
    _comesFromCoupon = [aDecoder decodeBoolForKey:@"comesFromCoupon"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_basePrice forKey:@"baseprice"];
    [aCoder encodeObject:_discount forKey:@"discount"];
    [aCoder encodeBool:_comesFromCoupon forKey:@"comesFromCoupon"];
}

-(NSNumber*)getPrice {
    return [NSNumber numberWithDouble:[_discount doubleValue] * [_basePrice doubleValue] / 100];
}

-(NSString*)description{
    return [NSString stringWithFormat:@"price: %@ discount: %@ basePrice: %@", [self getPrice], _discount, _basePrice ];
}

-(void)updateBasePrice:(NSNumber*)price {
    _basePrice = price;
}
-(NSNumber *) getDiscountPercentage{
    return _discount;
}
@end
