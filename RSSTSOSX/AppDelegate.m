//
//  AppDelegate.m
//  RSSTSOSX
//
//  Created by Shintaro Kaneko on 4/26/15.
//  Copyright (c) 2015 Shintaro Kaneko. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSTask *task = [[NSTask alloc] init];
    NSPipe *stdError = [NSPipe pipe];
    [task setStandardError:stdError];

    NSString *script = [[NSBundle mainBundle] pathForResource:@"rssts" ofType:@"rb"];

    [task setLaunchPath:@"/usr/bin/ruby"];
    [task setCurrentDirectoryPath:[[NSBundle mainBundle].bundlePath stringByDeletingLastPathComponent]];
    [task setArguments:@[script]];
    [task launch];
    [task waitUntilExit];

    NSData *data = [[stdError fileHandleForReading] availableData];
    if (data) {
        NSString *err = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@", err);
    }

    [task terminationStatus];
    [NSApp terminate:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

@end
