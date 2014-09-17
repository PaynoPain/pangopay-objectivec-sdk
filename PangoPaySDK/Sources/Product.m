//
//  Product.m
//  GlassPayCommerce
//
//  Created by Christian Bongardt on 26/03/14.
//  Copyright (c) 2014 Christian Bongardt. All rights reserved.
//

#import "Product.h"

@interface Product()

@property (strong, nonatomic) NSNumber *price;

@end

@implementation Product

-(id) initWithName:(NSString*) name
       description:(NSString*) description
             price:(NSNumber*) price {
    self = [super init];
    if (!self) { return nil; }
    
    self.name = name;
    self.price = price;
    self.descr = description;
    
    return self;
}
-(id) initWithName:(NSString*) name
       description:(NSString*) description
             price:(NSNumber*) price
             image:(NSString*) image
externalId:(NSNumber *)externalId
{
    self = [super init];
    if (!self) { return nil; }
    
    self.name = name;
    self.price = price;
    self.descr = description;
    self.imgURL = image;
    self.externalId = externalId;
    return self;
    
}

-(id) initWithName:(NSString*) name
        description:(NSString*) description
              price:(NSNumber*) price
             image:(NSString*) image
{
    self = [super init];
    if (!self) { return nil; }
    
    self.name = name;
    self.price = price;
    self.descr = description;
    self.imgURL = image;
    return self;

}
-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if (!self) { return nil; }
    
    self.name = [aDecoder decodeObjectForKey:@"name"];
    self.price =[aDecoder decodeObjectForKey:@"price"];
    self.descr = [aDecoder decodeObjectForKey:@"descr"];
    self.externalId = [aDecoder decodeObjectForKey:@"externalId"];
    
    return self;
}
-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_price forKey:@"price"];
    [aCoder encodeObject:_descr forKey:@"descr"];
    [aCoder encodeObject:_externalId forKey:@"externalId"];
}

-(NSString*)description {
    return [NSString stringWithFormat:@"name: %@ description:%@ price:%@", _name, _descr, _price];
}

-(NSNumber *) getPrice{
    return _price;
}


@end
