//
//  CartItem.m
//  GlassPayCommerce
//
//  Created by Christian Bongardt on 26/03/14.
//  Copyright (c) 2014 Christian Bongardt. All rights reserved.
//

#import "CartItem.h"
#import "Product.h"
#import "Discount.h"

@interface CartItem()


@property (strong, nonatomic) Discount *discount;
@property (strong, nonatomic) NSNumber *quantity;
@end

@implementation CartItem


-(id)initWithProduct:(Product*)product {
    self = [super init];
    if (self == nil) { return nil; }
    _quantity = @1;
    _product = product;
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if (self == nil) { return nil; }
    _quantity = [aDecoder decodeObjectForKey:@"quantity"];
    _discount = [aDecoder decodeObjectForKey:@"discount"];
    _product = [aDecoder decodeObjectForKey:@"product"];
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_quantity forKey:@"quantity"];
    [aCoder encodeObject:_product forKey:@"product"];
    [aCoder encodeObject:_discount forKey:@"discount"];
}

-(void)setDiscount:(Discount*)discount {
    _discount = discount;
}

-(void)removeDiscount {
    _discount = nil;
}
-(Discount*)getDiscount{
    return _discount;
}
-(Product*)getProduct{
    return _product;
}

-(void)increaseQuantityByOne {
    _quantity = [NSNumber numberWithInt:[_quantity intValue]+1];
}
-(void)decreaseQuantityByOne {
    if ([_quantity intValue] == 1) {
        return;
    }
    _quantity = [NSNumber numberWithInt:[_quantity intValue]-1];
}

-(void)setQuantity:(NSNumber*)quantity {
    _quantity = quantity;
}
-(NSNumber*)getQuantity {
    return _quantity;
}

-(NSString*)description {
    return [NSString stringWithFormat:@"product: %@ \n discount: %@", _product, _discount ];
}


-(NSNumber *) getPrice{
    NSNumber *price;
    if (_discount != nil) {
        price = [NSNumber numberWithDouble:[[_product getPrice] doubleValue] - [[_discount getPrice] doubleValue]];
    }
    else {
        price = [_product getPrice];
    }
    
    price = [NSNumber numberWithDouble:[price doubleValue]*[_quantity doubleValue] ];
    return price;
}

@end
