//
//  NSString+Awoo.m
//  DireFloof
//
//  Created by John Gabelmann on 3/8/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NSString+Awoo.h"

@implementation NSString (Awoo)

- (NSString *)awooString
{
    NSMutableString *pureStr = [NSMutableString stringWithCapacity:[self length]];
    NSScanner *scanner = [NSScanner scannerWithString:self];
    scanner.charactersToBeSkipped = NULL;
    scanner.caseSensitive = NO;
    
    NSString *tmp = nil;
    BOOL backtracked = NO;
    
    while (![scanner isAtEnd])
    {
        [scanner scanUpToString:@"t" intoString:&tmp];
        NSString *firstT = nil;
        if (![scanner isAtEnd] && !backtracked) {
            firstT = [scanner.string substringWithRange:NSMakeRange(scanner.scanLocation, 1)];
        }
        if (tmp != nil)
            [pureStr appendString:tmp];
        tmp = nil;
        
        if (![scanner isAtEnd])
            [scanner setScanLocation:[scanner scanLocation] + 1];
        
        
        [scanner scanUpToString:@"t" intoString:&tmp];

        NSString *secondT = nil;
        
        if (![scanner isAtEnd]) {
            secondT = [scanner.string substringWithRange:NSMakeRange(scanner.scanLocation, 1)];
        }
        
        BOOL validToot = YES;

        if (tmp.length >= 2 && ![scanner isAtEnd]) {
            NSScanner *tmpScanner = [NSScanner scannerWithString:tmp];
            tmpScanner.charactersToBeSkipped = NULL;
            tmpScanner.caseSensitive = NO;
            
            NSUInteger lastLoc = 0;
            
            if ([[tmp substringToIndex:1] caseInsensitiveCompare:@"o"] != NSOrderedSame) {
                validToot = NO;
            }
            
            NSString *tmpO = nil;
            while (![tmpScanner isAtEnd] && validToot) {
                [tmpScanner scanUpToString:@"o" intoString:&tmpO];
                validToot = tmpScanner.scanLocation - lastLoc <= 1;
                lastLoc = tmpScanner.scanLocation;
                
                if (![tmpScanner isAtEnd]) {
                    [tmpScanner setScanLocation:[tmpScanner scanLocation] + 1];
                }
                tmpO = nil;
            }
            
            tmpScanner = nil;
        }
        else
        {
            validToot = NO;
        }
        
        if (validToot) {
            if (backtracked) {
                [pureStr deleteCharactersInRange:NSMakeRange(pureStr.length - 1, 1)];
            }
            
            [pureStr appendString:@"aw"];
            [pureStr appendString:[tmp lowercaseString]];
            
            backtracked = NO;
        }
        else
        {
            if (firstT) {
                [pureStr appendString:firstT];
            }
            
            if (tmp != nil)
            {
                [pureStr appendString:tmp];
            }
            
            if (secondT) {
                [pureStr appendString:secondT];
                
                [scanner setScanLocation:scanner.scanLocation - 1];
                backtracked = YES;
            }
        }
        
        if (![scanner isAtEnd])
            [scanner setScanLocation:[scanner scanLocation] + 1];
        tmp = nil;
    }
                                                               
    return pureStr;
}

@end
