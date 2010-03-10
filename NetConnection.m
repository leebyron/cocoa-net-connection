#import "NetConnection.h"

//---------------------------------------------------------------------------
@interface NetConnection (Private)

- (id)initWithURL:(NSURL*)url;
- (BOOL)isNetworkConnected;
- (void)changedKey:(NSString*)key userInfo:(NSDictionary*)userInfo;

@end

//---------------------------------------------------------------------------
void _NetConnectionNotificationCallback(
  SCDynamicStoreRef store,
  CFArrayRef changedKeys,
  void* source) {

  NSString* key;
  NSDictionary* info;
  NSEnumerator* keysE = [(NSArray *)changedKeys objectEnumerator];
  while (key = [keysE nextObject]) {
    info = (NSDictionary*)SCDynamicStoreCopyValue(store, (CFStringRef)key);
    [(NetConnection*)source changedKey:key userInfo:info];
    [info release];
  }
}

//---------------------------------------------------------------------------
@implementation NetConnection

static NetConnection* instance = nil;

+ (NetConnection*)netConnection
{
  if (instance == nil) {
    NSURL* url = [NSURL URLWithString:@"http://www.google.com/"];
    instance = [[NetConnection alloc] initWithURL:url];
  }
  return instance;
}

- (void)dealloc
{
  // remove dynamic store
  CFRunLoopRemoveSource(
    [[NSRunLoop currentRunLoop] getCFRunLoop],
    runLoopSource,
    kCFRunLoopCommonModes
  );
  CFRelease(runLoopSource);
  CFRelease(dynamicStore);

  [super dealloc];
}

- (BOOL)isOnline
{
  return isOnline;
}

@end

//---------------------------------------------------------------------------
@implementation NetConnection (Private)

- (id)initWithURL:(NSURL*)url
{
  self = [super init];
  if (self) {
    // check present connectivity
    connectivityURL = [url retain];
    isOnline = [self isNetworkConnected];
    
    // set up dynamic store
    SCDynamicStoreContext context = {0, (void *)self, NULL, NULL, NULL};
    dynamicStore = SCDynamicStoreCreate(
      NULL,
      (CFStringRef) [[NSBundle mainBundle] bundleIdentifier],
      _NetConnectionNotificationCallback,
      &context
    );
    
    // add dynamic store to run loop
    runLoopSource = SCDynamicStoreCreateRunLoopSource(NULL, dynamicStore, 0);
    CFRunLoopAddSource(
      [[NSRunLoop currentRunLoop] getCFRunLoop],
      runLoopSource,
      kCFRunLoopCommonModes
    );
    
    // only observe ip changes
    BOOL success = SCDynamicStoreSetNotificationKeys(
      dynamicStore,
      NULL,
      (CFArrayRef)[NSArray arrayWithObject:@"State:/Network/Global/IP.*"]
    );
    if (!success) {
      NSLog(@"Error: keys could not be observed.");
    }
  }
  return self;
}

- (BOOL)isNetworkConnected
{
  SCNetworkConnectionFlags status;
  BOOL success = SCNetworkCheckReachabilityByName(
    [[connectivityURL host] UTF8String],
    &status
  );

  success = success
            && (status & kSCNetworkFlagsReachable)
            && !(status & kSCNetworkFlagsConnectionRequired);

  return success;
}

- (void)changedKey:(NSString*)key userInfo:(NSDictionary*)userInfo
{
  BOOL wasOnline = isOnline;
  isOnline = userInfo != nil;
  if (wasOnline != isOnline) {
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:kNetConnectionChangeNotification
                      object:self
                    userInfo:userInfo];
  }
}

@end
