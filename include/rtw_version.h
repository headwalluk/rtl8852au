/*
 * DRIVERVERSION is normally injected by the project Makefile from
 * PACKAGE_VERSION in dkms.conf, so this file does not need editing
 * when cutting a release.
 *
 * The fallback below only fires if the macro hasn't already been
 * defined on the command line — i.e. for IDE / standalone / third-
 * party builds that don't use the project Makefile.
 */
#ifndef DRIVERVERSION
#define DRIVERVERSION	"v0.0.0-unknown"
#endif
