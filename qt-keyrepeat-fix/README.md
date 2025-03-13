# Qt Key Repeat Fix for macOS

This is a fix for the key repeat issue in Qt applications (specifically nvim-qt) on macOS.

## Problem

On macOS, when you hold down a key in nvim-qt, it doesn't repeat. This happens because:

1. macOS has a "press and hold" feature that shows an accent menu when keys are held
2. Qt doesn't properly implement the NSTextInputClient protocol
3. As a result, macOS swallows key repeat events in Qt applications

This problem is documented in Qt Bug [QTBUG-71394](https://bugreports.qt.io/browse/QTBUG-71394).

## Solution

This fix injects a dynamic library into nvim-qt using DYLD_INSERT_LIBRARIES that patches macOS's text input handling through several complementary techniques:

1. Disables the macOS press-and-hold feature at multiple levels
2. Intercepts key repeat events and routes them to the proper handlers
3. Prevents infinite loops and cascading events while maintaining proper timing

## Installation

1. Compile the library:
   ```bash
   make
   ```

2. Install the library:
   ```bash
   make install
   ```

3. Add this to your ~/.zshrc:
   ```bash
   # Function to run nvim-qt with key repeat fix and message filtering
   nvim-qt() {
     DYLD_INSERT_LIBRARIES=/Users/wilson/Library/KeyRepeatFix/libKeyRepeatFix.dylib command nvim-qt "$@" 2> >(grep -v "IMKClient\|IMKInputSession\|IMKCFRunLoopWakeUpReliable\|Force processing repeat key" >&2)
   }
   ```

4. Restart your terminal or run `source ~/.zshrc`

5. Run nvim-qt as usual, and key repeat should now work properly!

The fix is entirely self-contained in the library and the shell function above. You don't need to make any other system changes, as the library automatically:

- Disables the press-and-hold accent menu popup
- Handles key repeat events properly
- Prevents infinite loop issues and recursion

## How It Works

The fix employs multiple techniques to ensure key repeat works correctly:

1. **NSTextInputContext Patching**: Intercepts the `handleEvent:` method to catch key repeat events and route them directly to the first responder.

2. **Press-and-Hold Disabling**: Disables the macOS press-and-hold feature through:
   - Application-level defaults
   - Attempted global defaults
   - Runtime patching of the NSEvent class to disable the press-and-hold behavior

3. **Rate Limiting & Recursion Prevention**: Uses state tracking to prevent:
   - Infinite loops of repeat events
   - Cascading repeat events
   - Event timing issues

4. **Event Routing**: Sends repeat events directly to the active window's first responder, bypassing Qt's broken implementation.

## Technical Details

The implemented solution:

- Uses Objective-C runtime method swizzling
- Keeps track of event state to prevent infinite loops
- Applies rate limiting to prevent overly fast repeat events
- Only processes actual key repeat events (marked with `isARepeat`)
- Targets only nvim-qt to avoid affecting other applications

## Troubleshooting

If key repeat still doesn't work:

1. Make sure you've restarted your terminal after adding the function to `.zshrc`
2. Verify that the path `/Users/wilson/Library/KeyRepeatFix/libKeyRepeatFix.dylib` is correct in your setup
3. Try increasing logging verbosity by removing the grep filters
4. Check for error messages when nvim-qt is launched

If you see an accent popup menu occasionally:
- This is fixed in the latest version by aggressively disabling press-and-hold
- If it still happens, try setting the global macOS default with: `defaults write -g ApplePressAndHoldEnabled -bool false`

## Credits

Based on insights from [QTBUG-71394](https://bugreports.qt.io/browse/QTBUG-71394) and using Objective-C runtime method swizzling technique.
