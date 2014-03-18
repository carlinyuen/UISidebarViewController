//
//  UISidebarViewController.m
//  Unsplash
//
//  Created by . Carlin on 3/13/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import "UISidebarViewController.h"

#import <QuartzCore/QuartzCore.h>

    NSString * const UISidebarViewControllerNotificationDidShow = @"sidebarDidShow";
    NSString * const UISidebarViewControllerNotificationWillShow = @"sidebarWillShow";
    NSString * const UISidebarViewControllerNotificationWillHide = @"sidebarWillHide";
    NSString * const UISidebarViewControllerNotificationDidHide = @"sidebarDidHide";

    /** Default Preferences */
    #define TIME_ANIMATION_DURATION 0.2
    #define SIZE_DEFAULT_SIDEBAR_WIDTH 270
    #define SIZE_PAN_FROM_EDGE_MARGIN 44
    #define ALPHA_OVERLAY 0.5

@interface UITouchPassingView : UIView
    @property (nonatomic, weak) UIView *targetView; // View to pass touches to
@end
@implementation UITouchPassingView
// If hitTest returns the container, then return targetView instead
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	UIView *child = nil;
    if ((child = [super hitTest:point withEvent:event]) == self && self.targetView) {
    	return self.targetView;
	}
    return child;
}
@end

@interface UISidebarViewController () <
    UIGestureRecognizerDelegate
>

    /** UIViewControllers to manipulate */
    @property (nonatomic, strong, readwrite) UIViewController *centerVC;
    @property (nonatomic, strong, readwrite) UIViewController *sidebarVC;

    /** Keep track of original frame of sidebar before orientation changes */
    @property (nonatomic, assign) CGRect sidebarFrame;

    /** Overlay over the center view to darken it up and pass touches */
    @property (nonatomic, strong) UITouchPassingView *overlayView;

    /** For detecting pan gesture for sidebar */
    @property (nonatomic, strong) UIPanGestureRecognizer *openSidebarPanGesture;
    @property (nonatomic, strong) UIPanGestureRecognizer *closeSidebarPanGesture;

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
        _overlayOpacity = ALPHA_OVERLAY;
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
    [self setupOverlayView];
    [self setupCenterView];
    [self setupSidebarView];
    [self setupGestures];

    // Attach gestures
    [self.centerVC.view addGestureRecognizer:self.openSidebarPanGesture];
    [self.overlayView addGestureRecognizer:self.closeSidebarPanGesture];
    [self.overlayView addGestureRecognizer:self.tapGesture];
}

/** This may be called when coming back from background */
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Update bounds in case screen has changed
    self.overlayView.frame = self.view.bounds;
    self.centerVC.view.frame = self.view.bounds;

    // Tell view controllers that they will appear
    [[self centerVC] viewWillAppear:animated];
    [[self sidebarVC] viewWillAppear:animated];
}

/** Setup code for rotation */
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.sidebarFrame = self.sidebarVC.view.frame;
}

/** This code will be called during animation of rotation */
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Reference bounds to view
    CGRect bounds = self.view.bounds;

    // Set overlay and center to match view bounds
    self.overlayView.frame = bounds;
    self.centerVC.view.frame = bounds;

    // Reset sidebar frame to what it was before rotation
    self.sidebarVC.view.frame = self.sidebarFrame;

    // Force show / hide sidebar to clear weird states
    [self displaySidebar:self.sidebarIsShowing animations:nil completion:nil];
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

- (void)setupOverlayView
{
    self.overlayView = [UITouchPassingView new];
    self.overlayView.frame = self.view.bounds;
    self.overlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:ALPHA_OVERLAY];
    self.overlayView.alpha = 0; // Start invisible so we can fade in
}

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
        self.sidebarVC = [UITableViewController new];
        self.sidebarVC.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
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

/** @brief Creates and sets up a whole new gesture recognizer and attaches it to the given view */
- (void)setupGestures
{
    // Open sidebar gesture
    self.openSidebarPanGesture = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(viewPanned:)];
    [self.openSidebarPanGesture setMinimumNumberOfTouches:1];
    [self.openSidebarPanGesture setMaximumNumberOfTouches:1];
    [self.openSidebarPanGesture setDelegate:self];

    // Close sidebar gesture
    self.closeSidebarPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(viewPanned:)];
    [self.closeSidebarPanGesture setMinimumNumberOfTouches:1];
    [self.closeSidebarPanGesture setMaximumNumberOfTouches:1];
    [self.closeSidebarPanGesture setDelegate:self];

    // Tap gesture
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
}


