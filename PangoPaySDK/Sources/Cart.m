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


-(id)init {
    self = super.self;
    if (self == nil) {
        return nil;
    }
    _cartItems = [NSMutableArray new];
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = super.self;
    if (self == nil) {
        return nil;
    }
    _cartItems = [aDecoder decodeObjectForKey:@"cartitems"];
    _discount =[aDecoder decodeObjectForKey:@"discount"];
    _order =[aDecoder decodeObjectForKey:@"order"];
    return self;
}

-(void)setDiscount:(Discount*)discount {
    _discount = discount;
}
-(Discount*)getDiscount {
    return _discount;
}
-(void)removeDiscount{
    _discount = nil;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_cartItems forKey:@"cartitems"];
    [aCoder encodeObject:_discount forKey:@"discount"];
    [aCoder encodeObject:_order forKey:@"order"];
}



-(NSNumber *) getPrice{

    NSNumber *price =@0;
    
    for ( CartItem *item in _cartItems) {
        price = [NSNumber numberWithDouble:[[item getPrice] doubleValue] + [price doubleValue]];
    }
    
    if (_discount != nil) {
        price = [NSNumber numberWithDouble:[price doubleValue] - [[_discount getPrice] doubleValue]] ;
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
