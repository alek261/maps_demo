//
//  PlaceController.m
//  maps_demo
//
//  Created by Alek Spitzer on 28.05.16.
//

#import "PlaceController.h"
#import "RestKitManager.h"
#import "Settings.h"
#import "PlaceMapping.h"
#import "Place.h"
#import <MagicalRecord/MagicalRecord.h>

@interface PlaceController ()

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation PlaceController

- (id)init{
    
    self = [super init];
    
    if(self){
        
        self.context = [[RestKitManager sharedInstance] objectManager].managedObjectStore.mainQueueManagedObjectContext;
    }
    
    return self;
}

+ (PlaceController*)sharedInstance{
    
    static PlaceController *instance = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        instance = [[PlaceController alloc] init];
        
    });
    
    return instance;
}

-(void)fetchPlacesWithName:(NSString*)name{

    NSString *urlPath = [NSString stringWithFormat:@"maps/api/geocode/json?address=%@", name]; // as the google geocoding API doesn't support POST, the params are added to the URL
    
    RKObjectManager *objectManager = [[RestKitManager sharedInstance] objectManager];   // the task is going to run on a background thread as the objectManager makes use of NSOperationQeue,
                                                                                        // which means during the mapping process the main thread is not going to be blocked -> the UI stays responsive
    [objectManager postObject:nil
                         path:urlPath
                   parameters:nil
                      success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult){
                          
                          if(mappingResult != nil){
                              
                              NSArray *mappingResultArray = [mappingResult array];
                              NSMutableArray *places = [[NSMutableArray alloc] initWithCapacity:0];
                              
                              [mappingResultArray enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop){
                                  
                                  if (object != nil){
                                      
                                      if ([object isKindOfClass:[PlaceMapping class]]) {
                                          [places addObject:object];
                                      }
                                  }
                              }];
                              
                              
                              NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
                              NSArray *sortedResults = [places sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]]; // order the places by the order reference from the API
                              
                              self.places = sortedResults;
                              
                              BOOL foundResults = false;
                              if (self.places.count > 0) {
                                  foundResults = true;
                              }
                              
                              
                              [[NSNotificationCenter defaultCenter] postNotificationName:@"didFetchPlacesNotification" object:[NSNumber numberWithBool:foundResults]];
                          }
                      }
                      failure:^(RKObjectRequestOperation *operation, NSError *error){
                          NSLog(@"%@", error.description);
                      }];

}

#pragma mark Helper methods

-(BOOL)objectExistsWithIdentificationAttribute:(NSString*)identificationAttribute value:(NSString*)value{
    
    BOOL objectExists = NO;
    if ([Place MR_findFirstByAttribute:identificationAttribute
                             withValue:value]) {
        objectExists = true;
    }
    
    
    return objectExists;
    
}

- (void)createPlaceWithAttributesDictionary:(NSDictionary *)attributesDictionary{
    
    Place *newPlace = [Place MR_createEntity];
    
    [attributesDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [newPlace setValue:obj forKey:key];
    }];
}

-(void)deletePlaceWithID:(NSString*)placeID completion:(void (^)(BOOL success))deletedBlock{

    
    Place *placeToDelete = [Place MR_findFirstByAttribute:@"place_id"
                                                withValue:placeID];
    
    if (placeToDelete) {
        [placeToDelete MR_deleteEntity];
    }
    
    __block BOOL objectDeleted = false;
    // save changes in context
    [self saveDataInManagedContextUsingBlock:^(BOOL saved, NSError *error) {
        if (saved) {
            if (placeToDelete.managedObjectContext == nil) { // check if object was deleted
                objectDeleted = true;
            }
        }
    }];
    
    
    deletedBlock(objectDeleted);

}

-(void)saveDataInManagedContextUsingBlock:(void (^)(BOOL saved, NSError *error))savedBlock{
    
    NSError *saveError;
    savedBlock([self.context saveToPersistentStore:&saveError], saveError);
}

@end
