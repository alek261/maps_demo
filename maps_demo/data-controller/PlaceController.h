//
//  PlaceController.h
//  maps_demo
//
//  Created by Alek Spitzer on 28.05.16.
//

#import <Foundation/Foundation.h>
#import "NSManagedObjectContext+RKAdditions.h"

@interface PlaceController : NSObject

@property (nonatomic, copy) NSArray *places;

+ (PlaceController*)sharedInstance;


-(void)fetchPlacesWithName:(NSString*)name;

-(BOOL)objectExistsWithIdentificationAttribute:(NSString*)identificationAttribute value:(NSString*)value;

- (void)createPlaceWithAttributesDictionary:(NSDictionary *)attributesDictionary;

-(void)saveDataInManagedContextUsingBlock:(void (^)(BOOL saved, NSError *error))savedBlock;

-(void)deletePlaceWithID:(NSString*)placeID completion:(void (^)(BOOL success))deletedBlock;

@end
