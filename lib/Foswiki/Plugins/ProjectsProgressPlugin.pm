# See bottom of file for default license and copyright information
package Foswiki::Plugins::ProjectsProgressPlugin;

use strict;
use warnings;

use Foswiki::Func;
use Foswiki::Plugins;
use Foswiki::Plugins::JQueryPlugin;
use JSON;

our $VERSION = '1.0.0';
our $RELEASE = '1.0.0';
our $SHORTDESCRIPTION = 'Renders progress information for project apps/Plugins';
our $NO_PREFS_IN_TOPIC = 1;

sub initPlugin {
  my ($topic, $web, $user, $installWeb) = @_;
  if ($Foswiki::Plugins::VERSION < 2.0) {
    Foswiki::Func::writeWarning( 'Version mismatch between ',
    __PACKAGE__, ' and Plugins.pm' );
    return 0;
  }

  Foswiki::Func::registerTagHandler('MILESTONEINFO', \&tagMILESTONEINFO);
  return 1;
}

sub tagMILESTONEINFO {
  my($session, $params, $topic, $web, $topicObject) = @_;

  my $project = $params->{_DEFAULT} || $params->{project} || '';
  return '%RED%<span>Missing param "project"!</span>%ENDCOLOR%' unless $project;

  my $type = $params->{type} || 'timeline';
  return '%RED%<span>Invalid type specified!</span>%ENDCOLOR%' unless $type =~ /^(timeline|milestone|next)$/;

  my $milestones = $params->{milestones} || '';
  $milestones =~ s/\s+//g;

  my @milestones = split(',', $milestones);
  return '%RED%<span>Missing param "milestones"!</span>%ENDCOLOR%' unless scalar(@milestones);

  _injectDeps();
  my $doneField = $params->{donefield} || '$msDone';
  my $dueField = $params->{duefield} || '$msDueDate';

  my ($pweb, $ptopic) = Foswiki::Func::normalizeWebTopicName(undef, $project);
  if ($type eq 'milestone') {
    my $milestone = $params->{milestone} || '';
    return '%RED%<span>Missing param "milestone"!</span>%ENDCOLOR%' unless $milestones;

    my $ms = _readMilestone($pweb, $ptopic, [$milestone], $doneField, $dueField);
    return _toHTML('milestone', shift(@{$ms}));
  }

  my @retval;
  my $returnNext = 0;
  @milestones = @{_readMilestone($pweb, $ptopic, \@milestones, $doneField, $dueField)};

  foreach my $ms (@milestones) {
    if ($type eq 'next') {
      my $isDone = $ms->{done} eq JSON::true;
      my $returnHere = $returnNext && !$isDone;

      if ($returnHere) {
        return _toHTML('milestone', $ms);
      } else {
        my ($index)= grep {@milestones[$_] == $ms} 0..$#milestones;
        return _toHTML('milestone', shift(@retval)) if ($index + 1 == scalar(@milestones));
      }

      $returnNext = $isDone;
    }

    push(@retval, $ms);
  }

  return _toHTML('timeline', \@retval);
}

sub _readMilestone {
  my ($web, $topic, $milestones, $doneField, $dueField) = @_;

  my @retval;
  my ($meta, $text) = Foswiki::Func::readTopic($web, $topic);

  foreach my $milestone (@$milestones) {
    my $titlePref = "PROJECT_${milestone}_TITLE";
    my $done = $doneField;
    my $due = $dueField;
    $done =~ s/\$ms/$milestone/;
    $due =~ s/\$ms/$milestone/;

    my $title = Foswiki::Func::getPreferencesValue($titlePref, $web);
    $title = $meta->expandMacros($title);
    my $due = $meta->get('FIELD', $due);
    my $done = $meta->get('FIELD', $done);

    push @retval, {
      title => "$title",
      due => int($due->{value}),
      dueName => $due->{name},
      done => ($done->{value} eq 'done') ? JSON::true : JSON::false,
      milestone => $milestone,
      project => "$web.$topic"
    };
  }

  $meta->finish();
  return \@retval;
}

