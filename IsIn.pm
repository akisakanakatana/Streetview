
package IsIn;

# functional
sub zip {
    my ($ah, @at) = @{+shift};
    my ($bh, @bt) = @{+shift};
    return defined $ah && defined $bh ?
	zip (\@at, \@bt, (@_, [$ah, $bh])) : @_;
}
sub foldr(&$@) {
    my ($f, $z, $h, @t) = @_;
    return defined $h ? $f->($h, &foldr ($f, $z, @t)) : $z;
}
sub foldl(&$@) {
    my ($f, $r, $h, @t) = @_;
    return defined $h ? &foldl ($f, $f->($h, $r), @t) : $r;
}
sub cyclezip {
    my ($h, @t) = @_;
    return zip ([$h, @t], [@t, $h]);
}

# point calculation
sub minusPoint {
    my ($ax, $ay, $bx, $by) = @_;
    return ($ax - $bx, $ay - $by);
}
sub minusPointX {
    my ($ax, $ay, $bx, $by) = @_;
    return $ax - $bx;
}
sub crossPointZ {
    my ($ax, $ay, $bx, $by) = @_;
    return $ax * $by - $ay * $bx;
}
sub crossp {
    my @a = @{+shift};
    my @c = @{+shift};
    my @d = @{+shift};
    return minusPointX (@c, @a) * minusPointX (@d, @a) <= 0.0
	&& minusPointX (@c, @d) *
   	      crossPointZ (minusPoint (@d, @c), minusPoint (@a, @c)) <= 0.0
}
sub isin {
    my ($a, @ps) = @_;
    return foldr {
	my ($x, $r) = @_;
	crossp ($a, @$x) ? !$r : $r
    } 0, cyclezip (@ps);
}

=pod
print isin ([1.1,0.0], [0.7,0.7], [0.0,1.0], [1.0,1.0], [1.0,1.0]) ?
    "in" : "out";
=cut

1;
