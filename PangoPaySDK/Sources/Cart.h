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

@interface Cart : NSObject <Price>
+ (instancetype)sharedInstance;

@property (strong, nonatomic) NSMutableArray *cartItems;
@property (strong,nonatomic) NSMutableArray *coupons;

@property (strong,nonatomic) NSMutableArray *couponGifts;

@property (strong, nonatomic) PNPCommerceOrder *order;

@property (strong,nonatomic) NSNumber *fidelityDiscount;
@property (strong,nonatomic) NSString *fidelityIdentifier;

-(void)setDiscount:(Discount*)discount;
-(Discount*)getDiscount;
-(void)removeDiscount;
-(NSNumber*)getPriceWithoutGlobalDiscount;
-(void) reset;

@end
