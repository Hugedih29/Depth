#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <substrate.h>
#import <dlfcn.h>
#import <string.h>

// No public iOS 16 key for this device gate has been confirmed. This hook is
// deliberately narrow and only responds to a string key explicitly mentioning
// both wallpaper/Lock Screen and depth.
typedef Boolean (*MGGetBoolAnswerFunction)(CFStringRef key);
static MGGetBoolAnswerFunction originalMGGetBoolAnswer;

static BOOL NativeDepthIsEnabled(void) {
    return CFPreferencesGetAppBooleanValue(CFSTR("Enabled"), CFSTR("com.codex.nativedepthunlock"), NULL);
}

static Boolean NativeDepthMGGetBoolAnswer(CFStringRef key) {
    if (NativeDepthIsEnabled() && key && CFGetTypeID(key) == CFStringGetTypeID()) {
        char name[256] = {0};
        if (CFStringGetCString(key, name, sizeof(name), kCFStringEncodingUTF8)) {
            for (char *cursor = name; *cursor; cursor++) {
                if (*cursor >= 'A' && *cursor <= 'Z') *cursor = (char)(*cursor - 'A' + 'a');
            }
            BOOL mentionsDepth = strstr(name, "depth") != NULL;
            BOOL mentionsWallpaper = strstr(name, "wallpaper") != NULL || strstr(name, "lockscreen") != NULL || strstr(name, "lock-screen") != NULL;
            if (mentionsDepth && mentionsWallpaper) {
                NSLog(@"[NativeDepthUnlock] Returning YES for capability query '%s'. Native rendering still depends on iOS support.", name);
                return true;
            }
        }
    }
    return originalMGGetBoolAnswer ? originalMGGetBoolAnswer(key) : false;
}

static void NativeDepthPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name,
                                          const void *object, CFDictionaryRef userInfo) {
    CFPreferencesAppSynchronize(CFSTR("com.codex.nativedepthunlock"));
}

%ctor {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
                                    NativeDepthPreferencesChanged,
                                    CFSTR("com.codex.nativedepthunlock/settingschanged"), NULL,
                                    CFNotificationSuspensionBehaviorCoalesce);
    // MobileGestalt is normally already present in these Apple processes, but
    // opening it explicitly also resolves the symbol reliably on iOS 16.
    void *handle = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_LAZY);
    void *symbol = handle ? dlsym(handle, "MGGetBoolAnswer") : dlsym(RTLD_DEFAULT, "MGGetBoolAnswer");
    if (symbol) {
        MSHookFunction(symbol, (void *)NativeDepthMGGetBoolAnswer, (void **)&originalMGGetBoolAnswer);
        NSLog(@"[NativeDepthUnlock] Capability probe installed; enabled=%@", NativeDepthIsEnabled() ? @"yes" : @"no");
    } else {
        NSLog(@"[NativeDepthUnlock] MGGetBoolAnswer was not found in this process.");
    }
}
