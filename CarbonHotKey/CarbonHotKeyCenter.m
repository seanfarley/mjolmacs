/*
 CarbonHotKey -- CarbonHotKeyCenter.m

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

#import <objc/runtime.h>

#import "CarbonHotKeyCenter.h"
#import "CarbonHotKeyUtilities.h"

#pragma mark Private Global Declarations

OSStatus carbon_hotKeyHandler(EventHandlerCallRef nextHandler,
                              EventRef theEvent, void *userData);

#pragma mark CarbonHotKey

@interface CarbonHotKey ()

@property(nonatomic, retain) NSValue *hotKeyRef;
@property(nonatomic) UInt32 hotKeyID;

@property(nonatomic, assign, setter=_setTarget:) id target;
@property(nonatomic, setter=_setAction:) SEL action;
@property(nonatomic, strong, setter=_setObject:) id object;
@property(nonatomic, copy, setter=_setTask:) CarbonHotKeyTask task;

@property(nonatomic, setter=_setKeyCode:) unsigned short keyCode;
@property(nonatomic, setter=_setModifierFlags:) NSUInteger modifierFlags;

@end

@implementation CarbonHotKey

+ (instancetype)hotKeyWithKeyCode:(unsigned short)keyCode
                    modifierFlags:(NSUInteger)flags
                             task:(CarbonHotKeyTask)task {
  CarbonHotKey *newHotKey = [[self alloc] init];
  [newHotKey _setTask:task];
  [newHotKey _setKeyCode:keyCode];
  [newHotKey _setModifierFlags:flags];
  return newHotKey;
}

- (void)dealloc {
  [[CarbonHotKeyCenter sharedHotKeyCenter] unregisterHotKey:self];
  [super dealloc];
}

- (NSUInteger)hash {
  return [self keyCode] ^ [self modifierFlags];
}

- (BOOL)isEqual:(id)object {
  BOOL equal = NO;
  if ([object isKindOfClass:[CarbonHotKey class]]) {
    equal = ([object keyCode] == [self keyCode]);
    equal &= ([object modifierFlags] == [self modifierFlags]);
  }
  return equal;
}

- (NSString *)description {
  NSMutableArray *bits = [NSMutableArray array];
  if ((_modifierFlags & NSEventModifierFlagControl) > 0) {
    [bits addObject:@"NSControlKeyMask"];
  }
  if ((_modifierFlags & NSEventModifierFlagCommand) > 0) {
    [bits addObject:@"NSCommandKeyMask"];
  }
  if ((_modifierFlags & NSEventModifierFlagShift) > 0) {
    [bits addObject:@"NSShiftKeyMask"];
  }
  if ((_modifierFlags & NSEventModifierFlagOption) > 0) {
    [bits addObject:@"NSAlternateKeyMask"];
  }

  NSString *flags = [NSString
      stringWithFormat:@"(%@)", [bits componentsJoinedByString:@" | "]];
  NSString *invokes = @"(block)";
  if ([self target] != nil && [self action] != nil) {
    invokes = [NSString stringWithFormat:@"[%@ %@]", [self target],
                                         NSStringFromSelector([self action])];
  }
  return [NSString
      stringWithFormat:@"%@\n\t(key: %hu\n\tflags: %@\n\tinvokes: %@)",
                       [super description], [self keyCode], flags, invokes];
}

- (void)invokeWithEvent:(NSEvent *)event {
  if (_target != nil && _action != nil &&
      [_target respondsToSelector:_action]) {
    [_target performSelector:_action withObject:event withObject:_object];
  } else if (_task != nil) {
    _task(event);
  }
}

@end

#pragma mark CarbonHotKeyCenter

static CarbonHotKeyCenter *sharedHotKeyCenter = nil;

@implementation CarbonHotKeyCenter {
  NSMutableSet *_registeredHotKeys;
  UInt32 _nextHotKeyID;
}

+ (instancetype)sharedHotKeyCenter {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedHotKeyCenter = [super allocWithZone:nil];
    sharedHotKeyCenter = [sharedHotKeyCenter init];

    EventTypeSpec eventSpec;
    eventSpec.eventClass = kEventClassKeyboard;
    eventSpec.eventKind = kEventHotKeyReleased;
    InstallApplicationEventHandler(&carbon_hotKeyHandler, 1, &eventSpec, NULL,
                                   NULL);
  });
  return sharedHotKeyCenter;
}

+ (id)allocWithZone:(NSZone *)zone {
  return sharedHotKeyCenter;
}

- (id)init {
  if (self != sharedHotKeyCenter) {
    return sharedHotKeyCenter;
  }

  self = [super init];
  if (self) {
    _registeredHotKeys = [[NSMutableSet alloc] init];
    _nextHotKeyID = 1;
  }
  return self;
}

- (NSSet *)hotKeysMatching:(BOOL (^)(CarbonHotKey *hotkey))matcher {
  NSPredicate *predicate = [NSPredicate
      predicateWithBlock:^BOOL(id evaluatedObject,
                               __attribute__((unused)) NSDictionary *bindings) {
        return matcher(evaluatedObject);
      }];
  return [_registeredHotKeys filteredSetUsingPredicate:predicate];
}

- (BOOL)hasRegisteredHotKeyWithKeyCode:(unsigned short)keyCode
                         modifierFlags:(NSUInteger)flags {
  return [self hotKeysMatching:^BOOL(CarbonHotKey *hotkey) {
           return hotkey.keyCode == keyCode && hotkey.modifierFlags == flags;
         }].count > 0;
}

- (CarbonHotKey *)_registerHotKey:(CarbonHotKey *)hotKey {
  if ([_registeredHotKeys containsObject:hotKey]) {
    return hotKey;
  }

  EventHotKeyID keyID;
  keyID.signature = 'htk1';
  keyID.id = _nextHotKeyID;

  EventHotKeyRef carbonHotKey;
  UInt32 flags = CarbonModifierFlagsFromCocoaModifiers([hotKey modifierFlags]);
  OSStatus err =
      RegisterEventHotKey([hotKey keyCode], flags, keyID,
                          GetEventDispatcherTarget(), 0, &carbonHotKey);

  // error registering hot key
  if (err != 0) {
    return nil;
  }

  NSValue *refValue = [NSValue valueWithPointer:carbonHotKey];
  [hotKey setHotKeyRef:refValue];
  [hotKey setHotKeyID:_nextHotKeyID];

  _nextHotKeyID++;
  [_registeredHotKeys addObject:hotKey];

  return hotKey;
}

- (CarbonHotKey *)registerHotKey:(CarbonHotKey *)hotKey {
  return [self _registerHotKey:hotKey];
}

- (void)unregisterHotKey:(CarbonHotKey *)hotKey {
  NSValue *hotKeyRef = [hotKey hotKeyRef];
  if (hotKeyRef) {
    EventHotKeyRef carbonHotKey = (EventHotKeyRef)[hotKeyRef pointerValue];
    UnregisterEventHotKey(carbonHotKey);
    [hotKey setHotKeyRef:nil];
  }

  [_registeredHotKeys removeObject:hotKey];
}

- (CarbonHotKey *)registerHotKeyWithKeyCode:(unsigned short)keyCode
                              modifierFlags:(NSUInteger)flags
                                       task:(CarbonHotKeyTask)task {
  // we can't add a new hotkey if something already has this combo
  if ([self hasRegisteredHotKeyWithKeyCode:keyCode modifierFlags:flags]) {
    return nil;
  }

  CarbonHotKey *newHotKey = [[CarbonHotKey alloc] init];
  [newHotKey _setTask:task];
  [newHotKey _setKeyCode:keyCode];
  [newHotKey _setModifierFlags:flags];

  return [self _registerHotKey:newHotKey];
}

- (CarbonHotKey *)registerHotKeyWithKeyCode:(unsigned short)keyCode
                              modifierFlags:(NSUInteger)flags
                                     target:(id)target
                                     action:(SEL)action
                                     object:(id)object {
  // we can't add a new hotkey if something already has this combo
  if ([self hasRegisteredHotKeyWithKeyCode:keyCode modifierFlags:flags]) {
    return nil;
  }

  // build the hotkey object:
  CarbonHotKey *newHotKey = [[CarbonHotKey alloc] init];
  [newHotKey _setTarget:target];
  [newHotKey _setAction:action];
  [newHotKey _setObject:object];
  [newHotKey _setKeyCode:keyCode];
  [newHotKey _setModifierFlags:flags];
  return [self _registerHotKey:newHotKey];
}

- (void)unregisterHotKeysMatching:(BOOL (^)(CarbonHotKey *hotkey))matcher {
  // explicitly unregister the hotkey, since relying on the unregistration in
  // -dealloc can be problematic
  @autoreleasepool {
    NSSet *matches = [self hotKeysMatching:matcher];
    for (CarbonHotKey *hotKey in matches) {
      [self unregisterHotKey:hotKey];
    }
  }
}

- (void)unregisterHotKeysWithTarget:(id)target {
  [self unregisterHotKeysMatching:^BOOL(CarbonHotKey *hotkey) {
    return hotkey.target == target;
  }];
}

- (void)unregisterHotKeysWithTarget:(id)target action:(SEL)action {
  [self unregisterHotKeysMatching:^BOOL(CarbonHotKey *hotkey) {
    return hotkey.target == target && sel_isEqual(hotkey.action, action);
  }];
}

- (void)unregisterHotKeyWithKeyCode:(unsigned short)keyCode
                      modifierFlags:(NSUInteger)flags {
  [self unregisterHotKeysMatching:^BOOL(CarbonHotKey *hotkey) {
    return hotkey.keyCode == keyCode && hotkey.modifierFlags == flags;
  }];
}

- (void)unregisterAllHotKeys {
  NSSet *keys = [_registeredHotKeys copy];
  for (CarbonHotKey *key in keys) {
    [self unregisterHotKey:key];
  }
}

- (NSSet *)registeredHotKeys {
  return [self hotKeysMatching:^BOOL(CarbonHotKey *hotkey) {
    return hotkey.hotKeyRef != NULL;
  }];
}

@end

OSStatus carbon_hotKeyHandler(__attribute__((unused))
                              EventHandlerCallRef nextHandler,
                              EventRef theEvent,
                              __attribute__((unused)) void *userData) {
  @autoreleasepool {
    EventHotKeyID hotKeyID;
    GetEventParameter(theEvent, kEventParamDirectObject, typeEventHotKeyID,
                      NULL, sizeof(hotKeyID), NULL, &hotKeyID);

    UInt32 keyID = hotKeyID.id;

    NSSet *matchingHotKeys = [[CarbonHotKeyCenter sharedHotKeyCenter]
        hotKeysMatching:^BOOL(CarbonHotKey *hotkey) {
          return hotkey.hotKeyID == keyID;
        }];

    if ([matchingHotKeys count] > 1) {
      NSLog(@"ERROR!");
    }

    CarbonHotKey *matchingHotKey = [matchingHotKeys anyObject];

    NSEvent *event = [NSEvent eventWithEventRef:theEvent];
    NSEvent *keyEvent = [NSEvent keyEventWithType:NSEventTypeKeyUp
                                         location:[event locationInWindow]
                                    modifierFlags:[event modifierFlags]
                                        timestamp:[event timestamp]
                                     windowNumber:-1
                                          context:nil
                                       characters:@""
                      charactersIgnoringModifiers:@""
                                        isARepeat:NO
                                          keyCode:[matchingHotKey keyCode]];

    [matchingHotKey invokeWithEvent:keyEvent];
  }

  return noErr;
}
