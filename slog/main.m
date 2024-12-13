//
//  main.m
//  slog
//
//  Created by Ethan Arbuckle on 12/11/24.
//

#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <dlfcn.h>

static NSString * const kANSIRed     = @"\x1b[31m";
static NSString * const kANSIGreen   = @"\x1b[32m";
static NSString * const kANSIYellow  = @"\x1b[33m";
static NSString * const kANSIBlue    = @"\x1b[34m";
static NSString * const kANSIMagenta = @"\x1b[35m";
static NSString * const kANSICyan    = @"\x1b[36m";
static NSString * const kANSIWhite   = @"\x1b[37m";
static NSString * const kANSIReset   = @"\x1b[0m";
static NSString * const kANSIBold    = @"\x1b[1m";

static const NSInteger kDefaultListLimit = 15;
static const NSInteger kDefaultCrashLimit = 1;
static NSString * const kDefaultCrashDir = @"/var/mobile/Library/Logs/CrashReporter";

static NSRegularExpression *gRegisterRegex = nil;

static NSArray<NSString *> *gHeaderKeys = nil;
static NSArray<NSString *> *gSystemInfoKeys = nil;
static NSArray<NSString *> *gExceptionInfoKeys = nil;

static void initializeStaticData(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gHeaderKeys = @[@"Incident Identifier", @"Hardware Model",
                        @"Process", @"Path",
                        @"Version", @"CrashReporter Key",
                        @"Code Type", @"Identifier",
                        @"Role", @"Parent Process",
                        @"Coalition", @"Date/Time",
                        @"AppStoreTools"];
        
        gSystemInfoKeys = @[@"OS Version", @"Launch Time",
                            @"Report Version", @"Release Type"];

        gExceptionInfoKeys = @[@"Exception Type",
                               @"Exception Subtype",
                               @"Exception Codes",
                               @"Termination Description",
                               @"Termination Reason",
                               @"Terminating Process",
                               @"Triggered by Thread"];
        
        NSError *error = nil;
        gRegisterRegex = [NSRegularExpression regularExpressionWithPattern:@"^(x\\d+|fp|sp|pc|lr|far|esr|cpsr):" options:0 error:&error];
        if (error) {
            NSLog(@"Failed to compile register regex: %@", error);
        }
    });
}

void printColoredString(NSString *string, NSString *color) {
    printf("%s%s%s", color.UTF8String, string.UTF8String, kANSIReset.UTF8String);
}

void printFormattedLine(NSString *line) {
    if (line.length == 0) {
        printf("\n");
        return;
    }
    
    NSString *firstComponent = [line componentsSeparatedByString:@": "].firstObject;
    
    if ([gHeaderKeys containsObject:firstComponent]) {
        printColoredString(line, kANSICyan);
        printf("\n");
        return;
    }
    
    if ([gSystemInfoKeys containsObject:firstComponent]) {
        printColoredString(line, kANSIGreen);
        printf("\n");
        return;
    }
    
    if ([gExceptionInfoKeys containsObject:firstComponent]) {
        printColoredString([NSString stringWithFormat:@"%@%@", kANSIBold, line], kANSIRed);
        printf("\n");
        return;
    }
    
    if ([line hasPrefix:@"Thread"] && [line containsString:@"rashed"]) {
        printColoredString([NSString stringWithFormat:@"\n%@%@", kANSIBold, line], kANSIWhite);
        printf("\n");
        return;
    }
    
    if ([line rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet].location == 0) {
        NSArray<NSString *> *components = [line componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        components = [components filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *component, NSDictionary *bindings) {
            return component.length > 0;
        }]];
        
        if (components.count >= 3) {
            NSString *frameNum = components[0];
            NSString *library = components[1];
            NSString *address = components[2];
            NSString *function = @"";
            
            if (components.count > 3) {
                NSRange range = NSMakeRange(3, components.count - 3);
                function = [[components subarrayWithRange:range] componentsJoinedByString:@" "];
            }
            
            printf("%s%-3s %s%-30s %s%-20s %s%s%s\n", kANSIYellow.UTF8String, frameNum.UTF8String,  kANSIBlue.UTF8String, library.UTF8String, kANSICyan.UTF8String, address.UTF8String, kANSIGreen.UTF8String, function.UTF8String, kANSIReset.UTF8String);
            return;
        }
    }
    
    if ([line hasPrefix:@" "] && [line containsString:@"x"]) {
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        
        if ([gRegisterRegex firstMatchInString:trimmedLine options:0 range:NSMakeRange(0, trimmedLine.length)]) {
            NSArray<NSString *> *components = [trimmedLine componentsSeparatedByString:@" "];
            components = [components filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *component, NSDictionary *bindings) {
                return component.length > 0;
            }]];
            
            NSMutableString *formattedLine = [NSMutableString string];
            for (NSString *component in components) {
                if ([component hasSuffix:@":"]) {
                    [formattedLine appendFormat:@"%@%-4s%@", kANSICyan, component.UTF8String, kANSIReset];
                }
                else if ([component hasPrefix:@"0x"]) {
                    [formattedLine appendFormat:@"%@%-18s\t%@", kANSIYellow, component.UTF8String, kANSIReset];
                }
                else if ([component containsString:@")"]) {
                    [formattedLine appendFormat:@"%@%s %@", kANSIGreen, component.UTF8String, kANSIReset];
                }
                else {
                    [formattedLine appendFormat:@"%@%s %@", kANSIWhite, component.UTF8String, kANSIReset];
                }
            }
            printf("   %s\n", formattedLine.UTF8String);
            return;
        }
    }
    
    if ([line hasPrefix:@"Binary Images:"]) {
        printColoredString([NSString stringWithFormat:@"\n%@%@", kANSIBold, line], kANSIWhite);
        printf("\n");
        return;
    }
    
    printf("%s\n", line.UTF8String);
}

