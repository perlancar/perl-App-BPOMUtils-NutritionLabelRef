package App::BPOMUtils::NutritionLabelRef;

use 5.010001;
use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

our @EXPORT_OK = qw(
                       bpom_get_nutrition_label_ref
               );

our %SPEC;

our @actions = qw(
                     list_refs
                     list_nutrients
                     list_groups
             );

our (@rows, @nutrient_symbols, @groups);
# load and cache table
{
    my (%nutrient_symbols, %groups);
    require TableData::Business::ID::BPOM::NutritionLabelRef;
    my $td = TableData::Business::ID::BPOM::NutritionLabelRef->new;
    @rows = $td->get_all_rows_hashref;
    for (@rows) {
        $nutrient_symbols{ $_->{symbol} }++;
        $groups{ $_->{group} }++;
    }
    @nutrient_symbols = sort keys %nutrient_symbols;
    @groups = sort keys %groups;
}

$SPEC{bpom_get_nutrition_label_ref} = {
    v => 1.1,
    summary => 'Get one or more values from BPOM nutrition label reference (ALG, acuan label gizi)',
    args => {
        action => {
            schema => ['str*', in=>\@actions],
            default => 'list_refs',
            cmdline_aliases => {
                list_nutrients => {is_flag=>1, code=>sub {$_[0]{action}='list_nutrients'}, summary=>'Shortcut for --action=list_nutrients'},
                n              => {is_flag=>1, code=>sub {$_[0]{action}='list_nutrients'}, summary=>'Shortcut for --action=list_nutrients'},
                list_groups    => {is_flag=>1, code=>sub {$_[0]{action}='list_groups'   }, summary=>'Shortcut for --action=list_groups'   },
                g              => {is_flag=>1, code=>sub {$_[0]{action}='list_groups'   }, summary=>'Shortcut for --action=list_groups'   },
            },
        },
        nutrient => {
            schema => 'nutrient::symbol*',
            pos => 0,
        },
        group => {
            schema => ['str*', in=>\@groups],
            pos => 1,
        },
        value => {
            schema => ['float*'],
            pos => 2,
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases =>{l=>{}},
        },
    },
    examples => [
        {
            summary => 'List all nutrient (symbols)',
            argv => [qw/--list-nutrients/],
            test => 0,
            'x.doc.max_result_lines' => 8,
        },
        {
            summary => 'List all groups (symbols)',
            argv => [qw/--list-groups/],
            test => 0,
        },
        {
            summary => 'List all ALG values',
            argv => [qw//],
            test => 0,
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'List ALG for vitamin D, for all groups',
            argv => [qw/VD/],
            test => 0,
        },
        {
            summary => 'List ALG for vitamin D, for 1-3 years olds',
            argv => [qw/VD 1to3y/],
            test => 0,
        },
        {
            summary => 'List ALG for vitamin D, for 1-3 years olds, and compare a value to reference',
            argv => [qw/VD 1to3y 10/],
            test => 0,
        },
    ],
};
sub bpom_get_nutrition_label_ref {
    my %args = @_;
    my $action = $args{action} // 'list_refs';

    if ($action eq 'list_nutrients') {
        return [200, "OK", \@nutrient_symbols];
    } elsif ($action eq 'list_groups') {
        return [200, "OK", \@groups];
    } elsif ($action eq 'list_refs') {
        my @res;
        for my $row0 (@rows) {
            my $resrow = { %{$row0} };
            if (defined $args{nutrient}) {
                next unless $resrow->{symbol} eq $args{nutrient};
                delete $resrow->{symbol};
            }
            if (defined $args{group}) {
                next unless $resrow->{group} eq $args{group};
                delete $resrow->{group};
            }
            if (defined $args{value}) {
                $resrow->{'%alg'} = $args{value} / $resrow->{ref} * 100;
            }
            push @res, $resrow;
        }
        return [200, "OK", \@res, {'table.fields'=>[qw/symbol group ref unit %alg/]}];
    } else {
        return [400, "Unknown action: $action"];
    }
}

1;
#ABSTRACT:

=head1 SYNOPSIS


=head1 DESCRIPTION

This distribution includes CLI utilities related to BPOM nutrition label
reference (ALG, acuan label gizi):

# INSERT_EXECS_LIST


=head1 SEE ALSO

L<TableData::Business::ID::BPOM::NutritionLabelRef>

Other C<App::BPOMUtils::*> distributions.

=cut
