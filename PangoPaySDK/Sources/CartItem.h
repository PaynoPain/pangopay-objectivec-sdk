//
//  CartItem.h
//  GlassPayCommerce
//
//  Created by Christian Bongardt on 26/03/14.
//  Copyright (c) 2014 Christian Bongardt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Price.h"
#import "PNPDataContainer.h"
@class Product;
@class Discount;

@interface CartItem : NSObject <Price,NSCoding>
@property (strong, nonatomic) Product *product;
@property (strong,nonatomic) PNPCoupon *coupon;
@property BOOL forceStampCount;
@property BOOL isStampcard;
-(id)initWithProduct:(Product*)product;
-(id)initWithProduct:(Product*)product createdFromCoupon:(PNPCoupon *) coupon;

-(void)setDiscount:(Discount*)discount;
-(void)removeDiscount;
-(Discount*)getDiscount;



-(Product*)getProduct;

-(void)increaseQuantityByOne;
-(void)decreaseQuantityByOne;

-(void)setQuantity:(NSNumber*)quantity;


-(NSNumber*)getQuantity;
@end
