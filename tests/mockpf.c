/*
 * mockpf.c
 * Evil testing shim that captures pf ioctls and emulates
 * the /dev/pf interface.
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
#include <stdlib.h>
#include <assert.h>

#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <net/pfvar.h>

/*
 * This code serves as a shim to allow the unit testing of /dev/pf
 * ioctl commands without providing root access or modifying the state
 * of the running system. Our functions tend towards assert() rather
 * than returning an error -- the point is to implode exactly where
 * an error is detected, allowing a client implementator to quickly find
 * the bug in their code.
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

/* Static example tables */
static struct pfr_table artist_table = {
	{ '\0' },
	"ips_artist",
	0,
	0
};

static struct pfr_table dev_table = {
	{ '\0' },
	"ips_developer",
	0,
	0
};

/*! Generic structure definition for either list type. */
typedef struct PFNode {
	struct PFNode *prev;
	struct PFNode *next;
} PFNode;

/*! Generic list structure. */
typedef struct PFList {
	unsigned int nodeCount;
	PFNode *firstNode;
} PFList;

/*! Double linked list of addresses. */
typedef struct PFAddressNode {
	struct PFAddressNode *prev;
	struct PFAddressNode *next;
	struct pfr_addr addr;
} PFAddressNode;

/*! Double linked list of tables. */
typedef struct PFTableNode {
	struct PFTableNode *prev;
	struct PFTableNode *next;
	struct pfr_table table;
	PFList addrs;
} PFTableNode;

static PFList *pf_tables;

/*! Initialize a new list. */
static void init_pflist(PFList *list) {
	list->firstNode = NULL;
}

/*! Initialize a new node. */
static void init_pfnode(PFNode *node) {
	node->prev = NULL;
	node->next = NULL;
}

/* Insert a node into the list */
static void insert_pfnode(PFList *list, PFNode *new, PFNode *position) {
	list->nodeCount++;

	/* Empty list */
	if (!list->firstNode) {
		list->firstNode = new;
		return;
	}

	/* Top of list? */
	if (!position)
		position = list->firstNode;

	new->prev = position->prev;
	new->next = position;

	if (position->prev)
		position->prev->next = new;
	else
		list->firstNode = new;

	position->prev = new;
}

/* Remove a node from a list */
static void remove_pfnode(PFList *list, PFNode *node) {
	list->nodeCount--;

	/* Last remaining node */
	if (!node->prev && !node->next) {
		free(node);
		list->firstNode = NULL;
		return;
	}

	if (node->prev)
		node->prev->next = node->next;
	else
		list->firstNode = node->next;

	if (node->next)
		node->next->prev = node->prev;

	free(node);
}

/* Set up pf ioctl emulator */
void mockpf_setup(void) {
	PFTableNode *tableNode;
	pf_tables = malloc(sizeof(PFList));
	init_pflist(pf_tables);

	/* Add our artist table */
	tableNode = malloc(sizeof(PFTableNode));
	init_pfnode((PFNode *) tableNode);
	init_pflist(&tableNode->addrs);
	tableNode->table = artist_table;
	insert_pfnode(pf_tables, (PFNode *) tableNode, NULL);

	/* Add our dev table */
	tableNode = malloc(sizeof(PFTableNode));
	init_pfnode((PFNode *) tableNode);
	tableNode->table = dev_table;
	init_pflist(&tableNode->addrs);
	insert_pfnode(pf_tables, (PFNode *) tableNode, NULL);
}

/* Tear down ioctl emulator */
void mockpf_teardown(void) {
	while (pf_tables->firstNode) {
		PFTableNode *tableNode = (PFTableNode *) pf_tables->firstNode;

		/* Clear out the address list */
		while (tableNode->addrs.firstNode)
			remove_pfnode(&tableNode->addrs, tableNode->addrs.firstNode);

		remove_pfnode(pf_tables, pf_tables->firstNode);
	}
}

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

	/* Fish out the argument */
	va_start(ap, request);
	argp = va_arg(ap, caddr_t);
	va_end(ap);

	if (d == pffd) {
		switch (request) {
			struct pfioc_table *iot;
			struct pfr_table *table;
			PFTableNode *tableNode;
			int size;

			case DIOCRGETTABLES:
				iot = (struct pfioc_table *) argp;

				/* Verify structure initialization */
				assert(iot->pfrio_esize == sizeof(struct pfr_table));

				/* Check our caller's buffer size */
				size = sizeof(struct pfr_table) * pf_tables->nodeCount;
				if (iot->pfrio_size < size) {
					iot->pfrio_size = size;
					return 0;
				} else {
					iot->pfrio_size = size;
				}

				table = iot->pfrio_buffer;
				for (tableNode = (PFTableNode *) pf_tables->firstNode; tableNode != NULL; tableNode = tableNode->next) {
					memcpy(table, &tableNode->table, sizeof(struct pfr_table));
					table++;
				}
				return 0;

			case DIOCRCLRADDRS:
				iot = (struct pfioc_table *) argp;

				/* Verify structure initialization */
				assert(iot->pfrio_esize == sizeof(struct pfr_table));

				/* Find the table */
				size = 0; /* Number of addresses cleared */
				for (tableNode = (PFTableNode *) pf_tables->firstNode; tableNode != NULL; tableNode = tableNode->next) {
					/* Check the name */
					if (strcmp(iot->pfrio_table.pfrt_name, tableNode->table.pfrt_name) == 0) {
						/* Matched. Clear out the address list */
						while (tableNode->addrs.firstNode) {
							remove_pfnode(&tableNode->addrs, tableNode->addrs.firstNode);
							size++;
						}
						iot->pfrio_ndel = size;
						return 0;
					}
				}

				/* If we fall through the table wasn't found */
				errno = ESRCH;
				return -1;

			default:
				errno = EINVAL;
				return -1;
		}
	}

	/* Call the real ioctl */
	return (_real_ioctl(d, request, argp));
}

#endif /* HAVE_PF */
