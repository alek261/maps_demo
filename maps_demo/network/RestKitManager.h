//
//  RestKitManager.h
//  maps_demo
//
//  Created by Alek Spitzer on 28.05.16.
//

#import <Foundation/Foundation.h>
#import "RKManagedObjectStore.h"
#import "RKObjectManager.h"

@interface RestKitManager : NSObject

@property(nonatomic, strong) RKManagedObjectStore *managedObjectStore;
@property(nonatomic, strong) RKObjectManager *objectManager;
@property(nonatomic, strong) NSManagedObjectContext *context;

+(RestKitManager *)sharedInstance;
- (void)initNetwork;


@end
