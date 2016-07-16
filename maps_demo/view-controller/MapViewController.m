//
//  MapViewController.m
//  maps_demo
//
//  Created by Alek Spitzer on 29.05.16.
//

#import "MapViewController.h"
#import "PlaceMapping.h"
#import "GoogleMaps.h"
#import "PlaceController.h"


@interface MapViewController () <UIAlertViewDelegate>

@property (nonatomic, strong) GMSMapView *mapView;
@property (nonatomic, assign) BOOL savedInDB;
@property (nonatomic, strong) UIBarButtonItem *saveDeleteButton;

@end

@implementation MapViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
    [self setupNavigationBar];
    [self setupMapView];
   
    
}

-(void)setupNavigationBar{

    self.title = @"Map";
    
    if (self.places.count == 1) {
        
        self.savedInDB = [[PlaceController sharedInstance] objectExistsWithIdentificationAttribute:@"place_id" value:[[self.places firstObject] place_id]];
        
        self.saveDeleteButton = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%@", (self.savedInDB) ? @"Delete" : @"Save"]
                                                                             style:UIBarButtonItemStylePlain target:self action:@selector(saveDeleteButtonAction:)];
        self.navigationItem.rightBarButtonItem = self.saveDeleteButton;
    }
   
}

-(void)saveDeleteButtonAction:(id)sender{

    PlaceMapping *place = [self.places firstObject];
    
    if (!self.savedInDB) { // save place
        // create managed object of entity place
        [[PlaceController sharedInstance] createPlaceWithAttributesDictionary:[NSDictionary dictionaryWithObjectsAndKeys:place.place_id, @"place_id", place.name, @"name",place.latitude, @"latitude", place.longitude, @"longitude", nil]];
        
        [[PlaceController sharedInstance] saveDataInManagedContextUsingBlock:^(BOOL saved, NSError *error) {
            if (saved) {
                self.savedInDB = true;
                [self updateSaveDeleteButton];
            }
        }];
    }
    else{
        // delete action
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Are you sure you want to delete this place?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
        
        [alert show];
    }
}

-(void)updateSaveDeleteButton{

    [self.saveDeleteButton setTitle:[NSString stringWithFormat:@"%@", (self.savedInDB) ? @"Delete" : @"Save"]];

}

-(void)setupMapView{
    
    PlaceMapping *firstPlace = [self.places firstObject];
    int zoom = 15; // default zoom for one place
    if (self.places.count > 1) {
        zoom = 1; // as we have more than one place, zoom from outside to the inside in viewDidAppear()
    }
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:[firstPlace.latitude doubleValue]
                                                            longitude:[firstPlace.longitude doubleValue]
                                                                 zoom:zoom];
    
    self.mapView = [GMSMapView mapWithFrame:self.view.bounds camera:camera];
    [self.view addSubview:self.mapView];
    
}

#pragma mark UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{

    if (buttonIndex == 1) { // delete button touched
        PlaceMapping *place = [self.places firstObject];
        [[PlaceController sharedInstance] deletePlaceWithID:place.place_id completion:^(BOOL success) {
            if (success) {
                self.savedInDB = false;
                [self updateSaveDeleteButton];
            }
        }];
    }
}


#pragma mark UIViewController

-(void)viewWillAppear:(BOOL)animated{

    [self.navigationController setNavigationBarHidden:NO];
}

-(void)viewDidAppear:(BOOL)animated{ // animation after view has been loaded so the transition to the view happens faster
    
    
    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] init];
    
    for (PlaceMapping *place in self.places){
        
        // Creates a marker in the center of the map.
        GMSMarker *marker = [[GMSMarker alloc] init];
        marker.position = CLLocationCoordinate2DMake([place.latitude floatValue], [place.longitude floatValue]);
        bounds = [bounds includingCoordinate:marker.position];
        marker.title = place.name;
        marker.snippet = [NSString stringWithFormat:@"(%f, %f)", [place.latitude floatValue], [place.longitude floatValue]];
        marker.map = self.mapView;
    }
    
    
    if (self.places.count > 1) { // just animate for multiple places
        [self.mapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:bounds withPadding:30.0f]]; // show all the place markers on the screen
    }
}

@end