void symbolicateAndPrintCrash(NSString *unsymbolicatedFile) {
    if (!unsymbolicatedFile || ![[NSFileManager defaultManager] fileExistsAtPath:unsymbolicatedFile]) {
        printColoredString([NSString stringWithFormat:@"Crash log not found: %@\n", unsymbolicatedFile], kANSIRed);
        return;
    }
    
    NSDictionary *transformedXform = ((id (*)(id, SEL, id, id))objc_msgSend)(objc_getClass("OSALegacyXform"), sel_registerName("transformURL:options:"), [NSURL fileURLWithPath:unsymbolicatedFile], nil);
    if (!transformedXform) {
        printColoredString(@"Failed to transform crash log\n", kANSIRed);
        return;
    }
    
    NSString *symbolicatedLog = transformedXform[@"symbolicated_log"];
    if (!symbolicatedLog) {
        printColoredString(@"Failed to symbolicate crash log\n", kANSIRed);
        return;
    }
    
    NSArray<NSString *> *lines = [symbolicatedLog componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet];
    for (NSString *line in lines) {
        if (line.length > 0) {
            printFormattedLine(line);
        }
    }
}

NSArray<NSString *> *getSortedCrashFiles(NSString *crashDir, NSString *filter, int limit) {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    
    if (limit <= 0 || ![fileManager fileExistsAtPath:crashDir]) {
        printColoredString(@"Crash log directory not found or invalid limit specified\n", kANSIRed);
        return @[];
    }
    
    NSError *error = nil;
    NSArray<NSString *> *crashFiles = [fileManager contentsOfDirectoryAtPath:crashDir error:&error];
    if (error) {
        printColoredString([NSString stringWithFormat:@"Error reading crash directory: %@\n", error.localizedDescription], kANSIRed);
        return @[];
    }
    
    NSString *predicate = @"self ENDSWITH '.ips'";
    if (filter) {
        predicate = [predicate stringByAppendingFormat:@" && self CONTAINS[c] '%@'", filter];
    }
    
    crashFiles = [crashFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:predicate]];
    NSMutableArray<NSString *> *sortedCrashes = [[crashFiles sortedArrayUsingComparator:^NSComparisonResult(NSString *file1, NSString *file2) {
        NSString *path1 = [crashDir stringByAppendingPathComponent:file1];
        NSString *path2 = [crashDir stringByAppendingPathComponent:file2];
        
        NSError *error1 = nil, *error2 = nil;
        NSDictionary *attr1 = [fileManager attributesOfItemAtPath:path1 error:&error1];
        NSDictionary *attr2 = [fileManager attributesOfItemAtPath:path2 error:&error2];
        
        if (error1 || error2) {
            return NSOrderedSame;
        }
        
        return [attr2.fileCreationDate compare:attr1.fileCreationDate];
    }] mutableCopy];
    
    [sortedCrashes enumerateObjectsUsingBlock:^(NSString *crashFile, NSUInteger idx, BOOL *stop) {
        sortedCrashes[idx] = [crashDir stringByAppendingPathComponent:crashFile];
    }];
    
    NSRange limitRange = NSMakeRange(0, MIN(sortedCrashes.count, limit));
    return [sortedCrashes subarrayWithRange:limitRange];
}

