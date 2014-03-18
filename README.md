UISidebarViewController
=======================

Simplest darn iOS sidebar menu implementation ever. Clean, simple, sidebar panel from left or right, works with rotations, can supply basic custom animations. Supports iOS 6 and 7.

Keywords: Xcode, ios, sidebar, menu, hamburger, panel, simple.

## Setup

## Notifications
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

## License
MIT
