/**
 * A simple DVTiPhoneSimulatorRemoteClient framework for launching app on iOS Simulator
 *
 * Copyright (c) 2009-2015 by Appcelerator, Inc. All Rights Reserved.
 *
 * Copyright (c) 2012 The Chromium Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file. 
 * (link : http://src.chromium.org/chrome/trunk/src/testing/iossim/)
 *
 * Original Author: Landon Fuller <landonf@plausiblelabs.com>
 * Copyright (c) 2008-2011 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 *
 *
 * Headers for the DVTiPhoneSimulatorRemoteClient framework used in this tool are
 * generated by class-dump, via GYP.
 * (class-dump is available at http://www.codethecode.com/projects/class-dump/)
 *
 * See the LICENSE file for the license on the source code in this file.
 */

#import "iPhoneSimulator.h"
#import "NSString+expandPath.h"
#import "nsprintf.h"
#import <sys/types.h>
#import <sys/stat.h>
#include <dlfcn.h>
@class DTiPhoneSimulatorSystemRoot;

#pragma mark - Contants

NSString *simulatorAppId = @"com.apple.iphonesimulator";
NSString *deviceProperty = @"SimulateDevice";
NSString *deviceIphoneRetina3_5InchiOS7 = @"iPhone Retina (3.5-inch)";
NSString *deviceIphoneRetina4_0InchiOS7 = @"iPhone Retina (4-inch)";
NSString *deviceiPhoneRetine4_0InchiOS764bit = @"iPhone Retina (4-inch 64-bit)";
NSString *deviceiPadRetinaiOS764bit = @"iPad Retina (64-bit)";
NSString *deviceIpadRetinaiOS7 = @"iPad Retina";
NSString *deviceIphone = @"iPhone";
NSString *deviceIpad = @"iPad";

// The path within the developer dir of the private Simulator frameworks.
NSString *const kSimulatorFrameworkRelativePath = @"Platforms/iPhoneSimulator.platform/Developer/Library/PrivateFrameworks/DVTiPhoneSimulatorRemoteClient.framework";
NSString *const kDVTFoundationRelativePath = @"../SharedFrameworks/DVTFoundation.framework";
NSString *const kDevToolsCoreRelativePath = @"../OtherFrameworks/DevToolsCore.framework";
NSString *const kIDEiOSSupportCoreRelativePath = @"../PlugIns/IDEiOSSupportCore.ideplugin";
NSString *const kDevToolsFoundationRelativePath = @"../OtherFrameworks/DevToolsFoundation.framework";
NSString *const kSimulatorRelativePath = @"Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app";

// Xcode 6 section block
NSString *const kXcode6SimulatorRelativePath = @"../SharedFrameworks/DVTiPhoneSimulatorRemoteClient.framework";
NSString *const kXcode6CoreSimulatorRelativePath = @"Library/PrivateFrameworks/CoreSimulator.framework";
// End of Xcode 6 block.

// IDEiOSSupportCore
NSString *const kIDEWatchCompanionFeature = @"com.apple.watch.companion";

// IDEFoundation
NSString *const kIDEWatchLaunchModeKey = @"IDEWatchLaunchMode";
NSString *const kIDEWatchLaunchModeGlance = @"IDEWatchLaunchMode-Glance";
NSString *const kIDEWatchLaunchNotification = @"IDEWatchLaunchMode-Notification";
// TODO: enable launching Static or Dynamic Notification Type
NSString *const kIDEWatchLaunchNotificationTypeStatic = @"IDEWatchLaunchNotificationType-Static";
NSString *const kIDEWatchNotificationPayloadKey = @"IDEWatchNotificationPayload";

@implementation iPhoneSimulator

#pragma mark - Load Frameworks

