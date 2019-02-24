//
//  MastodonConstants.h
//  DireFloof
//
//  Created by John Gabelmann on 2/7/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef MastodonConstants_h
#define MastodonConstants_h

#define MS_BASE_URL_STRING                              @"https://mastodon.social/"
#define MS_BASE_API_URL_STRING                          @"https://mastodon.social/api/v1/"
#define MS_BASE_MEDIA_URL_STRING                        @"https://files.mastodon.social/"
#define MS_CLIENT_ID_KEY                                @"MS_CLIENT_ID_KEY"
#define MS_CLIENT_SECRET_KEY                            @"MS_CLIENT_SECRET_KEY"
#define MS_CLIENT_NOTIFICATION_STATE_KEY                @"MS_CLIENT_NOTIFICATION_STATE_KEY"
#define MS_BASE_URL_STRING_KEY                          @"MS_BASE_URL_STRING_KEY"
#define MS_BASE_API_URL_STRING_KEY                      @"MS_BASE_API_URL_STRING_KEY"
#define MS_BASE_MEDIA_URL_STRING_KEY                    @"MS_BASE_MEDIA_URL_STRING_KEY"
#define MS_INSTANCE_KEY                                 @"MS_INSTANCE_KEY"
#define MS_LAST_NOTIFICATION_ID_KEY                     @"MS_LAST_NOTIFICATION_ID_KEY"
#define MS_LAST_APNS_REFRESH_KEY                        @"MS_LAST_APNS_REFRESH_KEY"
#define MS_LAST_BACKGROUND_FETCH_KEY                    @"MS_LAST_BACKGROUND_FETCH_KEY"
#define MS_CURRENT_USER_KEY                             @"MS_CURRENT_USER_KEY"
#define MS_MEDIA_ATTACHMENT_MEDIA_KEY                   @"MS_MEDIA_ATTACHMENT_MEDIA_KEY"
#define MS_MEDIA_ATTACHMENT_DESCRIPTION_KEY             @"MS_MEDIA_ATTACHMENT_DESCRIPTION_KEY"
#define MS_APNS_URL_STRING                              @"https://amarok-apns.herokuapp.com/"

#define MS_VISIBILITY_TYPE_DIRECT           @"direct"
#define MS_VISIBILITY_TYPE_PRIVATE          @"private"
#define MS_VISIBILITY_TYPE_UNLISTED         @"unlisted"
#define MS_VISIBILITY_TYPE_PUBLIC           @"public"

#define MS_NOTIFICATION_TYPE_MENTION        @"mention"
#define MS_NOTIFICATION_TYPE_REBLOG         @"reblog"
#define MS_NOTIFICATION_TYPE_FAVORITE       @"favourite"
#define MS_NOTIFICATION_TYPE_FOLLOW         @"follow"

#define MS_FOLLOW_STATUS_KEY_FOLLOWING      @"following"
#define MS_FOLLOW_STATUS_KEY_FOLLOWED_BY    @"followed_by"
#define MS_FOLLOW_STATUS_KEY_BLOCKING       @"blocking"
#define MS_FOLLOW_STATUS_KEY_MUTING         @"muting"
#define MS_FOLLOW_STATUS_KEY_REQUESTED      @"requested"

#define MS_MISSING_AVATAR_URL               @"avatars/original/missing.png"

typedef NS_ENUM(NSUInteger, MSTimelineType) {
    MSTimelineTypeHome          = 1,
    MSTimelineTypePublic        = 2,
    MSTimelineTypeMentions      = 3,
    MSTimelineTypeHashtag       = 4,
    MSTimelineTypeLocal         = 5,
};

typedef NS_ENUM(NSUInteger, MSMediaType) {
    MSMediaTypeImage            = 1,
    MSMediaTypeVideo            = 2,
    MSMediaTypeGifv             = 3,
};

#endif /* MastodonConstants_h */
