/*
 * Main.java vi:ts=4:sw=4:expandtab:
 *
 * Copyright (c) 2007 Landon Fuller <landonf@threerings.net>
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

package com.threerings.authldap.test.ldapd;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashSet;
import java.util.Hashtable;
import java.util.Iterator;
import java.util.Set;

import javax.naming.Context;
import javax.naming.NamingException;
import javax.naming.directory.Attribute;
import javax.naming.directory.Attributes;
import javax.naming.directory.BasicAttribute;
import javax.naming.directory.BasicAttributes;
import javax.naming.ldap.InitialLdapContext;
import javax.naming.ldap.LdapContext;

import org.apache.commons.io.FileUtils;
import org.apache.directory.server.configuration.MutableServerStartupConfiguration;
import org.apache.directory.server.core.configuration.MutablePartitionConfiguration;
import org.apache.directory.server.jndi.ServerContextFactory;
import org.apache.directory.shared.ldap.ldif.Entry;
import org.apache.directory.shared.ldap.ldif.LdifReader;
import org.apache.directory.shared.ldap.name.LdapDN;
import org.apache.log4j.Appender;
import org.apache.log4j.Logger;
import org.apache.log4j.SimpleLayout;
import org.apache.log4j.WriterAppender;
import org.apache.mina.util.AvailablePortFinder;

import org.apache.directory.server.core.DirectoryService;

/**
 * Manages an LDAP server for automated testing
 */
public class LDAPServer {
    public static void usage () {
        System.out.println("Usage: ldapd <data directory> <ldif file>");
    }

    public static void main (final String[] args) {
        if (args.length < 2) {
            usage();
            Runtime.getRuntime().exit(1);
        }

        final File dataDir = new File(args[0]);
        final File ldif = new File(args[1]);

        /* Set up logging to stderr */
        final Logger logger = Logger.getRootLogger();
        final Appender stderrOutput = new WriterAppender(new SimpleLayout(), System.err);
        logger.addAppender(stderrOutput);

        /* Kick off the server */
        final LDAPServer server;
        try {
            server = new LDAPServer(dataDir, ldif);
        } catch (final IOException e) {
            System.err.println("IO error instantiating server: " + e.getMessage());
            e.printStackTrace();
            Runtime.getRuntime().exit(1);
            return;

        } catch (final NamingException e) {
            System.err.println("LDAP instantiation error: " + e.getMessage());
            e.printStackTrace();
            Runtime.getRuntime().exit(1);
            return;
        }

        /* Print out the vitals to our waiting caller */
        System.out.println(server.getLdapURL());
    }

    /**
     * Construct a new LDAP Server instance.
     * @throws IOException
     * @throws NamingException
     */
    public LDAPServer (final File dataDir, final File ldif)
        throws IOException, NamingException
    {
        /* Clean out the data directory */
        if (dataDir.exists()) {
            FileUtils.deleteDirectory(dataDir);
            if (dataDir.exists())
                throw new IOException("Unable to delete " + dataDir);
        }

        /* Find an available TCP port */
        final int port = AvailablePortFinder.getNextAvailable(1024);

        /* Instantiate our configuration */
        _config = new MutableServerStartupConfiguration();
        _config.setWorkingDirectory(dataDir);
        _config.setShutdownHookEnabled(false);

        /* Configure networking  */
        _config.setEnableNetworking(true);
        _config.setLdapPort(port);

        /* Set up all test partitions */
        createTestPartitions();

        /* Set up root context */
        _rootDSE = new InitialLdapContext(createContext(""), null);

        /* Import our LDIF */
        importLdif(new FileInputStream(ldif));
    }

    /** Return the test partition base DN */
    public String getBaseDN () {
        return BASEDN;
    }

    /** Return the server's LDAP URL */
    public String getLdapURL () {
        return "ldap://localhost:" + getLdapPort();
    }

    /** Return the server's LDAP port */
    public int getLdapPort () {
        return _config.getLdapPort();
    }

    /**
     * Create the partitions we'll be using for testing.
     *
     * @throws NamingException
     */
    private void createTestPartitions ()
        throws NamingException
    {
        final MutablePartitionConfiguration pcfg = new MutablePartitionConfiguration();
        pcfg.setName("test");
        pcfg.setSuffix("o=test");

        /* Partition indices */
        final Set<String> indices = new HashSet<String>();
        indices.add("objectClass");
        indices.add("o");
        pcfg.setIndexedAttributes(indices);

        /* Create the partition's base entry (o=test) */
        final Attributes basedn = new BasicAttributes(true);
        Attribute attr;

        /* objectClass attribute */
        attr = new BasicAttribute("objectClass");
        attr.add("top");
        attr.add("organization");
        basedn.put(attr);

        /* organization attribute */
        attr = new BasicAttribute("o");
        attr.add("test");
        basedn.put(attr);

        /* Set the partition root entry */
        pcfg.setContextEntry(basedn);

        /* Add the partition to our configuration */
        final Set<MutablePartitionConfiguration> pcfgs = new HashSet<MutablePartitionConfiguration>();
        pcfgs.add(pcfg);
        _config.setContextPartitionConfigurations(pcfgs);
    }

    private Hashtable<Object,Object> createContext (final String partition)
    {
        @SuppressWarnings("unchecked")
        final Hashtable<Object,Object> env = new Hashtable<Object,Object>(_config.toJndiEnvironment());
        env.put(Context.SECURITY_PRINCIPAL, "uid=admin,ou=system");
        env.put(Context.SECURITY_CREDENTIALS, "secret");
        env.put(Context.SECURITY_AUTHENTICATION, "simple");
        env.put(Context.INITIAL_CONTEXT_FACTORY, ServerContextFactory.class.getName());
        env.put(Context.PROVIDER_URL, partition);
        return env;
    }

    /**
     * Load records from LDIF into the root DSE.
     *
     * @param in LDIF input stream
     * @throws NamingException
     */
    private void importLdif(final InputStream in)
        throws NamingException
    {
        @SuppressWarnings("unchecked")
        final Iterator<Entry> entries = new LdifReader(in).iterator();

        while (entries.hasNext()) {
            final Entry entry = entries.next();
            final LdapDN dn = new LdapDN(entry.getDn());
            _rootDSE.createSubcontext(dn, entry.getAttributes());
        }
    }


    /** Default base DN */
    private static final String BASEDN = "o=test";

    /** Our root DSE */
    private final LdapContext _rootDSE;

    /** LDAP server configuration */
    private final MutableServerStartupConfiguration _config;
}