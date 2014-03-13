//
//  UISidebarViewController.m
//  Unsplash
//
//  Created by . Carlin on 3/13/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import "UISidebarViewController.h"

#import <QuartzCore/QuartzCore.h>

    #define TIME_ANIMATION_DURATION 0.2

    #define SIZE_DEFAULT_SIDEBAR_WIDTH 270

@interface UISidebarViewController () <
    UIGestureRecognizerDelegate
>

    /** UIViewControllers to manipulate */
    @property (nonatomic, strong) UIViewController *centerVC;
    @property (nonatomic, strong) UIViewController *sidebarVC;

    /** For detecting pan gesture for sidebar */
    @property (nonatomic, strong) UIPanGestureRecognizer *panGesture;

    /** For detecting tap on center when sidebar is showing */
    @property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

    /** Flag for whether or not sidebar is in process of showing or is shown */
    @property (nonatomic, assign, readwrite) BOOL sidebarIsShowing;

@end

@implementation UISidebarViewController

/** @brief Initialize with view controller to be in the center, and the view controller to be the sidebar */
- (id)initWithCenterViewController:(UIViewController *)center andSidebarViewController:(UIViewController *)sidebar
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        // ViewControllers
        _centerVC = center;
        _sidebarVC = sidebar;

        // Default Preferences
        _direction = UISidebarViewControllerDirectionLeft;
        _animationDuration = TIME_ANIMATION_DURATION;
        _sidebarWidth = SIZE_DEFAULT_SIDEBAR_WIDTH;
        _sidebarIsShowing = false;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Hide own view
    self.view.backgroundColor = [UIColor clearColor];

    // Setup
    [self setupCenterView];
    [self setupSidebarView];
    [self setupGestures];

    // Attach pan gesture to center view
    [self.centerVC.view addGestureRecognizer:self.panGesture];
}

/** This may be called when coming back from background */
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Tell view controllers that they will appear
    [[self centerVC] viewWillAppear:animated];
    [[self sidebarVC] viewWillAppear:animated];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Update bounds of sidebar and center view
    CGRect sFrame = self.sidebarVC.view.frame;
    CGRect cFrame = self.centerVC.view.frame;
    CGRect bounds = self.view.bounds;
   
    // Special case if sidebar is showing
    if (self.sidebarIsShowing)
    {
        self.sidebarVC.view.frame = CGRectMake(
            (self.direction == UISidebarViewControllerDirectionLeft
                ? -CGRectGetWidth(sFrame) + self.sidebarWidth
                : CGRectGetWidth(bounds) - self.sidebarWidth),
            0,
            CGRectGetWidth(sFrame),
            CGRectGetHeight(sFrame)
        );
    }
    else    // Not showing, just shift over (frames already rotated!)
    {
        self.sidebarVC.view.frame = CGRectMake(
            (self.direction == UISidebarViewControllerDirectionLeft
                ? -CGRectGetWidth(sFrame)
                : CGRectGetWidth(bounds)),
            0,
            CGRectGetWidth(sFrame),
            CGRectGetHeight(sFrame)
        );
    }
    self.centerVC.view.frame = bounds;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    // Remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Setup

- (void)setupCenterView
{
    // Create centerVC if does not exist
    if (!self.centerVC)
    {
        self.centerVC = [UIViewController new];
        self.centerVC.view.backgroundColor = [UIColor whiteColor];
        self.centerVC.view.frame = self.view.bounds;
    }

    // Setup centerVC
    CGRect frame = self.centerVC.view.frame;
    frame.origin = CGPointMake(0, 0);
    self.centerVC.view.frame = frame;

    // Add to this view
    [self.view addSubview:self.centerVC.view];
    [self addChildViewController:self.centerVC];
    [self.centerVC didMoveToParentViewController:self];
}

- (void)setupSidebarView
{
    // Create sidebarVC if does not exist
    if (!self.sidebarVC)
    {
        self.sidebarVC = [UIViewController new];
        self.sidebarVC.view.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.5];
        self.sidebarVC.view.frame = self.view.bounds;
    }

    // Setup sidebarVC
    CGRect frame = self.sidebarVC.view.frame;
    frame.origin = (self.direction == UISidebarViewControllerDirectionLeft)
        ? CGPointMake(-CGRectGetWidth(frame), 0)
        : CGPointMake(CGRectGetWidth(self.view.bounds), 0);
    self.sidebarVC.view.frame = frame;
    
    // Add to this view
    [self.view addSubview:self.sidebarVC.view];
    [self addChildViewController:self.sidebarVC];
    [self.sidebarVC didMoveToParentViewController:self];
}

