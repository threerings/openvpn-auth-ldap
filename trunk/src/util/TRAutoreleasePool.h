/* 
 * TRAutoreleasePool.h
 *
 * Copyright (C) 2006 Landon Fuller <landonf@opendarwin.org>
 * All rights reserved.
 *
 * Author: Landon Fuller <landonf@opendarwin.org>
 *
 * This file is part of libFoundation.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose and without fee is hereby granted, provided
 * that the above copyright notice appear in all copies and that both that
 * copyright notice and this permission notice appear in supporting
 * documentation.
 *
 * We disclaim all warranties with regard to this software, including all
 * implied warranties of merchantability and fitness, in no event shall
 * we be liable for any special, indirect or consequential damages or any
 * damages whatsoever resulting from loss of use, data or profits, whether in
 * an action of contract, negligence or other tortious action, arising out of
 * or in connection with the use or performance of this software.
 */

#ifndef __TRAutoreleasePool_h__
#define __TRAutoreleasePool_h__

#include "TRObject.h"

typedef struct _TRAutoreleasePoolBucket TRAutoreleasePoolBucket;

@interface TRAutoreleasePool : TRObject
{
@private
	TRAutoreleasePoolBucket *poolBucket;
}

+ (void) addObject:(id)anObject;

- (void) addObject:(id)anObject;

@end

#endif /* __TRAutoreleasePool_h__ */
