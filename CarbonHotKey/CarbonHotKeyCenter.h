/*
 CarbonHotKey -- CarbonHotKeyCenter.h

 Copyright (c) 2010-2015 Dave DeLong <https://www.davedelong.com>
 Copyright (c) 2021 Sean Farley <https://farley.io>

 Permission to use, copy, modify, and/or distribute this software for any
 purpose with or without fee is hereby granted, provided that the above
 copyright notice and this permission notice appear in all copies.

 The software is provided "as is", without warranty of any kind, including all
 implied warranties of merchantability and fitness. In no event shall the
 author(s) or copyright holder(s) be liable for any claim, damages, or other
 liability, whether in an action of contract, tort, or otherwise, arising from,
 out of, or in connection with the software or the use or other dealings in the
 software.
 */

#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>

// a convenient typedef for the required signature of a hotkey block callback
typedef void (^CarbonHotKeyTask)(NSEvent *);

@interface CarbonHotKey : NSObject

// creates a new hotkey but does not register it
+ (instancetype)hotKeyWithKeyCode:(unsigned short)keyCode
                    modifierFlags:(NSUInteger)flags
                             task:(CarbonHotKeyTask)task;

@property(nonatomic, assign, readonly) id target;
@property(nonatomic, readonly) SEL action;
@property(nonatomic, strong, readonly) id object;
@property(nonatomic, copy, readonly) CarbonHotKeyTask task;

@property(nonatomic, readonly) unsigned short keyCode;
@property(nonatomic, readonly) NSUInteger modifierFlags;

@end

#pragma mark -

@interface CarbonHotKeyCenter : NSObject

+ (instancetype)sharedHotKeyCenter;

/**
 Register a hotkey.
 */
- (CarbonHotKey *)registerHotKey:(CarbonHotKey *)hotKey;

/**
 Register a target/action hotkey.
 The modifierFlags must be a bitwise OR of NSCommandKeyMask, NSAlternateKeyMask,
 NSControlKeyMask, or NSShiftKeyMask; Returns the hotkey registered.  If
 registration failed, returns nil.
 */
- (CarbonHotKey *)registerHotKeyWithKeyCode:(unsigned short)keyCode
                              modifierFlags:(NSUInteger)flags
                                     target:(id)target
                                     action:(SEL)action
                                     object:(id)object;

/**
 Register a block callback hotkey.
 The modifierFlags must be a bitwise OR of NSCommandKeyMask, NSAlternateKeyMask,
 NSControlKeyMask, or NSShiftKeyMask; Returns the hotkey registered.  If
 registration failed, returns nil.
 */
- (CarbonHotKey *)registerHotKeyWithKeyCode:(unsigned short)keyCode
                              modifierFlags:(NSUInteger)flags
                                       task:(CarbonHotKeyTask)task;

/**
 See if a hotkey exists with the specified keycode and modifier flags.
 NOTE: this will only check among hotkeys you have explicitly registered with
 CarbonHotKeyCenter. This does not check all globally registered hotkeys.
 */
- (BOOL)hasRegisteredHotKeyWithKeyCode:(unsigned short)keyCode
                         modifierFlags:(NSUInteger)flags;

/**
 Unregister a specific hotkey
 */
- (void)unregisterHotKey:(CarbonHotKey *)hotKey;

/**
 Unregister all hotkeys
 */
- (void)unregisterAllHotKeys;

/**
 Unregister all hotkeys with a specific target
 */
- (void)unregisterHotKeysWithTarget:(id)target;

/**
 Unregister all hotkeys with a specific target and action
 */
- (void)unregisterHotKeysWithTarget:(id)target action:(SEL)action;

/**
 Unregister a hotkey with a specific keycode and modifier flags
 */
- (void)unregisterHotKeyWithKeyCode:(unsigned short)keyCode
                      modifierFlags:(NSUInteger)flags;

/**
 Returns a set of currently registered hotkeys
 **/
- (NSSet *)registeredHotKeys;

@end
