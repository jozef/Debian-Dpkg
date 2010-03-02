# -*- mode: cperl -*-
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

use Test::More tests => 8;

use strict;
use warnings;
use File::Temp qw(tempfile);

use_ok('Dpkg::IPC');

$/ = undef;

my ($tmp_fh, $tmp_name) = tempfile;
my ($tmp2_fh, $tmp2_name) = tempfile;

my $string = "foo\nbar\n";
my $string2;

open TMP, '>', $tmp_name;
print TMP $string;
close TMP;

my $pid = fork_and_exec(exec => "cat",
			from_string => \$string,
			to_string => \$string2);

ok($pid);

is($string2, $string, "{from,to}_string");

$pid = fork_and_exec(exec => "cat",
		     from_handle => $tmp_fh,
		     to_handle => $tmp2_fh);

ok($pid);

wait_child($pid);

open TMP, '<', $tmp2_name;
$string2 = <TMP>;
close TMP;

is($string2, $string, "{from,to}_handle");

$pid = fork_and_exec(exec => "cat",
		     from_file => $tmp_name,
		     to_file => $tmp2_name,
		     wait_child => 1,
		     timeout => 5);

ok($pid);

open TMP, '<', $tmp2_name;
$string2 = <TMP>;
close TMP;

is($string2, $string, "{from,to}_file");

eval {
    $pid = fork_and_exec(exec => ["sleep", "10"],
		         wait_child => 1,
		         timeout => 5);
};
ok($@, "fails on timeout");

unlink($tmp_name);
unlink($tmp2_name);
