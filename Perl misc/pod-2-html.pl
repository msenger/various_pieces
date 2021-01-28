#!/usr/bin/perl
#
#   Usage: ./pod-2-html.pl [<] <inputfile>  > <outfile>
#
#   Make an HTML documentation from a POD-containing file, adding some
#   CSS-style declaration in order to get the same/similar look&feel
#   as the HTML documentation on CPAN site.
#
#   Martin Senger <martin.senger@gmail.com>
#   December 2012
# -----------------------------------------------------------------

use warnings;
use strict;
use Pod::Simple::HTML;

# ----------------------------------------------------------------------

use Cwd;
my $dir = getcwd;

# get the input
my $input = do { local $/; <> };

# CSS-style to be added to the result
my @style = <DATA>;
my $style = join ("", @style);

# make the POD to HTMl conversion
my $p = Pod::Simple::HTML->new;
$p->index (1);
$p->html_css ("\n$style\n");
$p->output_string (\my $result);
$p->parse_string_document ($input);
print STDOUT $result;

__DATA__
<style type="text/css">
 <!--/*--><![CDATA[/*><!--*/
BODY {
  background: white;
  color: black;
  font-family: arial,sans-serif;
  margin: 0;
  padding: 1ex;
}

A:link, A:visited {
  background: transparent;
  color: #006699;
}

A[href="#POD_ERRORS"] {
  background: transparent;
  color: #FF0000;
}

DIV {
  border-width: 0;
}

DT {
  margin-top: 1em;
  margin-left: 1em;
}

.pod { margin-right: 20ex; }

.pod PRE     {
  background: #eeeeee;
  border: 1px solid #888888;
  color: black;
  padding: 1em;
  white-space: pre;
}

.pod H1      {
  background: transparent;
  color: #006699;
  font-size: large;
}

.pod H1 A { text-decoration: none; }
.pod H2 A { text-decoration: none; }
.pod H3 A { text-decoration: none; }
.pod H4 A { text-decoration: none; }

.pod H2      {
  background: transparent;
  color: #006699;
  font-size: medium;
}

.pod H3      {
  background: transparent;
  color: #006699;
  font-size: medium;
  font-style: italic;
}

.pod H4      {
  background: transparent;
  color: #006699;
  font-size: medium;
  font-weight: normal;
}

.pod IMG     {
  vertical-align: top;
}

.pod .toc A  {
  text-decoration: none;
}

.pod .toc LI {
  line-height: 1.2em;
  list-style-type: none;
}

  /*]]>*/-->
</style>
