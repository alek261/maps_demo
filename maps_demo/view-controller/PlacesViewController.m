//
//  PlacesViewController.m
//  maps_demo
//
//  Created by Alek Spitzer on 27.05.16.
//

#import "PlacesViewController.h"
#import "PlaceController.h"
#import "NSString+URL_ENCODED.h"
#import "PlaceMapping.h"
#import "MapViewController.h"

@interface PlacesViewController () <UIGestureRecognizerDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, assign) CGRect screenFrame;
@property (nonatomic, assign) CGFloat statusBarHeight;
@property (nonatomic, assign) CGFloat navigationBarHeight;
@property (nonatomic, assign) int numberOfSections;

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, copy)   NSArray *places;
@property (nonatomic, copy)   NSArray *selectedPlaces;
@property (nonatomic, strong) NSMutableArray *sections;
@property (nonatomic, strong) NSMutableDictionary *cellsToSections;

@property (nonatomic, strong) UIView *noResultsView;

@end


@implementation PlacesViewController

#pragma mark NSNotification

-(void)didFetchPlaces:(NSNotification*)notification{

    [self.searchBar resignFirstResponder];
    
    NSNumber *success = notification.object;
    
    if ([success boolValue]) {
        
        [self removeNoResultsView];
        
        self.places = [[PlaceController sharedInstance] places];
        
        if (self.places.count > 1) {
            
            // "Display all on Map row shown"
            self.sections = [[NSMutableArray alloc] initWithObjects:@"A", @"B", nil];
            self.cellsToSections = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                    [[NSMutableArray alloc] initWithObjects:
                                     @"Display all on row", nil], @"A", [[NSMutableArray alloc] initWithArray:self.places], @"B", nil];
        }
        
        else{
            
            self.sections = [[NSMutableArray alloc] initWithObjects:@"A",nil];
            self.cellsToSections = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                    self.places, @"A", nil];
        }
        
        [self.tableView reloadData];
    }
    
    else{
        
        [self showNoResultsView];
    }
    
}


#pragma mark Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenFrame = [[UIScreen mainScreen] bounds];
    self.statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    self.navigationBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    
    [self setupSearchBar];
    [self setupTableView];
    [self setupNoResultsView];
    
    
}

-(void)setupNoResultsView{
    
    self.noResultsView = [[UIView alloc] initWithFrame:CGRectMake(0, self.searchBar.frame.origin.y + self.searchBar.frame.size.height, self.screenFrame.size.width, self.screenFrame.size.height - self.searchBar.frame.size.height - self.statusBarHeight)];
    [self.noResultsView setBackgroundColor:[UIColor whiteColor]];
    
    UILabel *noResultsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [noResultsLabel setFont:[UIFont boldSystemFontOfSize:25.0]];
    [noResultsLabel setText:@"No Results"];
    [noResultsLabel sizeToFit];
    [noResultsLabel setCenter:CGPointMake(self.noResultsView.frame.size.width/2, self.noResultsView.frame.size.height/2)];
    
    [self.noResultsView addSubview:noResultsLabel];

}

-(void)showNoResultsView{
    
    // check if noResultsView was added in order to prevent re-adding it
    if ([self.noResultsView superview] == nil) {
        [self.view addSubview:self.noResultsView];
    }
}

-(void)removeNoResultsView{
    
    [self.noResultsView removeFromSuperview];

}

-(void)setupSearchBar{
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, self.statusBarHeight, self.screenFrame.size.width, 50)];
    [self.searchBar setDelegate:self];
    [self.view addSubview:self.searchBar];
    
}


-(void)dismissKeyboard:(id)sender{
    
    [self.searchBar resignFirstResponder];
}

-(void)setupTableView{

    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.searchBar.frame.origin.y + self.searchBar.frame.size.height, self.screenFrame.size.width, self.screenFrame.size.height - self.statusBarHeight - self.searchBar.frame.size.height)];
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    [self.view addSubview:self.tableView];
    
}

#pragma mark UISearchBar Delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    
    [[PlaceController sharedInstance] fetchPlacesWithName:[searchBar.text urlencode]]; // a category is used in order to url encode the search location as we add it to the URL
}


#pragma mark - UITableView Delegate

// UITableView contains a UIScrollView
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    
    [self.searchBar resignFirstResponder];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    if (section == 0) { // "Display all on row" section won't be shown
        return 0;
    }
    
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 50;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return self.cellsToSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return [self getSectionCells:section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
   static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    
    NSString *title = [self getTitle:indexPath];
    
    cell.textLabel.text = title;
    
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString *title = [self getTitle:indexPath];
    
    if ([title isEqualToString:@"Display all on row"]){
        self.selectedPlaces = self.places;
    }
    
    else{
        PlaceMapping *selectedPlace = [self.places objectAtIndex:indexPath.row];
        self.selectedPlaces = [NSArray arrayWithObject:selectedPlace];
    }
    
    
    [self performSegueWithIdentifier:@"showMap" sender:self];
}

#pragma mark - Helper method

- (NSArray *)getSectionCells:(NSUInteger)sectionIndex{
    
    NSString *sectionName = [self.sections objectAtIndex:sectionIndex];
    NSArray *cells = [self.cellsToSections objectForKey:sectionName];
    
    return cells;
}

- (NSString *)getTitle:(NSIndexPath *)indexPath{
    
    NSString *title;
    
    // object introspection in order to take the cell title from a string object (Display all in row) or a Place object
    id object = [[self getSectionCells:indexPath.section] objectAtIndex:indexPath.row];
    
    if ([object isKindOfClass:[PlaceMapping class]]) {
        title = [(PlaceMapping*)object name];
    }
    else if ([object isKindOfClass:[NSString class]]){
        title = object;
    }
    
    return title;
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showMap"]) {
        
        MapViewController *vc = [segue destinationViewController];
        [vc setPlaces:self.selectedPlaces];
    }
}


#pragma mark UIViewController

-(void)viewWillAppear:(BOOL)animated{

    for (NSIndexPath *indexPath in self.tableView.indexPathsForSelectedRows) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFetchPlaces:) name:@"didFetchPlacesNotification" object:nil];
    [self.navigationController setNavigationBarHidden:YES];

}

-(void)viewWillDisappear:(BOOL)animated{

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
