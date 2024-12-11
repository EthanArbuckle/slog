//
//  main.m
//  slog
//
//  Created by Ethan Arbuckle on 12/11/24.
//

#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <dlfcn.h>

#define ANSI_RED     "\x1b[31m"
#define ANSI_GREEN   "\x1b[32m"
#define ANSI_YELLOW  "\x1b[33m"
#define ANSI_BLUE    "\x1b[34m"
#define ANSI_MAGENTA "\x1b[35m"
#define ANSI_CYAN    "\x1b[36m"
#define ANSI_WHITE   "\x1b[37m"
#define ANSI_RESET   "\x1b[0m"
#define ANSI_BOLD    "\x1b[1m"

void printFormattedLine(NSString *line) {
    
    NSArray *headers = @[@"Incident Identifier", @"Hardware Model", @"Process", @"Path", @"Version", @"CrashReporter Key", @"Code Type", @"Identifier", @"Role", @"Parent Process", @"Coalition", @"Date/Time"];
    if ([headers containsObject:[line componentsSeparatedByString:@": "].firstObject]) {
        printf(ANSI_CYAN "%s" ANSI_RESET "\n", line.UTF8String);
        return;
    }
    
    NSArray *systemInfo = @[@"OS Version", @"Launch Time", @"Report Version", @"Release Type"];
    if ([systemInfo containsObject:[line componentsSeparatedByString:@": "].firstObject]) {
        printf(ANSI_GREEN "%s" ANSI_RESET "\n", line.UTF8String);
        return;
    }
    
    NSArray *exceptionInfo = @[@"Exception Type", @"Exception Subtype", @"Exception Codes", @"Termination Description", @"Termination Reason", @"Terminating Process", @"Triggered by Thread"];
    if ([exceptionInfo containsObject:[line componentsSeparatedByString:@": "].firstObject]) {
        printf(ANSI_RED ANSI_BOLD "%s" ANSI_RESET "\n", line.UTF8String);
        return;
    }
    
    if ([line hasPrefix:@"Thread"] && [line containsString:@"rashed"]) {
        printf("\n" ANSI_WHITE ANSI_BOLD "%s" ANSI_RESET "\n", line.UTF8String);
        return;
    }
    
    if ([line rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location == 0) {
        
        NSArray *components = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        components = [components filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
            return [(NSString *)object length] > 0;
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
            
            printf(ANSI_YELLOW "%-3s " ANSI_BLUE "%-30s " ANSI_CYAN "%-20s " ANSI_GREEN "%s" ANSI_RESET "\n", frameNum.UTF8String, library.UTF8String, address.UTF8String, function.UTF8String);
            return;
        }
    }
    
    if ([line hasPrefix:@" "] && [line containsString:@"x"]) {
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([trimmedLine rangeOfString:@"^(x\\d+|fp|sp|pc|lr|far|esr|cpsr):" options:NSRegularExpressionSearch].location != NSNotFound) {
            NSArray *components = [trimmedLine componentsSeparatedByString:@" "];
            components = [components filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
                return [(NSString *)object length] > 0;
            }]];
            
            NSMutableString *formattedLine = [NSMutableString string];
            for (NSString *component in components) {
                if ([component hasSuffix:@":"]) {
                    [formattedLine appendFormat:@ANSI_CYAN "%-4s" ANSI_RESET, component.UTF8String];
                }
                else if ([component hasPrefix:@"0x"]) {
                    [formattedLine appendFormat:@ANSI_YELLOW "%-18s\t" ANSI_RESET, component.UTF8String];
                }
                else if ([component containsString:@")"]) {
                    [formattedLine appendFormat:@ANSI_GREEN "%s " ANSI_RESET, component.UTF8String];
                }
                else {
                    [formattedLine appendFormat:@ANSI_WHITE "%s " ANSI_RESET, component.UTF8String];
                }
            }
            printf("   %s\n", formattedLine.UTF8String);
            return;
        }
    }
    
    if ([line hasPrefix:@"Binary Images:"]) {
        printf("\n" ANSI_WHITE ANSI_BOLD "%s" ANSI_RESET "\n", line.UTF8String);
        return;
    }
    
    printf("%s\n", line.UTF8String);
}


int main(int argc, char *argv[]) {
    @autoreleasepool {
        
        void *osa_handle = dlopen("/System/Library/PrivateFrameworks/OSAnalytics.framework/OSAnalytics", RTLD_NOW);
        if (osa_handle == NULL) {
            printf(ANSI_RED "Failed to load OSAnalytics\n" ANSI_RESET);
            return 1;
        }

        NSString *crashDir = @"/var/mobile/Library/Logs/CrashReporter";
        NSArray *crashFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:crashDir error:nil];
        crashFiles = [crashFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.ips'"]];
        if (crashFiles.count == 0) {
            printf(ANSI_RED "No crash logs found\n" ANSI_RESET);
            return 1;
        }
        
        NSString *latestCrash = [crashFiles sortedArrayUsingComparator:^NSComparisonResult(NSString *file1, NSString *file2) {
            NSString *path1 = [crashDir stringByAppendingPathComponent:file1];
            NSString *path2 = [crashDir stringByAppendingPathComponent:file2];
            NSDictionary *attr1 = [[NSFileManager defaultManager] attributesOfItemAtPath:path1 error:nil];
            NSDictionary *attr2 = [[NSFileManager defaultManager] attributesOfItemAtPath:path2 error:nil];
            return [attr2.fileCreationDate compare:attr1.fileCreationDate];
        }].firstObject;
        
        NSString *crashPath = [crashDir stringByAppendingPathComponent:latestCrash];
        printf(ANSI_GREEN "Processing crash log: %s\n\n" ANSI_RESET, latestCrash.UTF8String);
        
        NSDictionary *transformedXform = ((id (*)(id, SEL, id, id))objc_msgSend)(objc_getClass("OSALegacyXform"), sel_registerName("transformURL:options:"), [NSURL URLWithString:crashPath], nil);
        if (transformedXform == nil) {
            printf(ANSI_RED "Failed to transform crash log\n" ANSI_RESET);
            return 1;
        }
        
        NSString *symbolicatedLog = [transformedXform valueForKey:@"symbolicated_log"];
        if (symbolicatedLog == nil) {
            printf(ANSI_RED "Failed to symbolicate crash log\n" ANSI_RESET);
            return 1;
        }
        
        NSArray *lines = [symbolicatedLog componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        for (NSString *line in lines) {
            if (line.length > 0) {
                printFormattedLine(line);
            }
        }
    }
    
    return 0;
}
