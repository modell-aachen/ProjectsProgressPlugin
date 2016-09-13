# See bottom of file for default license and copyright information
package Foswiki::Plugins::ProjectsProgressPlugin;

use strict;
use warnings;

use Foswiki::Func;
use Foswiki::Plugins;

our $VERSION = '1.0.0';
our $RELEASE = '1.0.0';
our $SHORTDESCRIPTION = 'Renders progress information for project apps/Plugins';
our $NO_PREFS_IN_TOPIC = 1;

sub initPlugin {
  my ( $topic, $web, $user, $installWeb ) = @_;
  # check for Plugins.pm versions
  if ( $Foswiki::Plugins::VERSION < 2.0 ) {
    Foswiki::Func::writeWarning( 'Version mismatch between ',
    __PACKAGE__, ' and Plugins.pm' );
    return 0;
  }

  Foswiki::Func::registerTagHandler('MILESTONEINFO', \&_tagMILESTONEINFO);

  return 1;
}

sub tagMILESTONEINFO {
  my($session, $params, $topic, $web, $topicObject) = @_;
}

1;

__END__
Q.Wiki ProjectsProgressPlugin - Modell Aachen GmbH

Author: %%

Copyright (C) 2016 Modell Aachen GmbH

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
