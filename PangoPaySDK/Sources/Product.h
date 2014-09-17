//
//  Product.h
//  GlassPayCommerce
//
//  Created by Christian Bongardt on 26/03/14.
//  Copyright (c) 2014 Christian Bongardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Price.h"

@interface Product:NSObject <Price,NSCoding>

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *descr;
@property (strong,nonatomic) NSNumber *externalId;
@property (strong, nonatomic) NSString *imgURL;

-(id) initWithName:(NSString*) name
       description:(NSString*) description
             price:(NSNumber*) price;


-(id) initWithName:(NSString*) name
       description:(NSString*) description
             price:(NSNumber*) price
             image:(NSString*) image;

-(id) initWithName:(NSString*) name
       description:(NSString*) description
             price:(NSNumber*) price
             image:(NSString*) image
        externalId:(NSNumber *) externalId;

@end
