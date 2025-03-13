#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

// Simple, targeted fix based directly on the Qt bug
@interface KeyRepeatPlugin : NSObject
+ (void)load;
@end

// The original implementation of key repeat
static IMP originalHandleKeyEvent = NULL;

// Flag to prevent infinite recursion
static BOOL handlingRepeat = NO;

// Rate limiting for repeat events
static NSTimeInterval lastRepeatTime = 0;
static const NSTimeInterval kMinRepeatInterval = 0.05; // 50ms minimum between repeats

// Our new implementation
void krf_handleKeyEvent(id self, SEL _cmd, NSEvent *event) {
    // Call original method first
    if (originalHandleKeyEvent) {
        ((void(*)(id, SEL, NSEvent *))originalHandleKeyEvent)(self, _cmd, event);
    }

    // Only process key down events and don't recurse
    if ([event type] == NSEventTypeKeyDown && !handlingRepeat) {
        // Get event info
        unsigned short keyCode = [event keyCode];
        BOOL isRepeat = [event isARepeat];

        // If it's a repeat event AND we're not too close to the last repeat
        if (isRepeat) {
            NSTimeInterval now = [[NSProcessInfo processInfo] systemUptime];

            // Rate limit to avoid infinite loops
            if ((now - lastRepeatTime) >= kMinRepeatInterval) {
                // Mark that we're handling a repeat to prevent recursion
                handlingRepeat = YES;
                lastRepeatTime = now;

                NSLog(@"Force processing repeat key: %d", keyCode);

                // Get the key window and first responder
                NSWindow *keyWindow = [NSApp keyWindow];
                if (keyWindow) {
                    NSResponder *firstResponder = [keyWindow firstResponder];
                    if ([firstResponder respondsToSelector:@selector(keyDown:)]) {
                        // Force-feed the key event to the first responder
                        [firstResponder performSelector:@selector(keyDown:) withObject:event];
                    }
                }

                // Reset recursion flag
                handlingRepeat = NO;
            }
        }
    }
}

@implementation KeyRepeatPlugin

+ (void)load {
    NSLog(@"Loading KeyRepeatPlugin to fix key repeat in Qt apps on macOS");

    // Get process path
    NSString *processPath = [[[NSProcessInfo processInfo] arguments] firstObject];

    // Only apply in nvim-qt processes
    if (![processPath containsString:@"nvim-qt"]) {
        NSLog(@"Not nvim-qt process. Skipping key repeat fix.");
        return;
    }

    // Find the NSTextInputContext class
    Class cls = NSClassFromString(@"NSTextInputContext");
    if (!cls) {
        NSLog(@"Failed to find NSTextInputContext class");
        return;
    }

    // The key method to intercept in cocoa for key events
    SEL selector = @selector(handleEvent:);
    Method originalMethod = class_getInstanceMethod(cls, selector);
    if (!originalMethod) {
        NSLog(@"Failed to find handleEvent: method");
        return;
    }

    // Store original implementation
    originalHandleKeyEvent = method_getImplementation(originalMethod);
    if (!originalHandleKeyEvent) {
        NSLog(@"Failed to get original implementation");
        return;
    }

    // Replace with our implementation
    method_setImplementation(originalMethod, (IMP)krf_handleKeyEvent);

    // Disable the press and hold feature more aggressively
    // First try app-level defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:NO forKey:@"ApplePressAndHoldEnabled"];
    [defaults synchronize];

    // Then try global defaults as root (this might not work without admin privileges)
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/defaults"];
    [task setArguments:@[@"write", @"-g", @"ApplePressAndHoldEnabled", @"-bool", @"false"]];
    [task launch];

    // Finally, directly modify the application's NSEvent handling for press-and-hold
    // Add a method to NSEvent to override the _delayedKeyDown method
    Class eventClass = [NSEvent class];
    if (eventClass) {
        // Try to disable the press-and-hold mechanism by telling NSEvent
        // that press-and-hold is disabled for all characters
        Method originalPressAndHoldMethod = class_getInstanceMethod(eventClass, NSSelectorFromString(@"_shouldStartPressAndHold"));
        if (originalPressAndHoldMethod) {
            // Replace it with a method that always returns NO
            IMP newImp = imp_implementationWithBlock(^BOOL(id __unused self, NSEvent * __unused event) {
                return NO;
            });
            method_setImplementation(originalPressAndHoldMethod, newImp);
            NSLog(@"Disabled press-and-hold in NSEvent");
        }
    }

    NSLog(@"Key repeat fix applied successfully");
}

@end
