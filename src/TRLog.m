/*
 * TRLog.m
 * Simple logging interface
 *
 * Author: Landon Fuller <landonf@threerings.net>
 *
 * Copyright (c) 2006 Three Rings Design, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of any contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <syslog.h>
#include <stdio.h>
#include <stdarg.h>

#include "TRLog.h"

/*! Log a message to stderr. */
static void log_stderr(const char *message, va_list args) {
	/* Log the message to stderr */
	vfprintf(stderr, message, args);
	fprintf(stderr, "\n");
}

/*! Log a message to syslog. */
static void log_syslog(int priority, const char *message, va_list args) {
	vsyslog(priority, message, args);
}

@implementation TRLog

#define DO_LOG(logName, priority) \
	+ (void) logName: (const char *) message, ... { \
		va_list ap; \
		va_start(ap, message); \
		log_syslog(priority, message, ap); \
		va_end(ap); \
		va_start(ap, message); \
		log_stderr(message, ap); \
		va_end(ap); \
	}

DO_LOG(error, LOG_ERR);
DO_LOG(warning, LOG_WARNING);
DO_LOG(info, LOG_INFO);
DO_LOG(debug, LOG_DEBUG);

#undef DO_LOG

/*!
 * Log a message with the supplied priority.
 */
+ (void) log: (loglevel_t) level withMessage: (const char *) message, ... {
	va_list ap;
	int priority = LOG_ERR;

	/* Map the TRLog log level to a syslog priority. */
	switch (level) {
		case TRLOG_ERR:
			priority = LOG_ERR;
			break;
		case TRLOG_WARNING:
			priority = LOG_WARNING;
			break;
		case TRLOG_INFO:
			priority = LOG_INFO;
			break;
		case TRLOG_DEBUG:
			priority = LOG_DEBUG;
			break;
	}

	/* Log the message to syslog */
	va_start(ap, message);
	log_syslog(priority, message, ap);
	va_end(ap);

	/* Log the message to stderr */
	va_start(ap, message);
	log_stderr(message, ap);
	va_end(ap);
}

@end
