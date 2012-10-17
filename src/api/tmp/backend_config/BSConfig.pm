#
# Copyright (c) 2006, 2007 Michael Schroeder, Novell Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program (see the file COPYING); if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#
################################################################
#
# Open Build Service Configuration
#

package BSConfig;

use Net::Domain;
use Socket;

my $hostname = "localhost";
# IP corresponding to hostname (only used for $ipaccess); fallback to localhost since inet_aton may fail to resolve at shutdown.
my $ip = quotemeta inet_ntoa(inet_aton($hostname) || inet_aton("localhost"));

my $frontend = undef; # FQDN of the WebUI/API server if it's not $hostname

# If defined, restrict access to the backend servers (bs_repserver, bs_srcserver, bs_service)
our $ipaccess = undef; our $dummy = {
   '127\..*' => 'rw', # only the localhost can write to the backend
   "^$ip" => 'rw',    # Permit IP of FQDN
   '.*' => 'worker',  # build results can be delivered from any client in the network
};

# IP of the WebUI/API Server (only used for $ipaccess)
if ($frontend) {
  my $frontendip = quotemeta inet_ntoa(inet_aton($frontend) || inet_aton("localhost"));
  $ipaccess->{$frontendip} = 'rw' ; # in dotted.quad format
}

our $obsname = $hostname; # unique identifier for this Build Service instance
# Change also the SLP reg files in /etc/slp.reg.d/ when you touch hostname or port
our $srcserver = "http://$hostname:3200";
our $reposerver = "http://$hostname:3201";
our $serviceserver = "http://$hostname:3202";
our $servicedir = '/Users/garyblessington/dev/open-build-service/src/api/test/fixtures/backend/services';
#our $servicetempdir = "/var/temp/";
#our $serviceroot = "/opt/obs/MyServiceSystem";

#our $gpg_standard_key = "/etc/obs-default-gpg.asc";
# public download service:
our $repodownload = "http://$hostname/repositories";
# optional notification service:
#our $hermesserver = "http://$hostname/hermes";
#our $hermesnamespace = "OBS";
#
# Notification Plugin
#our $notification_plugin = "notify_hermes";
#
#FIXME2.4 belongs in API
# Does the notify plugin supports multiple actions?
# Hermes doesn't, BOSS does.
#our $multiaction_notify_support = 0

# For the workers only, it is possible to define multiple repository servers here.
# But only one source server is possible yet.
our @reposervers = ("http://$hostname:3201");

# proxy support:
#our $proxy = "http(s)://<user:pass>\@<host>:<port>";

# Curl-like interpretation for noproxy, i.e. each name in $noproxy is either
# a domain containing the hostname or the hostname itself.
# Example: host.com matches host.com, www.host.com etc but not www.myhost.com
#our $noproxy = "localhost, 127.0.0.1";

# Package defaults
our $bsdir = '/Users/garyblessington/dev/open-build-service/src/api/tmp/backend_data';
#our $bsuser = 'obsrun';
#our $bsgroup = 'obsrun';
#our $bsquotafile = '/srv/obs/quota.xml';

# To enable package downloading from backend on demand
our $enable_download_on_demand = 1;

# Disable fdatasync calls, increases the speed, but may lead to data 
# corruption on system crash when the filesystem does not guarantees
# data write before rename.
# It is esp. required on XFS filesystem.
# It is safe to be disabled on ext4 and btrfs filesystems.
#our $disable_data_sync = 1;

# Package rc script / backend communication + log files
our $rundir = "$bsdir/run";
our $logdir = "$bsdir/log";

# optional for non-acl systems, should be set for access control
# 0: trees are shared between projects (built-in default)
# 1: trees are not shared (only usable for new installations)
# 2: new trees are not shared, in case of a missing tree the shared
#    location is also tried (package default)
our $nosharedtrees = 2;

# optional: limit visibility of projects for some architectures
#our $limit_projects = {
# "ppc" => [ "openSUSE:Factory", "FATE" ],
# "ppc64" => [ "openSUSE:Factory", "FATE" ],
#};

# optional: allow seperation of releasnumber syncing per architecture
# one counter pool for all ppc architectures, one for i586/x86_64,
# arm archs are seperated and one for the rest in this example
our $relsync_pool = {
 "local" => "local",
 "i586" => "i586",
 "x86_64" => "i586",
 "ppc" => "ppc",
 "ppc64" => "ppc",
 "mips" => "mips",
 "mips64" => "mips",
 "mipsel" => "mipsel",
 "mips64el" => "mipsel",
 "armv4l"  => "arm",
 "armv5l"  => "arm",
 "armv6l"  => "arm",
 "armv7l"  => "arm",
 "armv5el" => "armv5el", # they do not exist
 "armv6el" => "armv6el",
 "armv7el" => "armv7el",
 "armv7hl" => "armv7hl",
 "armv8el" => "armv8el",
 "sparcv9" => "sparcv9",
 "sparc64" => "sparcv9",
};

# List of power hosts that can handle power jobs for the sake of
# building critical packages fast.
#our $powerhosts  = ["build20"];

# List of power packages that can be built on power hosts 
#our $powerpkgs = [ "glibc", "qt" ]

#No extra stage server sync
#our $stageserver = 'rsync://127.0.0.1/put-repos-main';
#our $stageserver_sync = 'rsync://127.0.0.1/trigger-repos-sync';

#No public download server
#our $repodownload = 'http://software.opensuse.org/download/repositories';

#No package signing server
#our $sign = '/usr/bin/sign';
#Extend sign call with project name as argument "--project $NAME"
#our $sign_project = 1;
#Global sign key 
#our $keyfile = '/srv/obs/openSUSE-Build-Service.asc';
#Create a key by default for new projects, if top level have not one
#our $forceprojectkeys = 1;

# Use a special local arch for product building
# our $localarch = "x86_64";

# config options for the bs_worker
#
# run a script to check if the worker is good enough for the job
#our workerhostcheck = 'my_check_script';
# 
# Allow to build as root, exceptions per package
# the keys are actually anchored regexes
# our $norootexceptions = { "my_project/my_package" => 1, "openSUSE:Factory.*/installation-images" => 1 };

# Use old style source service handling
# our $old_style_services = 1;

# host specific configs
my $hostconfig = "bsconfig." . Net::Domain::hostname();
if(-r $hostconfig) {
  print "reading $hostconfig...\n";
  require $hostconfig;
}

1;