// Loads the Simulator framework from the given developer dir.
- (void)LoadSimulatorFramework:(NSString *)developerDir
{
	// The Simulator framework depends on some of the other Xcode private
	// frameworks; manually load them first so everything can be linked up.
	NSString *dvtFoundationPath = [developerDir stringByAppendingPathComponent:kDVTFoundationRelativePath];

	NSBundle *dvtFoundationBundle =
	    [NSBundle bundleWithPath:dvtFoundationPath];
	if (![dvtFoundationBundle load]) {
		nsprintf(@"Unable to dvtFoundationBundle. Error: ");
		exit(EXIT_FAILURE);
		return;
	}

	NSString *devToolsFoundationPath = [developerDir stringByAppendingPathComponent:kDevToolsFoundationRelativePath];
	NSBundle *devToolsFoundationBundle = [NSBundle bundleWithPath:devToolsFoundationPath];
	if (![devToolsFoundationBundle load]) {
		nsprintf(@"Unable to devToolsFoundationPath. Error: ");
		return;
	}
	// Prime DVTPlatform.
	NSError *error = nil;
	Class DVTPlatformClass = [self FindClassByName:@"DVTPlatform"];
	if (![DVTPlatformClass loadAllPlatformsReturningError:&error]) {
		nsprintf(@"Unable to loadAllPlatformsReturningError. Error: %@", [error localizedDescription]);
		return;
	}
	//Xcode 5 and below.
	NSString *simBundlePath = [developerDir stringByAppendingPathComponent:kSimulatorFrameworkRelativePath];
	if (![[NSFileManager defaultManager] fileExistsAtPath:simBundlePath]) {
		simBundlePath = [developerDir stringByAppendingPathComponent:kXcode6SimulatorRelativePath];
		_isXcode6 = YES;
		NSString *coreSimBundlePath = [developerDir stringByAppendingPathComponent:kXcode6CoreSimulatorRelativePath];
		NSBundle *coreBundle = [NSBundle bundleWithPath:coreSimBundlePath];
		if (![coreBundle load]) {
			nsprintf(@"Unable to load core simulator framework");
			exit(EXIT_FAILURE);
		}
	}
	NSBundle *simBundle = [NSBundle bundleWithPath:simBundlePath];
	if (![simBundle load]) {
		nsprintf(@"Unable to load simulator framework");
		exit(EXIT_FAILURE);
	}

	NSString *devToolsCorePath = [developerDir stringByAppendingPathComponent:kDevToolsCoreRelativePath];
	NSBundle *devToolsCoreBundle = [NSBundle bundleWithPath:devToolsCorePath];
	if (![devToolsCoreBundle load]) {
		nsprintf(@"Unable to devToolsCoreBundle. Error: ");
		exit(EXIT_FAILURE);
		return;
	}

	NSString *dvtiPhoneSimulatorPath = [developerDir stringByAppendingPathComponent:kIDEiOSSupportCoreRelativePath];
	NSBundle *dvtiPhoneSimulatorBundle = [NSBundle bundleWithPath:dvtiPhoneSimulatorPath];
	if (![dvtiPhoneSimulatorBundle load]) {
		nsprintf(@"Unable to dvtiPhoneSimulatorBundle. Error: ");
		exit(EXIT_FAILURE);
		return;
	}

	return;
}

#pragma mark - Utilities

// Helper to find a class by name and die if it isn't found.
- (Class)FindClassByName:(NSString *)nameOfClass
{
	Class theClass = NSClassFromString(nameOfClass);
	if (!theClass) {
		nsfprintf(stderr, @"Failed to find class %@ at runtime.", nameOfClass);
		exit(EXIT_FAILURE);
	}
	return theClass;
}