#pragma mark - Class Methods

/** @brief Trigger show or hide sidebar */
- (void)displaySidebar:(BOOL)show animations:(void (^)(CGRect))animations completion:(void (^)(BOOL))completion
{
    [self.view bringSubviewToFront:self.sidebarVC.view];

    // Update overlay color
    if (show) {
        self.overlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:ALPHA_OVERLAY];
    }

    // Setup target frame and animations and callbacks
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

        // Add overlayview
        [self.view insertSubview:self.overlayView belowSubview:self.sidebarVC.view];
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
    }
       
    // Send notification that view will be shown / hidden
    [[NSNotificationCenter defaultCenter]
        postNotificationName:(show
            ? UISidebarViewControllerNotificationWillShow
            : UISidebarViewControllerNotificationWillHide
        ) object:self userInfo:nil];

    // Animate with custom options
    __block UISidebarViewController *this = self; // Prevent retain cycles
    self.sidebarIsShowing = show;
    [UIView animateWithDuration:self.animationDuration delay:0
        options:UIViewAnimationOptionBeginFromCurrentState
            | UIViewAnimationOptionCurveEaseInOut
        animations:^{
            [[this overlayView] setAlpha:show];
            if (animations) {
                animations(targetFrame);    // Call custom animations if given
            } else {
                [[[this sidebarVC] view] setFrame:targetFrame];
            }
        }
        completion:^(BOOL finished) {
            if (finished)
            {
                // Remove overlay if animation finished
                if (!show) {
                    [[this overlayView] removeFromSuperview];
                }
                       
                // Send notification that view was shown / hidden
                [[NSNotificationCenter defaultCenter]
                    postNotificationName:(show
                        ? UISidebarViewControllerNotificationDidShow
                        : UISidebarViewControllerNotificationDidHide
                    ) object:self userInfo:nil];
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
    CGPoint velocity = [gesture velocityInView:gesture.view];

    // Panning - move sidebar along
    if (gesture.state == UIGestureRecognizerStateChanged)
    {
        // Figure out whether to show or hide if the user let go now
        self.sidebarIsShowing = (velocity.x > 0);

        // Allow dragging only in x-coordinates by only updating the x-coordinate with translation position.
        self.sidebarVC.view.center = CGPointMake(
            self.sidebarVC.view.center.x + translatedPoint.x,
            self.sidebarVC.view.center.y
        );
        [gesture setTranslation:CGPointMake(0,0) inView:self.view];
    }

    // Panning starting - if opening sidebar, check view order
    if (gesture.state == UIGestureRecognizerStateBegan
        && gesture == self.openSidebarPanGesture)
    {
        // Make sure view order is correct
        [self.view bringSubviewToFront:self.sidebarVC.view];
        [self.view insertSubview:self.overlayView belowSubview:self.sidebarVC.view];
        [self.view sendSubviewToBack:self.centerVC.view];
    }

    // Panning ended - animate to intended state
    if (gesture.state == UIGestureRecognizerStateEnded)
    {
        // Animate to show / hide sidebar
        [self displaySidebar:self.sidebarIsShowing animations:nil completion:nil];
    }
}

/** @brief Tap gesture recognized */
- (void)viewTapped:(UITapGestureRecognizer *)gesture
{
    // This should only happen on the overlayView view, when the sidebar is shown
    if (gesture.view == self.overlayView && self.sidebarIsShowing) {
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
    // If this recognizer is the opening sidebar gesture
    if (gestureRecognizer == self.openSidebarPanGesture)
    {
        // Figure out if it's starting from the right edge or not
        CGPoint startingPoint = [gestureRecognizer locationInView:self.view];
        if ((self.direction == UISidebarViewControllerDirectionLeft
                && startingPoint.x <= SIZE_PAN_FROM_EDGE_MARGIN)
            || (self.direction == UISidebarViewControllerDirectionRight
                && startingPoint.x >= CGRectGetWidth(self.view.bounds) - SIZE_PAN_FROM_EDGE_MARGIN)) {
            return true;
        }
        return false;
    }

    return true;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return true;
}


@end
