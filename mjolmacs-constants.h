#ifndef MJOLMACS_CONSTANTS_H_
#define MJOLMACS_CONSTANTS_H_

#include <emacs-module.h>
#include <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

emacs_value Qnil;
emacs_value Qt;

const NSNumber *control;
const NSNumber *meta;
const NSNumber *command;
const NSNumber *shift;

const NSDictionary *modifier_map;
const NSDictionary *key_map;
const NSDictionary *rev_key_map;

#endif // MJOLMACS_CONSTANTS_H_