sub _toHTML {
  my ($type, $data) = @_;
  my $json = to_json($data);

  if ($type eq 'milestone') {
    my $state = ($data->{done} eq JSON::true) ? 'closed' : 'open';
    return <<HTML;
<div class="milestone">
  <div class="signal">%SIGNAL{"$data->{due}" status="$state"}%</div>
  <div class="text">
    <span><strong>%RENDERFORDISPLAY{"$data->{project}" format="\$value" fields="$data->{dueName}"}%</strong></span>
    <span>$data->{title}</span>
    <span class="rawdata">$json</span>
  </div>
</div>
HTML
  }

  my @entries;
  my $isDone = 0;
  for (my $i = 0; $i < scalar(@$data); $i++) {
    my $entry = @$data[$i];
    my $icon = '';
    $icon = 'fa-play' if $isDone;
    $isDone = $entry->{done} eq JSON::true;
    $icon = 'fa-check' if $isDone;
    $icon = 'fa-play' if $i == 0 && !$isDone;

    my $offset = $Foswiki::cfg{Extensions}{AmpelPlugin}{WARN} || 3;
    my $warn = $offset * 24 * 60 * 60;
    my $now = time;
    my $color = 'green';
    if ($entry->{due} < $now) {
      $color = 'red';
    } elsif ($now + $warn >= $entry->{due}) {
      $color = 'yellow';
    }

    $color = '' if $entry->{done} eq JSON::true;
    my $fa = "<i class=\"fa $icon\"></i>";
    my $html = <<HTML;
<div class="entry $color">
  <span class="bar"></span>
  <span class="circle">$fa
    <span class="tooltip">
      <div><strong>%RENDERFORDISPLAY{"$entry->{project}" format="\$value" fields="$entry->{dueName}"}%</strong></div>
      <div class="due"><strong>$entry->{due}</strong></div>
      <div>$entry->{title}</div>
    </span>
  </span>
</div>
HTML
    push @entries, $html;
  }

  my $inner = join('', @entries);
  return <<HTML;
  <div class="timeline" data-lang="%LANGUAGE%">$inner</div>
HTML
}

sub _injectDeps {
  foreach my $jqp (qw(jqp::moment jqp::tooltipster)) {
    Foswiki::Plugins::JQueryPlugin::createPlugin($jqp);
  }

  Foswiki::Func::addToZone('script', 'VUEJSPLUGIN', "<script type=\"text/javascript\" src=\"%PUBURLPATH%/%SYSTEMWEB%/VueJSPlugin/vue.min.js\"></script>");
  Foswiki::Func::addToZone('head', "VUEJS::STYLES", "<link rel=\"stylesheet\" type=\"text/css\" href=\"%PUBURLPATH%/%SYSTEMWEB%/VueJSPlugin/vue.css\" />");

  my $styles = <<STYLES;
<link rel="stylesheet" type="text/css" media="all" href="%PUBURLPATH%/%SYSTEMWEB%/FontAwesomeContrib/css/font-awesome.min.css%QUERYVERSION{name="FontAwesomeContrib" format="?version=\$version"}%" />
<link rel="stylesheet" type="text/css" media="all" href="%PUBURLPATH%/%SYSTEMWEB%/ProjectsProgressPlugin/css/progress.css?version=$RELEASE" />
STYLES
  Foswiki::Func::addToZone('head', 'PROJECTSPROGRESS::CSS', $styles);

  Foswiki::Func::addToZone(
    'script',
    'PROJECTSPROGRESS::JS',
    "<script type=\"text/javascript\" src=\"%PUBURLPATH%/%SYSTEMWEB%/ProjectsProgressPlugin/js/progress.js\"></script>",
    'JQUERYPLUGIN::JQP::MOMENT,VUEJSPLUGIN,JQUERYPLUGIN::FOSWIKI::PREFERENCES'
  );
}

1;

__END__
Q.Wiki ProjectsProgressPlugin - Modell Aachen GmbH

Author: %$AUTHOR%

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
