#import "CarbonHotKey/CarbonHotKeyCenter.h"
#import <Cocoa/Cocoa.h>
#import <emacs-module.h>

@interface MjolmacsEnv : NSObject {
  NSMutableDictionary *funcs;
  NSFileHandle *pipe;
}

@end
