# -*- mode: cperl;-*-
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use Test::More;
use Dpkg::ErrorHandling;

use strict;
use warnings;

report_options(quiet_warnings => 1);

my @tests = <DATA>;
my @ops = ("<", "<<", "lt",
	   "<=", "le",
	   "=", "eq",
	   ">=", "ge",
	   ">", ">>", "gt");

plan tests => scalar(@tests) * (3 * scalar(@ops) + 4) + 8;

sub dpkg_vercmp {
     my ($a, $cmp, $b) = @_;
     return system('dpkg', '--compare-versions', $a, $cmp, $b) == 0;
}

sub obj_vercmp {
     my ($a, $cmp, $b) = @_;
     return $a < $b  if $cmp eq "<<";
     return $a lt $b if $cmp eq "lt";
     return $a <= $b if $cmp eq "<=" or $cmp eq "<";
     return $a le $b if $cmp eq "le";
     return $a == $b if $cmp eq "=";
     return $a eq $b if $cmp eq "eq";
     return $a >= $b if $cmp eq ">=" or $cmp eq ">";
     return $a ge $b if $cmp eq "ge";
     return $a > $b  if $cmp eq ">>";
     return $a gt $b if $cmp eq "gt";
}

use_ok('Dpkg::Version');

my $truth = {
    "-1" => {
	"<<" => 1, "lt" => 1,
	"<=" => 1, "le" => 1, "<" => 1,
	"=" => 0, "eq" => 0,
	">=" => 0, "ge" => 0, ">" => 0,
	">>" => 0, "gt" => 0,
    },
    "0" => {
	"<<" => 0, "lt" => 0,
	"<=" => 1, "le" => 1, "<" => 1,
	"=" => 1, "eq" => 1,
	">=" => 1, "ge" => 1, ">" => 1,
	">>" => 0, "gt" => 0,
    },
    "1" => {
	"<<" => 0, "lt" => 0,
	"<=" => 0, "le" => 0, "<" => 0,
	"=" => 0, "eq" => 0,
	">=" => 1, "ge" => 1, ">" => 1,
	">>" => 1, "gt" => 1,
    },
};

# Handling of empty/invalid versions
my $empty = Dpkg::Version->new("");
ok($empty eq "", "Dpkg::Version->new('') eq ''");
ok($empty->as_string() eq "", "Dpkg::Version->new('')->as_string() eq ''");
ok(!$empty->is_valid(), "empty version is invalid");
my $ver = Dpkg::Version->new("10a:5.2");
ok(!$ver->is_valid(), "bad epoch is invalid");
ok($ver eq '10a:5.2', "invalid still same string 1/2");
$ver = Dpkg::Version->new('5.2@3-2');
ok($ver eq '5.2@3-2', "invalid still same string 2/2");
ok(!$ver->is_valid(), "illegal character is invalid");

# Comparisons
foreach my $case (@tests) {
    my ($a, $b, $res) = split " ", $case;
    my $va = Dpkg::Version->new($a, check => 1);
    my $vb = Dpkg::Version->new($b, check => 1);

    is("$va", $a, "String representation of Dpkg::Version($a) is $a");
    is("$vb", $b, "String representation of Dpkg::Version($b) is $b");

    is(version_compare($a, $b), $res, "$a cmp $b => $res");
    is($va <=> $vb, $res, "Dpkg::Version($a) <=> Dpkg::Version($b) => $res");
    foreach my $op (@ops) {
        my $norm_op = version_normalize_relation($op);
	if ($truth->{$res}{$op}) {
	    ok(version_compare_relation($a, $norm_op, $b), "$a $op $b => true");
	    ok(obj_vercmp($va, $op, $vb), "Dpkg::Version($a) $op Dpkg::Version($b) => true");
	    ok(dpkg_vercmp($a, $op, $b), "dpkg --compare-versions $a $op $b => true");
	} else {
	    ok(!version_compare_relation($a, $norm_op, $b), "$a $op $b => false");
	    ok(!obj_vercmp($va, $op, $vb), "Dpkg::Version($a) $op Dpkg::Version($b) => false");
	    ok(!dpkg_vercmp($a, $op, $b), "dpkg --compare-versions $a $op $b => false");
	}
    }
}

__DATA__
1.0-1 2.0-2 -1
2.2~rc-4 2.2-1 -1
2.2-1 2.2~rc-4 1
1.0000-1 1.0-1 0
1 0:1 0
0 0:0-0 0
2:2.5 1:7.5 1
1:foo foo 1
0:foo foo 0
foo foo 0
foo- foo 0
foo- foo-0 0
foo fo 1
foo- foo+ -1
foo~1 foo -1
foo~foo+Bar foo~foo+bar -1
foo~~ foo~ -1
1~ 1 -1
12345+that-really-is-some-ver-0 12345+that-really-is-some-ver-10 -1
foo-0 foo-01 -1
foo.bar foobar 1
foo.bar foo1bar 1
foo.bar foo0bar 1
1foo-1 foo-1 -1
foo2.0 foo2 1
foo2.0.0 foo2.10.0 -1
foo2.0 foo2.0.0 -1
foo2.0 foo2.10 -1
foo2.1 foo2.10 -1
1.09 1.9 0
1.0.8+nmu1 1.0.8 1
3.11 3.10+nmu1 1
0.9j-20080306-4 0.9i-20070324-2 1
1.2.0~b7-1 1.2.0~b6-1 1
1.011-1 1.06-2 1
0.0.9+dfsg1-1 0.0.8+dfsg1-3 1
4.6.99+svn6582-1 4.6.99+svn6496-1 1
53 52 1
0.9.9~pre122-1 0.9.9~pre111-1 1
2:2.3.2-2+lenny2 2:2.3.2-2 1
1:3.8.1-1 3.8.GA-1 1
1.0.1+gpl-1 1.0.1-2 1
1a 1000a -1
