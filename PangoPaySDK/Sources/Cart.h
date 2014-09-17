//
//  Cart.h
//  GlassPayCommerce
//
//  Created by Christian Bongardt on 26/03/14.
//  Copyright (c) 2014 Christian Bongardt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Price.h"

@class PNPCommerceOrder;

@class Discount;

@interface Cart : NSObject <Price,NSCoding>

@property (strong, nonatomic) NSMutableArray *cartItems;
@property (strong,nonatomic) NSMutableArray *coupons;
@property (strong, nonatomic) PNPCommerceOrder *order;

-(void)setDiscount:(Discount*)discount;
-(Discount*)getDiscount;
-(void)removeDiscount;
-(NSNumber*)getPriceWithoutGlobalDiscount;


@end