void listRecentCrashes(NSString *crashDir, NSString *filter, int limit) {
    NSArray<NSString *> *sortedCrashes = getSortedCrashFiles(crashDir, filter, limit);
    printf("\nRecent crash logs:\n");
    
    [sortedCrashes enumerateObjectsUsingBlock:^(NSString *crashFilePath, NSUInteger idx, BOOL *stop) {
        NSError *error = nil;
        NSDictionary *attrs = [NSFileManager.defaultManager attributesOfItemAtPath:crashFilePath error:&error];
        if (error) {
            printColoredString([NSString stringWithFormat:@"Error reading file attributes: %@\n", error.localizedDescription], kANSIRed);
            return;
        }
        
        NSArray<NSString *> *fileNameParts = [[crashFilePath lastPathComponent] componentsSeparatedByString:@"-"];
        if (fileNameParts.count < 5) {
            printColoredString([NSString stringWithFormat:@"Invalid crash log file name: %@\n", crashFilePath], kANSIRed);
            return;
        }

        NSString *processName = [[fileNameParts subarrayWithRange:NSMakeRange(0, fileNameParts.count - 4)] componentsJoinedByString:@"-"];
        printf("%s%lu. %s%s%s - %s (%s)\n", kANSIYellow.UTF8String, idx + 1, kANSIGreen.UTF8String, crashFilePath.UTF8String, kANSIReset.UTF8String, processName.UTF8String, attrs.fileCreationDate.description.UTF8String);
    }];
}

void printUsage(void) {
    printf("Usage: slog [options] [crash_file]\n");
    printf("Running without options will display the most recent crash log\n");
    printf("Options:\n");
    printf("  -i, --ips <file>      Display a specific crash log\n");
    printf("  -l, --list            List recent crash logs. (default: 15)\n");
    printf("  -c  --count <num>     Limit the number of crash logs to list/symbolicate\n");
    printf("  -f, --filter <app>    Filter crashes by process name. Can be used with -l\n");
    printf("  -h, --help            Show this help message\n");
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        initializeStaticData();
        
        void *osa_handle = dlopen("/System/Library/PrivateFrameworks/OSAnalytics.framework/OSAnalytics", RTLD_NOW);
        if (osa_handle == NULL) {
            printColoredString(@"Failed to load OSAnalytics\n", kANSIRed);
            return 1;
        }
        
        NSString *crashDir = kDefaultCrashDir;
        NSString *ipsFile = nil;
        NSString *filterApp = nil;
        BOOL listCrashes = NO;
        NSInteger limit = -1;
        
        for (int i = 1; i < argc; i++) {
            NSString *arg = @(argv[i]);
            
            if ([arg isEqualToString:@"-h"] || [arg isEqualToString:@"--help"]) {
                printUsage();
                return 0;
            }
            else if ([arg isEqualToString:@"-i"] || [arg isEqualToString:@"--ips"]) {
                if (i + 1 < argc) {
                    ipsFile = @(argv[++i]);
                }
            }
            else if ([arg isEqualToString:@"-l"] || [arg isEqualToString:@"--list"]) {
                listCrashes = YES;
                // If user has not specified a limit, default to kDefaultListLimit
                if (limit == -1) {
                    limit = kDefaultListLimit;
                }
            }
            else if ([arg isEqualToString:@"-f"] || [arg isEqualToString:@"--filter"]) {
                if (i + 1 < argc) {
                    filterApp = @(argv[++i]);
                }
            }
            else if ([arg isEqualToString:@"-c"] || [arg isEqualToString:@"--count"]) {
                if (i + 1 < argc) {
                    limit = [@(argv[++i]) integerValue];
                }
            }
            else {
                // Check if its a valid file path
                NSString *unknownOption = @(argv[i]);
                if ([[NSFileManager defaultManager] fileExistsAtPath:unknownOption]) {
                    // Assume user meant to use -i
                    ipsFile = unknownOption;
                }
                else {
                    // Use it as a process filter
                    filterApp = unknownOption;
                }
            }
        }
        
        // Display a specific crash log
        if (ipsFile) {
            // Support receiving full path or just the ips filename
            if (ipsFile.pathComponents.count == 1) {
                ipsFile = [crashDir stringByAppendingPathComponent:ipsFile];
            }
            
            symbolicateAndPrintCrash(ipsFile);
            return 0;
        }
        
        // List recent crash logs. Honor the limit and filter options
        if (listCrashes) {
            listRecentCrashes(crashDir, filterApp, (int)limit);
            return 0;
        }
        
        // If no user limit was set, default to showing just the most recent crash log
        if (limit == -1) {
            limit = kDefaultCrashLimit;
        }
        
        // No options specified, display the most recent crash log(s)
        NSArray<NSString *> *sortedCrashes = getSortedCrashFiles(crashDir, filterApp, (int)limit);
        if (sortedCrashes.count == 0) {
            printColoredString(@"No recent crash logs found\n", kANSIRed);
            return 1;
        }
        
        for (NSUInteger i = 0; i < sortedCrashes.count; i++) {
            NSString *crashFilePath = sortedCrashes[i];
            printColoredString([NSString stringWithFormat:@"Crash log: %@\n\n", crashFilePath], kANSIGreen);
            symbolicateAndPrintCrash(crashFilePath);
            printf("\n");
        }
    }
    
    return 0;
}
