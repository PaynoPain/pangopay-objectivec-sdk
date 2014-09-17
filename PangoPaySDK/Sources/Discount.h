//
//  Discount.h
//  GlassPayCommerce
//
//  Created by Christian Bongardt on 26/03/14.
//  Copyright (c) 2014 Christian Bongardt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Price.h"

@interface Discount : NSObject <Price,NSCoding>

@property BOOL comesFromCoupon;

-(id)initWithBasePrice:(NSNumber*)price
              discount:(NSNumber*)discount
       comesFromCoupon:(BOOL) comesFromCoupon;

-(id)initWithBasePrice:(NSNumber*)price
              discount:(NSNumber*)discount;



-(void)updateBasePrice:(NSNumber*)price;

-(NSNumber *) getDiscountPercentage;
@end
