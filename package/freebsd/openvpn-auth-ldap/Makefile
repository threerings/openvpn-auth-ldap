# New ports collection makefile for:	openvpn-auth-ldap
# Date created:		06 June 2007
# Whom:			Nick Barkas <snb@threerings.net>
#
# $FreeBSD: $

PORTNAME=	openvpn-auth-ldap
PORTVERSION=	2.0.3
CATEGORIES=	security
MASTER_SITES=	http://dpw.threerings.net/projects/openvpn-auth-ldap/
DISTNAME=	auth-ldap-${PORTVERSION}

MAINTAINER=	snb@threerings.net
COMMENT=	LDAP authentication plugin for OpenVPN

PLIST_FILES=	lib/openvpn-auth-ldap.so

USE_OPENLDAP=	yes
BUILD_DEPENDS=	re2c:${PORTSDIR}/devel/re2c \
		${NONEXISTENT}:${PORTSDIR}/security/openvpn:extract

# XXX need to find OpenVPN version and add proper configure flags

post-install:
.if !defined(NOPORTDOCS)
	${INSTALL_DATA} ${WRKSRC}/README ${DOCSDIR}
PLIST_FILES+=	${DOCSDIR}/README
.endif

.include <bsd.port.mk>
