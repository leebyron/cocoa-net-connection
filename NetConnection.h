/**
 * NetConnection is a small class responsible for keeping track of when your
 * computer has access to the internet. It does so via the isOnline method
 * and posting notifications to the NSNotificiationCenter.
 *
 * @author leebyron lee@leebyron.com
 *
 *
 * To determine at any time if you are online
 *
 * BOOL live = [[NetConnection netConnection] isOnline];
 *
 *
 * To keep track of net connection change events, subscribe to the event via
 * the NSNotificationCenter:
 *
 * NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
 * [nc addObserver:self
 *        selector:@selector(netConnectionChanged:)
 *            name:kNetConnectionChangeNotification
 *          object:[NetConnection netConnection]];
 *
 * - (void)netConnectionChanged:(NSNotification*)notif {
 *   BOOL live = [[NetConnection netConnection] isOnline];
 * }
 *
 */

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <ApplicationServices/ApplicationServices.h>

#define kNetConnectionChangeNotification @"NetConnectionChangeNotification"

@interface NetConnection : NSObject {
  SCDynamicStoreRef   dynamicStore;
  CFRunLoopSourceRef  runLoopSource;
  BOOL                isOnline;
  NSURL*              connectivityURL;
}

+ (NetConnection*)netConnection;
- (BOOL)isOnline;

@end
