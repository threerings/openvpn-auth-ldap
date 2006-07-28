/*
 * mockpf.c
 * Evil, evil shim that captures pf ioctls.
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
 * 3. Neither the name of Landon Fuller nor the names of any contributors
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

#include <config.h>

#ifdef HAVE_PF

#include <dlfcn.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdarg.h>
#include <string.h>
#include <errno.h>
#include <sys/ioctl.h>

/*
 * This code serves as a shim to allow the unit testing of /dev/pf
 * ioctl commands without providing root access or modifying the state
 * of the running system.
 *
 * open() is hooked, and its path argument is matched against "/dev/pf".
 * If the path matches, /dev/null is instead opened, and the resultant
 * fd is saved as pffd. All future calls to open("/dev/pf",) will
 * reference this file descriptor. A reference count is maintained,
 * and close() is also hooked -- the file descriptor is actually closed
 * when the reference count reaches 0.
 *
 * Lastly, we hook ioctl(), and check for our pffd. If it's a pf(4) ioctl
 * command, we interpret the ioctl arguments directly -- implementing
 * a mock pf ioctl() interface.
 */

/* Retain a single (reference counted) file descriptor that will be used for
 * all pf(4) ioctls */
static int pffd = -1;
static unsigned int pfRefCount = 0;

/* Real function references */
static int (*_real_open)(const char *, int, ...) = NULL;
static int (*_real_close)(int) = NULL;
static int (*_real_ioctl)(int, unsigned long, ...) = NULL;

int open(const char *path, int flags, ...) {
	mode_t mode;
	va_list ap;

	/* Grab the real symbol if necessary */
	if (!_real_open)
		_real_open = dlsym(RTLD_NEXT, "open");

	/* Are we opening /dev/pf ? */
	if(strcmp(path, PF_DEV_PATH) == 0) {
		/* Does a 'pf' reference already exist? */
		if (pffd != -1) {
			pfRefCount++;
			return pffd;
		} else {
			pffd = _real_open("/dev/null", O_RDWR);
			/* Only increment the refcount if the open succeeded */
			if (pffd != -1)
				pfRefCount++;
			return pffd;
		}
	}

	/* Call the real open */
	if (flags & O_CREAT) {
		va_start(ap, flags);
		mode = va_arg(ap, int);
		va_end(ap);
		return _real_open(path, flags, mode);
	} else {
		return _real_open(path, flags);
	}
}

int close(int d) {
	int ret;

	/* Grab the real symbol if necessary */
	if (!_real_close)
		_real_close = dlsym(RTLD_NEXT, "close");

	if (d == pffd) {
		if (pfRefCount == 1) {
			ret = _real_close(pffd);
			/* Failure here is highly unlikely, but
			 * we account for it anyway */
			if (ret == -1) {
				return ret;
			} else {
				pfRefCount--;
				pffd = -1;
			}
		}
	}

	/* Call the real close */
	return _real_close(d);
}

int ioctl(int d, unsigned long request, ...) {
	va_list ap;
	caddr_t argp;

	/* Grab the real symbol if necessary */
	if (!_real_ioctl)
		_real_ioctl = dlsym(RTLD_NEXT, "ioctl");

	if (d == pffd) {
		switch (request) {
			default:
				errno = EINVAL;
				return -1;
		}
	}

	/* Call the real ioctl */
	va_start(ap, request);
	argp = va_arg(ap, caddr_t);
	va_end(ap);

	return (_real_ioctl(d, request, argp));
}

#endif /* HAVE_PF */