// Finds the developer dir via xcode-select or the DEVELOPER_DIR environment
// variable.
NSString *FindDeveloperDir()
{
	// Check the env first.
	NSDictionary *env = [[NSProcessInfo processInfo] environment];
	NSString *developerDir = [env objectForKey:@"DEVELOPER_DIR"];
	if ([developerDir length] > 0)
		return developerDir;

	// Go look for it via xcode-select.
	NSTask *xcodeSelectTask = [[[NSTask alloc] init] autorelease];
	[xcodeSelectTask setLaunchPath:@"/usr/bin/xcode-select"];
	[xcodeSelectTask setArguments:[NSArray arrayWithObject:@"-print-path"]];

	NSPipe *outputPipe = [NSPipe pipe];
	[xcodeSelectTask setStandardOutput:outputPipe];
	NSFileHandle *outputFile = [outputPipe fileHandleForReading];

	[xcodeSelectTask launch];
	NSData *outputData = [outputFile readDataToEndOfFile];
	[xcodeSelectTask terminate];

	NSString *output =
	    [[[NSString alloc] initWithData:outputData
	                           encoding:NSUTF8StringEncoding] autorelease];
	output = [output stringByTrimmingCharactersInSet:
	                     [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([output length] == 0)
		output = nil;
	return output;
}

- (void)printUsage
{
	fprintf(stderr, "Usage: ios-sim <command> <options> [--args ...]\n");
	fprintf(stderr, "\n");
	fprintf(stderr, "Commands:\n");
	fprintf(stderr, "  show-sdks                       List the available iOS SDK versions\n");
	fprintf(stderr, "  launch <application path>       Launch an application on the iOS Simulator specified by the path\n");
	fprintf(stderr, "  show-simulators                 List available simulators. (Xcode 6+)\n");
	fprintf(stderr, "  show-installed-apps             List installed apps\n");
	fprintf(stderr, "\n");

	fprintf(stderr, "Options:\n");
	fprintf(stderr, "  --xcode-dir <custom DEVELOPER_DIR>  Set the xcode to be used by ios-sim. (Should be passed in as the First argument. Defaults to `xcode-select --print-path` location\n");

	fprintf(stderr, "  --version                       Print the version of ios-sim\n");
	fprintf(stderr, "  --help                          Show this help text\n");
	fprintf(stderr, "  --verbose                       Set the output level to verbose\n");
	fprintf(stderr, "  --exit                          Exit after startup\n");
	fprintf(stderr, "  --launch-watch-app              Launch the installed application's watch app instead of the main app installed \n");
	fprintf(stderr, "  --external-display-type <screen type>  The type of the external screen [watch-regular (default), watch-compact] \n");
	fprintf(stderr, "  --watch-launch-mode <mode>      The mode of the watch app to launch [main (default), glance, notification] \n");
	fprintf(stderr, "  --watch-notification-payload <path to payload>  The path to the payload that will be delivered in notification mode \n");
	fprintf(stderr, "  --launch-bundle-id <bundle id>  The bundle id to be launch instead of the main app installed\n");
	fprintf(stderr, "  --retina                        Start as a retina device(DEPRECATED)\n");
	fprintf(stderr, "  --tall                          Start the tall version of the iPhone simulator(4-inch simulator), to be used in conjuction with retina flag(DEPRECATED)\n");
	fprintf(stderr, "  --sim-64bit                     Start 64 bit version of iOS 7 simulator(DEPRECATED))\n");
	fprintf(stderr, "  --timeout                       Set the timeout value for a new session from the Simulator. Default: 30 seconds \n");
	fprintf(stderr, "  --sdk <sdkversion>              The iOS SDK version to run the application on (defaults to the latest)\n");
	fprintf(stderr, "  --udid <unique device ID>       The UDID of the simulator being launched. Run `ios-sim listSimulators` to get the list of simulators.\n");
	fprintf(stderr, "  --family <device family>        The device type that should be simulated (defaults to `iphone')\n");
	fprintf(stderr, "  --uuid <uuid>                   A UUID identifying the session (is that correct?)\n");
	fprintf(stderr, "  --env <environment file path>   A plist file containing environment key-value pairs that should be set\n");
	fprintf(stderr, "  --setenv NAME=VALUE             Set an environment variable\n");
	fprintf(stderr, "  --stdout <stdout file path>     The path where stdout of the simulator will be redirected to (defaults to stdout of ios-sim)\n");
	fprintf(stderr, "  --stderr <stderr file path>     The path where stderr of the simulator will be redirected to (defaults to stderr of ios-sim)\n");
	fprintf(stderr, "  --args <...>                    All following arguments will be passed on to the application\n");
}

- (NSString *)findDeviceType:(NSString *)family
{
	NSString *devicePropertyValue;

	if (_retinaDevice) {
		if (_verbose) {
			nsprintf(@"using retina");
		}
		if ([family isEqualToString:@"ipad"]) {
			if (_sim_64bit) {
				if (_verbose) {
					nsprintf(@"using retina ipad ios 7 64-bit");
				}
				devicePropertyValue = deviceiPadRetinaiOS764bit;
			} else {
				if (_verbose) {
					nsprintf(@"using retina ipad ios 7");
				}
				devicePropertyValue = deviceIpadRetinaiOS7;
			}

		} else {
			if (_tallDevice) {
				if (_sim_64bit) {
					if (_verbose) {
						nsprintf(@"using iphone retina tall ios 7 64 bit");
					}
					devicePropertyValue = deviceiPhoneRetine4_0InchiOS764bit;
				} else {
					if (_verbose) {
						nsprintf(@"using iphone retina tall ios 7");
					}
					devicePropertyValue = deviceIphoneRetina4_0InchiOS7;
				}
			} else {
				if (_verbose) {
					nsprintf(@"using retina iphone retina ios 7");
				}
				devicePropertyValue = deviceIphoneRetina3_5InchiOS7;
			}
		}
	} else {
		if ([family isEqualToString:@"ipad"]) {
			devicePropertyValue = deviceIpad;
		} else {
			devicePropertyValue = deviceIphone;
		}
	}
	if (_verbose) {
		nsprintf(@"Simulated Device Name :: %@", devicePropertyValue);
	}
	return devicePropertyValue;
}

- (SimDevice *)FindDeviceToBeSimulated:(NSString *)udid
{
	Class simDeviceSetClass = [self FindClassByName:@"SimDeviceSet"];
	NSArray *devices = [[simDeviceSetClass defaultSet] availableDevices];

	for (id device in devices) {
		if (_verbose) {
			nsprintf(@"Comparing %@ == %@", [device UDID].UUIDString, udid);
		}
		if ([[device UDID].UUIDString isEqualToString:udid]) {
			return device;
		}
	}
	return nil;
}

- (NSString *)jsonFromObject:(id)obj
{
	NSError *error = nil;
	NSData *JSONData = [NSJSONSerialization dataWithJSONObject:obj
	                                                   options:NSJSONWritingPrettyPrinted
	                                                     error:&error];
	if (error) {
		nsprintf(@"Error converting object to json: %@", error);
		exit(EXIT_FAILURE);
	}
	NSString *str = (NSString *)CFStringCreateWithFormatAndArguments(NULL, NULL, (CFStringRef)[[[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding] autorelease], nil);
	return [str autorelease];
}

- (NSDictionary *)launchOptions
{
	if (!_launchOptions) {
		_launchOptions = [NSMutableDictionary dictionary];
	}
	if (_watchLaunchMode) {
		if ([_watchLaunchMode isEqualToString:@"glance"]) {
			_launchOptions[kIDEWatchLaunchModeKey] = kIDEWatchLaunchModeGlance;
		} else if ([_watchLaunchMode isEqualToString:@"notification"]) {
			_launchOptions[kIDEWatchLaunchModeKey] = kIDEWatchLaunchNotification;
			if (!_watchNotificationPayload) {
				nsfprintf(stderr, @"--watch-notification-payload is required");
				exit(EXIT_FAILURE);
			}
			_launchOptions[kIDEWatchNotificationPayloadKey] = _watchNotificationPayload;
		}
	}
	return [[_launchOptions copy] autorelease];
}

- (NSDictionary *)notificationPayloadFromFile:(NSString *)path
{
	if (![[NSFileManager alloc] fileExistsAtPath:path]) {
		nsfprintf(stderr, @"Payload file not found at: %@", path);
		exit(EXIT_FAILURE);
	}
	NSData *data = [NSData dataWithContentsOfFile:path];
	NSError *error = nil;
	NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
	if (error) {
		nsfprintf(stderr, @"Error parsing notification payload file: %@", error);
		exit(EXIT_FAILURE);
	}
	return json;
}

#pragma mark - Actions

- (int)showSDKs
{
	Class systemRootClass = [self FindClassByName:@"DTiPhoneSimulatorSystemRoot"];
	if (_isXcode6) {
		Class simRunTimeClass = [self FindClassByName:@"SimRuntime"];
		id supportedRuntimes = [simRunTimeClass supportedRuntimes];
		printf("Available iOS SDK's\n");
		for (id runtime in supportedRuntimes) {
			nsfprintf(stderr, @" %@", [runtime name]);
		}
	} else {
		NSArray *roots = [systemRootClass knownRoots];
		nsprintf(@"Simulator SDK Roots:");
		for (DTiPhoneSimulatorSystemRoot *root in roots) {
			nsfprintf(stderr, @"'%@' (%@)\n\t%@", [root sdkDisplayName], [root sdkVersion], [root sdkRootPath]);
		}
	}
	return EXIT_SUCCESS;
}

- (int)showSimulators
{
	if (_isXcode6) {
		Class simDeviceSetClass = [self FindClassByName:@"SimDeviceSet"];
		NSArray *devices = [[simDeviceSetClass defaultSet] availableDevices];
		NSMutableArray *deviceArray = [NSMutableArray arrayWithCapacity:[devices count]];
		for (SimDevice *device in devices) {
			[deviceArray addObject:@{
				@"name" : [device name],
				@"version" : [device runtime].versionString,
				@"udid" : [device UDID].UUIDString,
				@"state" : [device stateString],
				@"logpath" : [device logPath],
				@"deviceType" : [device deviceType].name,
				@"type" : [device deviceType].productFamily,
				@"supportsWatch" : [NSNumber numberWithBool:[device supportsFeature:kIDEWatchCompanionFeature]]
			}];
		}
		if ([deviceArray count] > 0) {
			NSError *error = nil;
			NSData *JSONData = [NSJSONSerialization dataWithJSONObject:deviceArray
			                                                   options:NSJSONWritingPrettyPrinted
			                                                     error:&error];
			NSString *str = (NSString *)CFStringCreateWithFormatAndArguments(NULL, NULL, (CFStringRef)[[[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding] autorelease], nil);
			fprintf(stdout, "%s", [str UTF8String]);
			[str release];
		}
	} else {
		fprintf(stdout, "null");
	}
	return EXIT_SUCCESS;
}

- (int)showInstalledApps
{
	if (!_device) {
		nsprintf(@"Device not found");
		return EXIT_FAILURE;
	}

	NSError *error = nil;
	NSDictionary *installedApps = [_device installedAppsWithError:&error];
	if (error) {
		nsprintf(@"Error listing installed apps: %@", error);
		return EXIT_FAILURE;
	}

	fprintf(stdout, "%s", [[self jsonFromObject:installedApps] UTF8String]);
	return EXIT_SUCCESS;
}

- (void)installApp
{
	if (_verbose) {
		nsprintf(@"Installing app: %@", _appPath);
	}
	DVTiPhoneSimulator *sim = [[self FindClassByName:@"DVTiPhoneSimulator"] simulatorWithDevice:_device];
	DVTFilePath *path = [[self FindClassByName:@"DVTFilePath"] filePathForPathString:_appPath];
	DVTFuture *install = [sim installApplicationAtPath:path];
	[install waitUntilFinished];
	if (install.error) {
		nsprintf(@"Error installing app: %@", install.error);
		exit(EXIT_FAILURE);
	} else {
		nsprintf(@"App installed successfully");
		[self launchApp];
	}
}

- (void)launchApp
{
	if (_verbose) {
		nsprintf(@"Launching app: %@", _appPath);
	}
	DVTiPhoneSimulator *sim = [[self FindClassByName:@"DVTiPhoneSimulator"] simulatorWithDevice:_device];
	if (_launchWatchApp) {
		if (![_device supportsFeature:kIDEWatchCompanionFeature]) {
			nsprintf(@"The selected device `%@`, does not support Watch Apps.", _device.name);
			exit(EXIT_FAILURE);
		}
		if (_verbose) {
			nsprintf(@"Launching watch app for companion with bundle id: %@", _appBundleID);
		}
		__block BOOL complete = NO;
		[sim launchWatchAppForCompanionIdentifier:_appBundleID options:[self launchOptions] completionblock:^(id error, id something) {
            if (error) {
                nsprintf(@"Error launching app: %@", error);
                exit(EXIT_FAILURE);
            } else {
                nsprintf(@"App launched successfully");
            }
            complete = YES;
		}];
		// Wait untill the launch completes to move on
		while (!complete) {
			[NSThread sleepForTimeInterval:0.05];
		}
		return;
	} else {
		_bundleID = (_bundleID) ? _bundleID : _appBundleID;
		if (_verbose) {
			nsprintf(@"Launching app with bundle id: %@", _bundleID);
		}
		DVTFuture *launch = [sim launchApplicationWithBundleIdentifier:_bundleID withArguments:_launchArgs environment:_environment options:[self launchOptions]];
		[launch waitUntilFinished];
		if (launch.error) {
			nsprintf(@"Error launching app: %@", launch.error);
			exit(EXIT_FAILURE);
		} else {
			nsprintf(@"App launched successfully");
		}
		return;
	}
}

#pragma mark - DTiPhoneSimulatorSessionDelegate

- (void)session:(DTiPhoneSimulatorSession *)session didEndWithError:(NSError *)error
{
	if (_verbose) {
		nsprintf(@"Session did end with error %@", error);
	}

	if (_stderrFileHandle != nil) {
		NSString *stderrPath = [[session sessionConfig] simulatedApplicationStdErrPath];
		[self removeStdioFIFO:_stderrFileHandle atPath:stderrPath];
	}

	if (_stdoutFileHandle != nil) {
		NSString *stdoutPath = [[session sessionConfig] simulatedApplicationStdOutPath];
		[self removeStdioFIFO:_stdoutFileHandle atPath:stdoutPath];
	}

	if (error != nil) {
		exit(EXIT_FAILURE);
	}

	exit(EXIT_SUCCESS);
}

- (void)session:(DTiPhoneSimulatorSession *)session didStart:(BOOL)started withError:(NSError *)error
{
	if (_startOnly && session) {
		nsprintf(@"Simulator started (no session)");
		exit(EXIT_SUCCESS);
	}

	if (started) {
		if (_verbose) {
			nsprintf(@"Simulator started (with session)");
		}

		if (_appPath) {
			[self installApp];
		} else if (_showInstalledApps) {
			exit([self showInstalledApps]);
		} else {
			[self launchApp];
		}

		if (_exitOnStartup) {
			exit(EXIT_SUCCESS);
		}
	} else {
		nsprintf(@"Session could not be started: %@", error);
		exit(EXIT_FAILURE);
	}
}

#pragma mark - STDIO

- (void)stdioDataIsAvailable:(NSNotification *)notification
{
	NSData *data = [[notification userInfo] valueForKey:NSFileHandleNotificationDataItem];
	NSString *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	if (!_alreadyPrintedData) {
		if ([str length] == 0) {
			return;
		} else {
			_alreadyPrintedData = YES;
		}
	}
	if ([str length] > 0) {
		fprintf(stdout, "%s", [str UTF8String]);
		fflush(stdout);
	}
}

- (void)createStdioFIFO:(NSFileHandle **)fileHandle ofType:(NSString *)type atPath:(NSString **)path
{
	*path = [NSString stringWithFormat:@"%@/ios-sim-%@-pipe-%d", NSTemporaryDirectory(), type, (int)time(NULL)];
	if (mkfifo([*path UTF8String], S_IRUSR | S_IWUSR) == -1) {
		nsprintf(@"Unable to create %@ named pipe `%@'", type, *path);
		exit(EXIT_FAILURE);
	} else {
		if (_verbose) {
			nsprintf(@"Creating named pipe at `%@'", *path);
		}
		int fd = open([*path UTF8String], O_RDONLY | O_NDELAY);
		*fileHandle = [[[NSFileHandle alloc] initWithFileDescriptor:fd] retain];
		[*fileHandle readInBackgroundAndNotify];
		[[NSNotificationCenter defaultCenter] addObserver:self
		                                         selector:@selector(stdioDataIsAvailable:)
		                                             name:NSFileHandleReadCompletionNotification
		                                           object:*fileHandle];
	}
}

- (void)removeStdioFIFO:(NSFileHandle *)fileHandle atPath:(NSString *)path
{
	if (_verbose) {
		nsprintf(@"Removing named pipe at `%@'", path);
	}
	[fileHandle closeFile];
	[fileHandle release];
	if (![[NSFileManager defaultManager] removeItemAtPath:path error:NULL]) {
		nsprintf(@"Unable to remove named pipe `%@'", path);
	}
}

#pragma mark - Launch Simulator

- (int)launchSimulatorFamily:(NSString *)family
                 withTimeout:(NSTimeInterval)timeout
                        udid:(NSString *)udid
                        uuid:(NSString *)uuid
                  stdoutPath:(NSString *)stdoutPath
                  stderrPath:(NSString *)stderrPath
{
	DTiPhoneSimulatorSessionConfig *config;
	DTiPhoneSimulatorSession *session;
	NSError *error = nil;
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	if (!_startOnly && !_showInstalledApps) {
		if (![fileManager fileExistsAtPath:_appPath]) {
			nsprintf(@"Could not load application specification for %s", _appPath);
			exit(EXIT_FAILURE);
		}
		NSBundle *appBundle = [NSBundle bundleWithPath:_appPath];
		_appBundleID = appBundle.bundleIdentifier;
		if (_verbose) {
			nsprintf(@"Found bundleid: %@ for app at: %@", _appBundleID, _appPath);
		}
	}

	if (_verbose) {
		nsprintf(@"SDK Root: %@", _sdkRoot);
		for (id key in _environment) {
			nsprintf(@"Env: %@ = %@", key, [_environment objectForKey:key]);
		}
	}

	/* Set up the session configuration */
	config = [[[[self FindClassByName:@"DTiPhoneSimulatorSessionConfig"] alloc] init] autorelease];

	/* Set external display type */
	if (_launchWatchApp) {
		// Default to Watch Regular
		NSInteger displayType = DTiPhoneSimulatorExternalDisplayTypeWatchRegular;
		if (_externalDisplayType) {
			if ([[_externalDisplayType lowercaseString] isEqualToString:@"watch-compact"]) {
				displayType = DTiPhoneSimulatorExternalDisplayTypeWatchCompact;
			} else if ([[_externalDisplayType lowercaseString] isEqualToString:@"carplay"]) {
				displayType = DTiPhoneSimulatorExternalDisplayTypeCarPlay;
			}
		}
		[config setExternalDisplayType:displayType];
	}

	[config setSimulatedSystemRoot:_sdkRoot];
	[config setSimulatedApplicationShouldWaitForDebugger:NO];

	if (stderrPath) {
		_stderrFileHandle = nil;
	} else if (!_exitOnStartup) {
		[self createStdioFIFO:&_stderrFileHandle ofType:@"stderr" atPath:&stderrPath];
	}
	[config setSimulatedApplicationStdErrPath:stderrPath];

	if (stdoutPath) {
		_stdoutFileHandle = nil;
	} else if (!_exitOnStartup) {
		[self createStdioFIFO:&_stdoutFileHandle ofType:@"stdout" atPath:&stdoutPath];
	}
	[config setSimulatedApplicationStdOutPath:stdoutPath];

	[config setLocalizedClientName:@"ios-sim"];

	// this was introduced in 3.2 of SDK
	if ([config respondsToSelector:@selector(setSimulatedDeviceFamily:)]) {
		if (family == nil) {
			family = @"iphone";
		}

		if (_verbose) {
			nsprintf(@"using device family %@", family);
		}

		if ([family isEqualToString:@"ipad"]) {
			[config setSimulatedDeviceFamily:[NSNumber numberWithInt:2]];
		} else {
			[config setSimulatedDeviceFamily:[NSNumber numberWithInt:1]];
		}
	}

	//Xcode 6
	if (_isXcode6) {
		if (((NSNull *)udid == [NSNull null]) ||
		    ([udid length] == 0) ||
		    (udid == nil) ||
		    ([[udid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0)) {
			nsprintf(@"To launch simulator on Xcode 6 please provide a valid simulator UDID. Run `ios-sim show-simulators` to get a list of all Simulators.");
			exit(EXIT_FAILURE);
		}
		_device = [self FindDeviceToBeSimulated:udid];
		if (_device == nil) {
			nsprintf(@"Unable to locate the Simulator with the provided udid : %@", udid);
			exit(EXIT_FAILURE);
		}

		config.device = _device;
		if (_verbose) {
			nsprintf(@"set device to : %@", _device.name);
		}
	} else {
		/* Figure out the type of simulator we need to open up.*/
		NSString *deviceInfoName = [self findDeviceType:family];
		[config setSimulatedDeviceInfoName:deviceInfoName];
	}

	/* Start the session */
	session = [[[[self FindClassByName:@"DTiPhoneSimulatorSession"] alloc] init] autorelease];
	// Set DTiPhoneSimulatorSessionDelegate
	[session setDelegate:self];
	if (uuid != nil) {
		[session performSelector:@selector(setUuid:) withObject:uuid];
	}
	timeout = MIN(500, MAX(90, timeout));

	if (![session requestStartWithConfig:config timeout:timeout error:&error]) {
		nsprintf(@"Could not start simulator session:");
		exit(EXIT_FAILURE);
	}

	return EXIT_SUCCESS;
}

/**
 * Execute 'main'
 */
- (void)runWithArgc:(int)argc argv:(char **)argv
{
	if (argc < 2) {
		[self printUsage];
		exit(EXIT_FAILURE);
	}

	/* Initializing variables*/
	_exitOnStartup = NO;
	_alreadyPrintedData = NO;
	_retinaDevice = NO;
	_tallDevice = NO;
	_sim_64bit = NO;
	_launchWatchApp = NO;
	_startOnly = strcmp(argv[1], "start") == 0;
	_launchFlag = strcmp(argv[1], "launch") == 0;
	_showInstalledApps = strcmp(argv[1], "show-installed-apps") == 0;
	NSTimeInterval timeout = 90;

	NSString *developerDir = FindDeveloperDir();
	if (!developerDir) {
		nsprintf(@"Unable to find developer directory.");
		exit(EXIT_FAILURE);
	}

	int numOfArgs;
	if (_startOnly || _showInstalledApps) {
		numOfArgs = 2;
	} else if (argc > 2) {
		numOfArgs = 3;
		_appPath = [[NSString stringWithUTF8String:argv[2]] expandPath];
	}

	int i = numOfArgs;

	// Check for old args and exit
	if (strcmp(argv[1], "showallsimulators") == 0) {
		fprintf(stderr, "`showallsimulators` has been removed. Use `show-simulators`.");
		exit(EXIT_FAILURE);
	}
	if (strcmp(argv[1], "showsdks") == 0) {
		fprintf(stderr, "`showsdks` has been removed. Use `show-sdks`.");
		exit(EXIT_FAILURE);
	}
	// End check on old args

	// Parse args
	if (strcmp(argv[1], "show-sdks") == 0) {
		[self LoadSimulatorFramework:developerDir];
		exit([self showSDKs]);
	} else if (strcmp(argv[1], "show-simulators") == 0) {
		for (i = 2; i < argc; i++) {
			if (strcmp(argv[i], "--xcode-dir") == 0) {
				if (++i < argc) {
					developerDir = [NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding];
				}
			}
		}
		[self LoadSimulatorFramework:developerDir];
		exit([self showSimulators]);
	} else if (_launchFlag || _startOnly || _showInstalledApps) {
		if (_launchFlag && argc < 3) {
			fprintf(stderr, "Missing application path argument\n");
			[self printUsage];
			exit(EXIT_FAILURE);
		}

		NSString *family = nil;
		NSString *uuid = nil;
		NSString *stdoutPath = nil;
		NSString *stderrPath = nil;
		NSString *udid = nil;
		_environment = [NSMutableDictionary dictionary];
		for (; i < argc; i++) {
			if (strcmp(argv[i], "--version") == 0) {
				printf("%s\n", IOS_SIM_VERSION);
				exit(EXIT_SUCCESS);
			} else if (strcmp(argv[i], "--help") == 0) {
				[self printUsage];
				exit(EXIT_SUCCESS);
			} else if (strcmp(argv[i], "--verbose") == 0) {
				_verbose = YES;
			} else if (strcmp(argv[i], "--exit") == 0) {
				_exitOnStartup = YES;
			} else if (strcmp(argv[i], "--sdk") == 0) {
				i++;
				[self LoadSimulatorFramework:developerDir];
				NSString *ver = [NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding];
				Class systemRootClass = [self FindClassByName:@"DTiPhoneSimulatorSystemRoot"];
				NSArray *roots = [systemRootClass knownRoots];
				for (DTiPhoneSimulatorSystemRoot *root in roots) {
					NSString *v = [root sdkVersion];
					if ([v isEqualToString:ver]) {
						_sdkRoot = root;
						break;
					}
				}
				if (_sdkRoot == nil) {
					fprintf(stderr, "Unknown or unsupported SDK version: %s\n", argv[i]);
					[self showSDKs];
					exit(EXIT_FAILURE);
				}
			} else if (strcmp(argv[i], "--family") == 0) {
				i++;
				family = [NSString stringWithUTF8String:argv[i]];
			} else if (strcmp(argv[i], "--uuid") == 0) {
				i++;
				uuid = [NSString stringWithUTF8String:argv[i]];
			} else if (strcmp(argv[i], "--setenv") == 0) {
				i++;
				NSArray *parts = [[NSString stringWithUTF8String:argv[i]] componentsSeparatedByString:@"="];
				[_environment setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
			} else if (strcmp(argv[i], "--env") == 0) {
				i++;
				NSString *envFilePath = [[NSString stringWithUTF8String:argv[i]] expandPath];
				_environment = [NSMutableDictionary dictionaryWithContentsOfFile:envFilePath];
				if (!_environment) {
					fprintf(stderr, "Could not read environment from file: %s\n", argv[i]);
					[self printUsage];
					exit(EXIT_FAILURE);
				}
			} else if (strcmp(argv[i], "--stdout") == 0) {
				i++;
				stdoutPath = [[NSString stringWithUTF8String:argv[i]] expandPath];
				NSLog(@"stdoutPath: %@", stdoutPath);
			} else if (strcmp(argv[i], "--stderr") == 0) {
				i++;
				stderrPath = [[NSString stringWithUTF8String:argv[i]] expandPath];
				NSLog(@"stderrPath: %@", stderrPath);
			} else if (strcmp(argv[i], "--args") == 0) {
				i++;
				break;
			} else if (strcmp(argv[i], "--launch-watch-app") == 0) {
				_launchWatchApp = YES;
			} else if (strcmp(argv[i], "--watch-launch-mode") == 0) {
				i++;
				_watchLaunchMode = [[NSString stringWithUTF8String:argv[i]] lowercaseString];
			} else if (strcmp(argv[i], "--watch-notification-payload") == 0) {
				i++;
				NSString *path = [[NSString stringWithUTF8String:argv[i]] expandPath];
				_watchNotificationPayload = [self notificationPayloadFromFile:path];
			} else if (strcmp(argv[i], "--launch-bundle-id") == 0) {
				i++;
				_bundleID = [NSString stringWithUTF8String:argv[i]];
			} else if (strcmp(argv[i], "--external-display-type") == 0) {
				i++;
				_externalDisplayType = [[NSString stringWithUTF8String:argv[i]] lowercaseString];
			} else if (strcmp(argv[i], "--retina") == 0) {
				_retinaDevice = YES;
			} else if (strcmp(argv[i], "--tall") == 0) {
				_tallDevice = YES;
			} else if (strcmp(argv[i], "--xcode-dir") == 0) {
				i++;
				developerDir = [NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding];
			} else if (strcmp(argv[i], "--sim-64bit") == 0) {
				_sim_64bit = YES;
			} else if (strcmp(argv[i], "--timeout") == 0) {
				i++;
				timeout = [[NSString stringWithUTF8String:argv[i]] doubleValue];
			} else if (strcmp(argv[i], "--udid") == 0) {
				i++;
				udid = [NSString stringWithUTF8String:argv[i]];
			} else {
				fprintf(stderr, "unrecognized argument:%s\n", argv[i]);
				[self printUsage];
				exit(EXIT_FAILURE);
			}
		}

		i = MIN(argc, i);
		_launchArgs = [NSMutableArray arrayWithCapacity:(argc - i)];
		for (; i < argc; i++) {
			[_launchArgs addObject:[NSString stringWithUTF8String:argv[i]]];
		}

		if (_sdkRoot == nil) {
			[self LoadSimulatorFramework:developerDir];
			Class systemRootClass = [self FindClassByName:@"DTiPhoneSimulatorSystemRoot"];
			_sdkRoot = [systemRootClass defaultRoot];
		}

		/* Don't exit, adds to runloop */
		[self launchSimulatorFamily:family
		                withTimeout:timeout
		                       udid:udid
		                       uuid:uuid
		                 stdoutPath:stdoutPath
		                 stderrPath:stderrPath];
	} else {
		if (argc == 2 && strcmp(argv[1], "--help") == 0) {
			[self printUsage];
			exit(EXIT_SUCCESS);
		} else if (argc == 2 && strcmp(argv[1], "--version") == 0) {
			printf("%s\n", IOS_SIM_VERSION);
			exit(EXIT_SUCCESS);
		} else {
			fprintf(stderr, "Unknown command\n");
			[self printUsage];
			exit(EXIT_FAILURE);
		}
	}
}

@end