/** @brief Creates and sets up a whole new gesture recognizer and attaches it to the centerVC view */
- (void)setupGestures
{
    // Regular UIPanGestureRecognizer for < iOS 7
    if (deviceOSVersionLessThan(iOS7)) {
        self.panGesture = [[UIPanGestureRecognizer alloc]
            initWithTarget:self action:@selector(sidebarPanned:)];
    }
    else    // UIScreenEdgePanGestureRecognizer
    {
        UIScreenEdgePanGestureRecognizer *edgePan = [[UIScreenEdgePanGestureRecognizer alloc]
            initWithTarget:self action:@selector(viewPanned:)];
        edgePan.edges = UIRectEdgeLeft | UIRectEdgeRight;
        self.panGesture = edgePan;
    }

    // Configure rest of the gesture
    [self.panGesture setMinimumNumberOfTouches:1];
    [self.panGesture setMaximumNumberOfTouches:1];
    [self.panGesture setDelegate:self];

    // Tap gesture - don't add to center view till sidebar is shown
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
}


#pragma mark - Class Methods

/** @brief Trigger show or hide sidebar */
- (void)displaySidebar:(BOOL)show animations:(void (^)(CGRect))animations completion:(void (^)(BOOL))completion
{
    [self.view bringSubviewToFront:self.sidebarVC.view];

    // Prevent retain cycles
    CGRect targetFrame = self.sidebarVC.view.frame;
    if (show)   // Showing sidebar
    {
        // Set frame
        targetFrame.origin.x = (self.direction == UISidebarViewControllerDirectionLeft)
            ? -CGRectGetWidth(targetFrame) + self.sidebarWidth
            : CGRectGetWidth(self.view.bounds) - self.sidebarWidth;

        // Set animations
        if (!animations) {
            animations = self.showSidebarAnimation;
        }
        if (!completion) {
            completion = self.showSidebarCompletion;
        }
    }
    else    // Hiding sidebar
    {
        // Set frame
        targetFrame.origin.x = (self.direction == UISidebarViewControllerDirectionLeft)
            ? -CGRectGetWidth(targetFrame)
            : CGRectGetWidth(self.view.bounds);
            
        // Set animations
        if (!animations) {
            animations = self.hideSidebarAnimation;
        }
        if (!completion) {
            completion = self.hideSidebarCompletion;
        }

        // Remove tap gesture from center view
        [self.centerVC.view removeGestureRecognizer:self.tapGesture];
    }

    // Animate with custom options
    __block UISidebarViewController *this = self;
    self.sidebarIsShowing = show;
    [UIView animateWithDuration:self.animationDuration delay:0
        options:UIViewAnimationOptionBeginFromCurrentState
            | UIViewAnimationOptionCurveEaseInOut
        animations:^{
            if (animations) {
                animations(targetFrame);    // Call custom animations if given
            } else {
                [[[this sidebarVC] view] setFrame:targetFrame];
            }
        }
        completion:^(BOOL finished) {
            if (finished) {
                if (show) {
                    // Add tap gesture to dismiss view
                    [[[this centerVC] view] addGestureRecognizer:[this tapGesture]];
                }
            }
            if (completion) {
                completion(finished);       // Call custom completion if given
            }
        }];
}

/** @brief Toggle displaying of sidebar */
- (void)toggleSidebar:(id)sender
{
    [self displaySidebar:!self.sidebarIsShowing animations:nil completion:nil];
}


#pragma mark - Event Handlers

/** @brief Pan gesture recognized */
- (void)viewPanned:(UIPanGestureRecognizer *)gesture
{
    CGPoint translatedPoint = [gesture translationInView:self.view];
    CGPoint velocity = [gesture velocityInView:[gesture view]];
}

/** @brief Tap gesture recognized */
- (void)viewTapped:(UITapGestureRecognizer *)gesture
{
    // This should only happen on the centerVC view, when the sidebar is shown
    if (gesture.view == self.centerVC.view && self.sidebarIsShowing) {
        [self displaySidebar:false animations:nil completion:nil];
    }
    else {  // Weird state, notify user
        NSLog(@"Warning: tap gesture fired in bad state!");
    }
}


#pragma mark - Protocols
#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return true;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return true;
}


@end
