//
//  Cart.m
//  GlassPayCommerce
//
//  Created by Christian Bongardt on 26/03/14.
//  Copyright (c) 2014 Christian Bongardt. All rights reserved.
//

#import "Cart.h"
#import "CartItem.h"
#import "Discount.h"

@interface Cart()

@property (strong, nonatomic) Discount *discount;

@end


@implementation Cart


+ (instancetype)sharedInstance{
    static id sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

-(id)init {
    self = super.self;
    if (self == nil) {
        return nil;
    }
    _cartItems = [NSMutableArray new];
    _coupons = [NSMutableArray new];
    _couponGifts = [NSMutableArray new];
    _discount = nil;
    return self;
}

-(void) reset{
    _cartItems = [NSMutableArray new];
    _couponGifts = [NSMutableArray new];
    _coupons = [NSMutableArray new];
    _discount = nil;
}


-(void)setDiscount:(Discount*)discount {
    _discount = discount;
}

-(Discount*)getDiscount {
    if(_discount == nil){
        return nil;
    }
   
    _discount = [[Discount alloc] initWithBasePrice:[self getPriceWithoutGlobalDiscount] discount:[_discount getDiscountPercentage] coupon:_discount.coupon];
    
    return _discount;
}
-(void)removeDiscount{
    if(_discount.comesFromCoupon){
        [_coupons removeObject:_discount.coupon];
    }
    _discount = nil;
}




-(NSNumber *) getPrice{

    NSNumber *price =@0;
    
    for ( CartItem *item in _cartItems) {
        price = [NSNumber numberWithDouble:[[item getPrice] doubleValue] + [price doubleValue]];
    }
    
    if (_discount != nil) {
        price = [NSNumber numberWithDouble:[price doubleValue] - [[[self getDiscount] getPrice] doubleValue]] ;
    }
    return price;
}

-(NSNumber*)getPriceWithoutGlobalDiscount {
    
    NSNumber *price =@0;
    
    for ( CartItem *item in _cartItems) {
        price = [NSNumber numberWithDouble:[[item getPrice] doubleValue] + [price doubleValue]];
    }
    
    return price;
}
@end
