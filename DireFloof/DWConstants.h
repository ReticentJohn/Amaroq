//
//  DWConstants.h
//  DireFloof
//
//  Created by John Gabelmann on 2/15/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef DWConstants_h
#define DWConstants_h

#define DW_BASE_ICON_TINT_COLOR                             [UIColor colorWithRed:0.38f green:0.42f blue:0.51f alpha:1.0f]
#define DW_FAVORITED_ICON_TINT_COLOR                        [UIColor colorWithRed:0.79f green:0.56f blue:0.13f alpha:1.0f]
#define DW_LINK_TINT_COLOR                                  [UIColor colorWithRed:0.61f green:0.68f blue:0.78f alpha:1.0f]
#define DW_BLUE_COLOR                                       [UIColor colorWithRed:0.20f green:0.57f blue:0.84f alpha:1.0f]
#define DW_BACKGROUND_COLOR                                 [UIColor colorWithRed:0.10f green:0.11f blue:0.13f alpha:1.0f]
#define DW_BAR_TINT_COLOR                                   [UIColor colorWithRed:0.19f green:0.21f blue:0.26f alpha:1.0f]
#define DW_SEARCH_HEADER_BACKGROUND_COLOR                   [UIColor colorWithRed:0.61f green:0.68f blue:0.78f alpha:1.0f]

#define DW_NOTIFICATIONS_AVAILABLE_IDENTIFIER               @"DW_NOTIFICATIONS_AVAILABLE"
#define DW_NEEDS_STATUS_CLEANUP_NOTIFICATION                @"DW_NEEDS_STATUS_CLEANUP_NOTIFICATION"
#define DW_NEEDS_REFRESH_NOTIFICATION                       @"DW_NEEDS_REFRESH_NOTIFICATION"
#define DW_STATUS_FAVORITED_NOTIFICATION                    @"DW_STATUS_FAVORITED_NOTIFICATION"
#define DW_STATUS_UNFAVORITED_NOTIFICATION                  @"DW_STATUS_UNFAVORITED_NOTIFICATION"
#define DW_STATUS_BOOSTED_NOTIFICATION                      @"DW_STATUS_BOOSTED_NOTIFICATION"
#define DW_STATUS_UNBOOSTED_NOTIFICATION                    @"DW_STATUS_UNBOOSTED_NOTIFICATION"
#define DW_WILL_PURGE_CACHE_NOTIFICATION                    @"DW_WILL_PURGE_CACHE_NOTIFICATION"
#define DW_DID_PURGE_CACHE_NOTIFICATION                     @"DW_DID_PURGE_CACHE_NOTIFICATION"
#define DW_DID_ANSWER_FOLLOW_REQUEST_NOTIFICATION           @"DW_DID_ANSWER_FOLLOW_REQUEST_NOTIFICATION"
#define DW_DID_CANCEL_LOGIN_NOTIFICATION                    @"DW_DID_CANCEL_LOGIN_NOTIFICATION"
#define DW_DID_SWITCH_INSTANCES_NOTIFICATION                @"DW_DID_SWITCH_INSTANCES_NOTIFICATION"

#define DW_SETTING_ALWAYS_PRIVATE_KEY                       @"DW_SETTING_ALWAYS_PRIVATE"
#define DW_SETTING_ALWAYS_PUBLIC_KEY                        @"DW_SETTING_ALWAYS_PUBLIC"
#define DW_SETTING_AWOO_MODE_KEY                            @"DW_SETTING_AWOO_MODE"
#define DW_SETTING_GIF_AUTOPLAY_KEY                         @"DW_SETTING_GIF_AUTOPLAY_KEY"
#define DW_SETTING_NEW_FOLLOWERS_OFF_KEY                    @"DW_SETTING_NEW_FOLLOWERS_OFF_KEY"
#define DW_SETTING_TOOT_SENSITIVITY_KEY                     @"DW_SETTING_TOOT_SENSITIVITY_KEY"
#define DW_SETTING_FAVORITES_OFF_KEY                        @"DW_SETTING_FAVORITES_OFF_KEY"
#define DW_SETTING_MENTIONS_OFF_KEY                         @"DW_SETTING_MENTIONS_OFF_KEY"
#define DW_SETTING_BOOSTS_OFF_KEY                           @"DW_SETTING_BOOSTS_OFF_KEY"
#define DW_SETTING_PUBLIC_SHOW_LOCAL_KEY                    @"DW_SETTING_PUBLIC_SHOW_LOCAL_KEY"

#define DW_MAINTENANCE_FLAG_1_1_4                           @"DW_MAINTENANCE_FLAG_1_1_4"
#define DW_MAINTENANCE_FLAG_1_1_6                           @"DW_MAINTENANCE_FLAG_1_1_6"

#define DW_PRIVACY_URL                                      @"http://www.iubenda.com/api/privacy-policy/8066189/no-markup"

typedef NS_ENUM(NSUInteger, DWAccessibilityActionType) {
    DWAccessibilityActionTypeOpenThread = 1,
    DWAccessibilityActionTypeOpenUrl = 2,
    DWAccessibilityActionTypeOpenUser = 3,
    DWAccessibilityActionTypeOpenHashtag = 4,
};
#endif /* DWConstants_h */
