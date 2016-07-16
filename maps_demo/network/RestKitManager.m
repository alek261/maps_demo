//
//  RestKitManager.m
//  maps_demo
//
//  Created by Alek Spitzer on 28.05.16.
//

#import "RestKitManager.h"
#import "Settings.h"
#import "RKLog.h"
#import "RKPathUtilities.h"
#import "RKResponseDescriptor.h"
#import "RKRelationshipMapping.h"
#import "Settings.h"
#import "RKMIMETypes.h"
#import "PlaceMapping.h"
#import "PlaceMapping.h"
#import <MagicalRecord/MagicalRecord.h>

// Use a class extension to expose access to MagicalRecord's private setter methods
@interface NSManagedObjectContext ()

+ (void)MR_setRootSavingContext:(NSManagedObjectContext *)context;
+ (void)MR_setDefaultContext:(NSManagedObjectContext *)moc;

@end

@implementation RestKitManager

- (id)init{
    
    self = [super init];
    
    if(self){
        
        _objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:BASE_API_URL]];
        [_objectManager setRequestSerializationMIMEType:RKMIMETypeFormURLEncoded];
    }
    
    return self;
}

+ (RestKitManager *)sharedInstance{
    
    static RestKitManager *instance = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        instance = [[RestKitManager alloc] init];
    });
    
    return instance;
}

- (void)initNetwork{
    
    // -- enable automatic network activity indicator management --
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    // -- init Core Data stack --
    // switched from using the Apple generated Core Data boilerplate over to using
    // a RestKit Core Data Manager called RKManagedObjectStore.
    // RKManagedObjectStore encapsulates all the functionality for setting up a
    // Core Data stack and provides you with a NSManagedObjectContext configuration
    // that is optimized for performance.
    
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] mutableCopy];
    self.managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
    
    NSError *error = nil;
    BOOL success = RKEnsureDirectoryExistsAtPath(RKApplicationDataDirectory(), &error);
    if(!success){
        
        RKLogError(@"Failed to create Application Data Directory at path '%@': %@", RKApplicationDataDirectory(), error);
    }
    
    [self setupObjectManager];
    [self createPersistentStore];
    [self setupMagicalRecord];
}

-(void)setupMagicalRecord{
    
    // Configure MagicalRecord to use RestKit's Core Data stack
    [NSPersistentStoreCoordinator MR_setDefaultStoreCoordinator:_objectManager.managedObjectStore.persistentStoreCoordinator];
    [NSManagedObjectContext MR_setRootSavingContext:_objectManager.managedObjectStore.persistentStoreManagedObjectContext];
    [NSManagedObjectContext MR_setDefaultContext:_objectManager.managedObjectStore.mainQueueManagedObjectContext];
    
}

-(void)createPersistentStore{
    
    // Create the persistent store coordinator
    [self.managedObjectStore createPersistentStoreCoordinator];
    
    
    // Create the persistent store
    NSError *error = nil;
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"maps_demo.sqlite"];
    NSString *seedPath = [[NSBundle mainBundle] pathForResource:@"RKSeedDatabase" ofType:@"sqlite"];
    NSPersistentStore *persistentStore = [self.managedObjectStore addSQLitePersistentStoreAtPath:storePath
                                                                          fromSeedDatabaseAtPath:seedPath
                                                                               withConfiguration:nil
                                                                                         options:nil
                                                                                           error:&error];
    if(!persistentStore)
    {
        RKLogError(@"Failed adding persistent store at storePath '%@': %@", storePath, error);
        RKLogError(@"Attempting to delete and recreate the store");
        if (error) {
            
            [[NSFileManager defaultManager] removeItemAtPath:storePath
                                                       error:nil];
            
            NSPersistentStore *persistentStore = [self.managedObjectStore addSQLitePersistentStoreAtPath:storePath
                                                                                  fromSeedDatabaseAtPath:seedPath
                                                                                       withConfiguration:nil
                                                                                                 options:nil
                                                                                                   error:&error];
            if(!persistentStore)
            {
                NSLog(@"Failed again crash and burn!");
            }
        }
    }
    
    // Create the context
    [self.managedObjectStore createManagedObjectContexts];
}


-(void)setupObjectManager{
    
    _objectManager.managedObjectStore = self.managedObjectStore;
    [self addObjectMappingsToObjectManager];
    
}


- (void)addObjectMappingsToObjectManager{
    

    // PLACE
    RKObjectMapping *placeMapping = [RKObjectMapping mappingForClass:[PlaceMapping class]];
    
    [placeMapping addAttributeMappingsFromDictionary:@{@"place_id" : @"place_id",
                                                       @"formatted_address" : @"name",
                                                       @"geometry.location.lat" : @"latitude",
                                                       @"geometry.location.lng" : @"longitude",
                                                       @"@metadata.mapping.collectionIndex": @"order"}]; // order reference from the API
    
    
    [_objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:placeMapping
                                                                                       method:RKRequestMethodAny
                                                                                  pathPattern:nil
                                                                                      keyPath:@"results"
                                                                                  statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];
    

}

@end
