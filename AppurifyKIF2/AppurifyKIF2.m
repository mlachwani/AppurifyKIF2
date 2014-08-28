//
//  AppurifyKIF2.m
//  AppurifyKIF2
//
//  Created by Appurify MAC-2 on 9/23/13.
//  Copyright (c) 2013 Appurify MAC-2. All rights reserved.
//

#import "AppurifyKIF2.h"
#import <dlfcn.h>

@implementation AppurifyKIF2

static AppurifyKIF2 *sharedKIF2;

-(void) callAfterSixtySecond:(NSTimer*) t
{

    NSLog(@"com.apple.AppSupport: %@", [[NSBundle bundleWithIdentifier:@"com.apple.AppSupport"] executablePath]);

    void *appSupportLibrary = dlopen([[[NSBundle bundleWithIdentifier:@"com.apple.AppSupport"] executablePath] fileSystemRepresentation], RTLD_LAZY);
    CFStringRef (*copySharedResourcesPreferencesDomainForDomain)(CFStringRef domain) = dlsym(appSupportLibrary, "CPCopySharedResourcesPreferencesDomainForDomain");
    if (copySharedResourcesPreferencesDomainForDomain)
    {
        CFStringRef accessibilityDomain = copySharedResourcesPreferencesDomainForDomain(CFSTR("com.apple.Accessibility"));
    
        if (accessibilityDomain)
        {
            CFPreferencesSetValue(CFSTR("ApplicationAccessibilityEnabled"), kCFBooleanTrue, accessibilityDomain, kCFPreferencesAnyUser, kCFPreferencesAnyHost);
            CFRelease(accessibilityDomain);
        
            NSLog(@"Accessibility Enabled");
        
        }
        else {
            NSLog(@"Error loading Accessibility");
        }
    }


    NSLog(@"Did finish launching, environment is %@", [[NSProcessInfo processInfo] environment]);

    //
    // Hard coded or put in [[NSProcessInfo processInfo] environment][@"XCInjectBundle"];
    //
    NSString *docsDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/"];

    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:docsDir];
    NSString *file;
    NSString *bundlePath;

    while (file = [dirEnum nextObject]) {
        if ([[file pathExtension] isEqualToString: @"octest"]) {
            bundlePath = [docsDir stringByAppendingString:@"/"];
            bundlePath = [bundlePath stringByAppendingString:file];
        }
    }

    //
    // Pre load the bundle
    //
    NSLog(@"PreLoading %@", bundlePath);

    if (bundlePath) {
        BOOL isDirectory = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:bundlePath isDirectory:&isDirectory] && isDirectory) {
            NSString *basename = [[bundlePath lastPathComponent] stringByDeletingPathExtension];
            bundlePath = [bundlePath stringByAppendingPathComponent:basename];
        }
        NSLog(@"Loading %@", bundlePath);
        void *loadedBundle = dlopen([bundlePath fileSystemRepresentation], RTLD_NOW);
        assert(loadedBundle);
    }

    NSBundle* bundle = [NSBundle bundleWithPath:@"/Developer/Library/Frameworks/SenTestingKit.framework"];
    if (bundle == nil) {
        //
        // do nothing
        //
    }
    else {
        [bundle load];
        [[NSClassFromString(@"SenTestSuite") defaultTestSuite] run];
    }

}

-(void) load
{
    [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self
                                   selector: @selector(callAfterSixtySecond:) userInfo: nil repeats: NO];
}

@end
