UISidebarViewController
=======================

Simplest darn iOS sidebar menu implementation ever. Clean, simple, sidebar panel from left or right, works with rotations, can supply basic custom animations. Supports iOS 6 and 7.

Keywords: Xcode, ios, sidebar, menu, hamburger, panel, simple.

### Setup
Super easy setup!

 1. Add UISidebarViewController.h/.m files in your project (or just drag the
		folder into your project file tree).
 2. `#import "UISidebarViewController.h"` where you need it, usually in the
		AppDelegate.
 3. Create the view controllers for your center view and sidebar view.
 4. Create and initialize the UISidebarViewController with the center and
		sidebar view controllers, and you're done!
 5. Bonus: observe for notifications on sidebar showing / hiding, or set custom
		showing / closing animations.

		#import "UISidebarViewController.h"`

		- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
		{
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
