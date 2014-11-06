//
//  Discount.h
//  GlassPayCommerce
//
//  Created by Christian Bongardt on 26/03/14.
//  Copyright (c) 2014 Christian Bongardt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Price.h"
#import "PNPDataContainer.h"
@interface Discount : NSObject <Price>

@property BOOL comesFromCoupon;
@property (strong,nonatomic) PNPCoupon *coupon;

-(id)initWithBasePrice:(NSNumber*)price
              discount:(NSNumber*)discount
       comesFromCoupon:(BOOL) comesFromCoupon;

-(id)initWithBasePrice:(NSNumber*)price
              discount:(NSNumber*)discount;

-(id)initWithBasePrice:(NSNumber*)price
              discount:(NSNumber*)discount
                coupon:(PNPCoupon *)coupon;

-(void)updateBasePrice:(NSNumber*)price;

-(NSNumber *) getDiscountPercentage;
@end
