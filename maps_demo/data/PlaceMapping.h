//
//  PlaceTest.h
//  maps_demo
//
//  Created by Alek Spitzer on 28.05.16.
//

#import <Foundation/Foundation.h>

@interface PlaceMapping : NSObject

@property (nonatomic, strong) NSString *place_id;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *latitude;
@property (nonatomic, strong) NSString *longitude;
@property (nonatomic, assign) int order;

@end
