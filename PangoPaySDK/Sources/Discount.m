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

-(id)initWithBasePrice:(NSNumber*)price
              discount:(NSNumber*)discount
                coupon:(PNPCoupon *)coupon{
    self = [super init];
    if (self == nil) { return nil; }
    _basePrice = price;
    _discount = discount;
    _coupon = coupon;
    _comesFromCoupon = YES;
    return self;
}

-(NSNumber*)getPrice {
    return [NSNumber numberWithDouble:[_discount doubleValue] * [_basePrice doubleValue] / 100];
}

-(NSString*)description{
    return [NSString stringWithFormat:@"price: %@ discount: %@ basePrice: %@ coupon: %@", [self getPrice], _discount, _basePrice,_coupon];
}

-(void)updateBasePrice:(NSNumber*)price {
    _basePrice = price;
}
-(NSNumber *) getDiscountPercentage{
    return _discount;
}
@end
