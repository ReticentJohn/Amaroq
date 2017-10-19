//
//  Validations.h
//  Food4Day
//
//  Created by Trong Dinh on 6/13/14.
//  Copyright (c) 2014 com.mroom.food4day. All rights reserved.
//

#ifndef EMPTY
#define EMPTY(__OBJECT) ( (nil == __OBJECT) ? YES : ( (nil != __OBJECT && [__OBJECT respondsToSelector:@selector(count)]) ? ([__OBJECT performSelector:@selector(count)] <= 0) : ( (nil != __OBJECT && [__OBJECT respondsToSelector:@selector(length)]) ? ([__OBJECT performSelector:@selector(length)] <= 0) : NO ) ) )
#endif

#ifndef NOTEMPTY
#define NOTEMPTY(__OBJECT) (EMPTY(__OBJECT) == NO)
#endif

#ifndef VALID
#define VALID(__OBJECT, __CLASSNAME) (nil != __OBJECT && [__OBJECT isKindOfClass:[__CLASSNAME class]])
#endif

#ifndef VALID_EMPTY
#define VALID_EMPTY(__OBJECT, __CLASSNAME) (VALID(__OBJECT, __CLASSNAME) == YES && EMPTY(__OBJECT) == YES)
#endif

#ifndef VALID_NOTEMPTY
#define VALID_NOTEMPTY(__OBJECT, __CLASSNAME) (VALID(__OBJECT, __CLASSNAME) == YES && EMPTY(__OBJECT) == NO)
#endif

#ifndef ARRAY_INDEX_EXISTS
#define ARRAY_INDEX_EXISTS(__OBJECT, __INDEX) (VALID(__OBJECT, NSArray) && __INDEX >= 0 && [(NSArray *) __OBJECT count] > __INDEX)
#endif

#ifndef OBJECT_AT_INDEX
#define OBJECT_AT_INDEX(__OBJECT, __INDEX) ((ARRAY_INDEX_EXISTS(__OBJECT, __INDEX)) ? [__OBJECT objectAtIndex:__INDEX] : nil)
#endif
