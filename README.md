UISidebarViewController
=======================

Simplest darn iOS sidebar menu implementation ever. Clean, simple, sidebar panel 
from left or right, works with rotations, can supply basic custom animations,
and you have full control over the sidebar and center views to manipulate their
transparency and content, with exception to the frames of the views since we
have to modify those to fit the UISidebarViewController and animate the sidebar.

Supports iOS 6 and 7. NOTE: sidebar appears OVER the main center view.

Keywords: Xcode, ios, sidebar, menu, hamburger, panel, simple.

![Vertical Closed](/images/vertical1.png)
![Vertical Opened](/images/vertical2.png)
![Horizontal Closed](/images/horizontal1.png)
![Horizontal Opened](/images/horizontal2.png)

## Setup
Super easy setup!

 1. Add UISidebarViewController.h/.m files in your project (or just drag the
		folder into your project file tree).
 2. `#import "UISidebarViewController.h"` where you need it, usually in the
		AppDelegate.
 3. Create the view controllers for your center view and sidebar view.
 4. Create and initialize the UISidebarViewController with the center and
		sidebar view controllers. You're done!
 5. Bonus: customize sidebar, observe for notifications on sidebar showing / hiding, or set custom showing / closing animations.

		#import "UISidebarViewController.h"`

		- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
		{
			self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

			// Create base view controller
			UIViewController *rootVC = [[UIViewController alloc] initWithNibName:@"RootView" bundle:nil];

			// Create menu sidebar controller
			UITableViewController *menuVC = [[UITableViewController alloc] initWithNibName:@"MenuView" bundle:nil];

			self.viewController = [[UISidebarViewController alloc]
					initWithCenterViewController:rootVC
					andSidebarViewController:menuVC];
			self.window.rootViewController = self.viewController;

			[self.window makeKeyAndVisible];
			return YES;
		}

### Config
Extra properties that you can configure:

 - 
 
		/** Direction in which the sidebar should come from, defaults to left */
		@property (nonatomic, assign) UISidebarViewControllerDirection direction;

 - 

		/** Duration of slide animation when displaySidebar is called, defaults to 0.2 */
		@property (nonatomic, assign) CGFloat animationDuration;

 - 

		/** Width for sidebar to slide to, defaults to 270 */
		@property (nonatomic, assign) CGFloat sidebarWidth;

 - 

		/** Opacity of the black overlay on center view when sidebar is out, defaults to 0.5k */
		@property (nonatomic, assign) CGFloat overlayOpacity;

Properties you can check:

 - `@property (nonatomic, assign, readonly) BOOL sidebarIsShowing;` 
		to see if the sidebar is being or in the process of being shown.
 - `@property (nonatomic, strong, readonly) UIViewController *centerVC;`
		a reference to the center view controller directly.
 - `@property (nonatomic, strong, readonly) UIViewController *sidebarVC;`
		a reference to the sidebar view controller directly.


### Notifications
There are four notifications that are fired when the sidebar is about to be
 or finished being shown or hidden. The notifications are posted through the
 default NSNotificationCenter, with the names:

 - `UISidebarViewControllerNotificationDidShow`
 - `UISidebarViewControllerNotificationDidHide`
 - `UISidebarViewControllerNotificationWillShow`
 - `UISidebarViewControllerNotificationWillHide`

These notifications are called right before a call to animate the showing
/ hiding of the sidebar. This means that the notification won't be posted if the
sidebar is being panned until the user lets go. To observe for these notifications:

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(notificationHandler:)
		name:@"UISidebarViewControllerNotificationWillShow"
		object:nil];

### Custom Animations
The default animations for the showing / hiding of the sidebar is just a simple
slide in the horizontal direction. You can supply your own custom animations as
well by setting these four:

 - `@property (nonatomic, copy) AnimationBlock showSidebarAnimation;`
 - `@property (nonatomic, copy) AnimationCompletionBlock showSidebarCompletion;`
 - `@property (nonatomic, copy) AnimationBlock hideSidebarAnimation;`
 - `@property (nonatomic, copy) AnimationCompletionBlock hideSidebarCompletion;`

`AnimationBlock` and `AnimationCompletionBlock` are defined as follows:

	/** Custom animation block type, targetFrame is calculated target frame location for sidebar */
	typedef void (^AnimationBlock)(CGRect targetFrame);

	/** Custom completion block type, finished refers to whether or not the animation was completed */
	typedef void (^AnimationCompletionBlock)(BOOL finished);

### License
MIT
