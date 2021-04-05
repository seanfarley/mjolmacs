#import <Cocoa/Cocoa.h>
#import <emacs-module.h>
#import "CarbonHotKey/CarbonHotKeyCenter.h"

@interface MjolmacsEnv : NSObject {
}

// strong is needed for ARC not to clean it up
// https://stackoverflow.com/questions/7198562/programmatically-create-and-open-an-nswindow-with-arc-on-lion-10-7
@property (strong) NSWindow *window;

@end
