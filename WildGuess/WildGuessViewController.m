//
//  WildGuessViewController.m
//  WildGuess
//
//  Created by HCKuo on 5/20/14.
//  Copyright (c) 2014 auszone. All rights reserved.
//
#import "WildGuessViewController.h"
#import "FXBlurView.h"
#define panoRadius 200 //KM
#define colorOcean [UIColor colorWithRed:(0 / 255.0f) green:( 64 / 255.0f) blue:(128 / 255.0f) alpha:0.8f]
@implementation WildGuessViewController {
    GMSMapView *mapView;
    GMSPanoramaView *panoView;
    GMSMarker *pickMarker;
    GMSMarker *targetMarker;
    GMSMutablePath *path;
    GMSPolyline *line;
    UILabel *resultLabel;
    UIButton *answerButton;
    CLLocationCoordinate2D panoCoordinate;
    FXBlurView *blurView;
    BOOL answered;
}
-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initPano];
    [self initMap];
    [self initMarker];
    [self initAnswerButton];
    [self initResultLabel];
    //[self.view addSubview:mapView];
    [self.view addSubview:panoView];
    
    blurView = [[FXBlurView alloc] initWithFrame:self.view.frame];
}

-(void)initMap
{
    CGRect mapRect = panoView.frame;
    mapRect.origin.y += 50;
    mapRect.size.height -= 100;
    mapRect.origin.x += 10;
    mapRect.size.width -= 20;
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-33.86
                                                        longitude:151.20
                                                                 zoom:0];
    mapView = [GMSMapView mapWithFrame:mapRect camera:camera];
    mapView.delegate = self;
    mapView.alpha = 0.85f;
}
-(void)initPano
{
    CGRect panoRect = CGRectMake(0.0, 60.0, self.view.frame.size.width, self.view.frame.size.height/1.25);
    panoView = [[GMSPanoramaView alloc] initWithFrame:panoRect];
    panoView.delegate = self;
    panoView.streetNamesHidden = YES;
    //[panoView setAllGesturesEnabled:NO];
    [self randomCoordinate];
    [panoView moveNearCoordinate:panoCoordinate radius:panoRadius*1000];
    //
}
-(void)initMarker
{
    pickMarker = [[GMSMarker alloc]init];
    pickMarker.map = mapView;
    targetMarker= [[GMSMarker alloc]init];
    targetMarker.map = nil;
}
-(void)initAnswerButton
{
    answerButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [answerButton addTarget:self
                     action:@selector(touchAnswerButton:)
           forControlEvents:UIControlEventTouchUpInside];
    [answerButton setTitle:@"Answer" forState:UIControlStateNormal];
    answerButton.backgroundColor = colorOcean;
    answerButton.frame = CGRectMake(80, mapView.frame.origin.y+mapView.frame.size.height, 160.0, 40.0);
    [answerButton.titleLabel setFont:[UIFont systemFontOfSize:28]];
    [answerButton.titleLabel setTextColor:[UIColor whiteColor]];

}
-(void)initResultLabel
{
    resultLabel = [[UILabel alloc]initWithFrame:CGRectMake(50, mapView.frame.origin.y-40, self.view.frame.size.width-100, 40)];
    resultLabel.textColor = [UIColor whiteColor];
    resultLabel.font = [UIFont fontWithName:@"Headline" size:15.0f];
    resultLabel.backgroundColor = colorOcean;
    resultLabel.textAlignment = UITextAlignmentCenter;
    
}
-(void)randomCoordinate
{
    panoCoordinate.latitude = [self getRandomNumberBetween:-85 to:85]+(double)[self getRandomNumberBetween:0 to:100000]/100000;
    panoCoordinate.longitude = [self getRandomNumberBetween:-180 to:180]+(double)[self getRandomNumberBetween:0 to:100000]/100000;
    NSLog(@"Random: %f %f", panoCoordinate.latitude, panoCoordinate.longitude);
}
#pragma mark - GMSMapViewDelegate
- (void)mapView:(GMSMapView *)mapView
didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    if (!answered) {
        pickMarker.position = coordinate;
    }
    
    //NSLog(@"You tapped at %f,%f", coordinate.latitude, coordinate.longitude);
}
#pragma mark - GMSPanoramaViewDelegate
-(void)panoramaView:(GMSPanoramaView *)view didMoveToPanorama:(GMSPanorama *)panorama nearCoordinate:(CLLocationCoordinate2D)coordinate
{
    if (!panoView.panorama.panoramaID) {
        //NSLog(@"retrying");
        [self randomCoordinate];
        [panoView moveNearCoordinate:panoCoordinate radius:panoRadius*1000];
    }else{
        //NSLog(@"found pano");
        //NSLog(panoView.panorama.panoramaID);
    }
}
-(void)panoramaView:(GMSPanoramaView *)view error:(NSError *)error onMoveNearCoordinate:(CLLocationCoordinate2D)coordinate
{
    [self randomCoordinate];
    [panoView moveNearCoordinate:panoCoordinate radius:panoRadius*1000];
}
#pragma mark - touchButtons
- (IBAction)touchRandomButton:(id)sender
{
    [self randomCoordinate];
    [panoView moveNearCoordinate:panoCoordinate radius:panoRadius*1000];
}
- (IBAction)touchEarthButton:(id)sender
{
    
    [self.view addSubview:blurView];
         blurView.blurRadius = 2;
    [blurView addSubview:mapView];
    UITapGestureRecognizer *tap =[[UITapGestureRecognizer alloc]
                                  initWithTarget:self
                                  action:@selector(tapDetected:)];
    tap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tap];
    [blurView addSubview:answerButton];
    answerButton.enabled = YES;
    [answerButton.titleLabel setTextColor:[UIColor whiteColor]];
}
-(IBAction)touchAnswerButton:(UIButton *)sender
{
    if (pickMarker.position.latitude+180 < 0.1 && pickMarker.position.longitude+180 < 0.1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"FYI" message:@"You have to pick a place first." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }else {
        resultLabel.text = [NSString stringWithFormat:@"%.2f KMs Away!", [self distanceBetweenOrderBy:pickMarker.position.latitude :panoCoordinate.latitude :pickMarker.position.longitude :panoCoordinate.longitude]];
        [blurView addSubview:resultLabel];
        answerButton.enabled = NO;
        answered = YES;
        targetMarker.map = mapView;
        targetMarker.position = panoView.panorama.coordinate;
        targetMarker.icon = [GMSMarker markerImageWithColor:[UIColor blueColor]];
        
        path = [GMSMutablePath path];
        [path addCoordinate:pickMarker.position];
        [path addCoordinate:targetMarker.position];
        line = [GMSPolyline polylineWithPath:path];
        line.map = mapView;
        line.strokeWidth = 2;
        line.strokeColor = colorOcean;
    }
    
}
- (IBAction)tapDetected:(UIGestureRecognizer *)sender {
    if (answered) {
        [self randomCoordinate];
        [panoView moveNearCoordinate:panoCoordinate radius:panoRadius*1000];
        targetMarker.map = nil;
        line.map = nil;

        path = nil;
        line = nil;
    }
    answered = NO;
    blurView.blurRadius = 0;
	[blurView removeFromSuperview];
    [mapView removeFromSuperview];
    [answerButton removeFromSuperview];
    [resultLabel removeFromSuperview];
}
#pragma mark - others
-(int)getRandomNumberBetween:(int)from to:(int)to {
    return (int)from + arc4random() % (to-from+1);
}
-(double)distanceBetweenOrderBy:(double)lat1 :(double)lat2 :(double)lng1 :(double)lng2{
    double dd = M_PI/180;
    double x1=lat1*dd,x2=lat2*dd;
    double y1=lng1*dd,y2=lng2*dd;
    double R = 6371004;
    double distance = (2*R*asin(sqrt(2-2*cos(x1)*cos(x2)*cos(y1-y2) - 2*sin(x1)*sin(x2))/2));
    return   distance/1000;
    //unit:KM
}

@end
