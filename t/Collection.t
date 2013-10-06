#===============================================================================
#
#  DESCRIPTION:  Tests for Games::Go::AGA::BayRate::Collection
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  05/24/2011 12:53:53 PM
#===============================================================================

use strict;
use warnings;

use Test::More tests => 3;  # last test to print

use Carp;

sub in_range {
    my ($val, $expect, $range) = @_;

    return ($val < $expect + $range and
            $val > $expect - $range);
}

use_ok('Games::Go::AGA::BayRate::Player');
use_ok('Games::Go::AGA::BayRate::Game');
use_ok('Games::Go::AGA::BayRate::Collection');

my $collection = Games::Go::AGA::BayRate::Collection->new(
    #iter_hook      => \&iter_hook,
);

my @players;
push @players, $collection->add_player(
    index   => 0,
    id      => 'player 0',
    seed    => -10,     # Initial rating
);
push @players, $collection->add_player(
    index   => 1,
    id      => 'player 1',
    seed    => -10,     # Initial rating
);
push @players, $collection->add_player(
    index   => 2,
    id      => 'player 2',
    seed    => -12,     # Initial rating
);
push @players, $collection->add_player(
    index   => 3,
    id      => 'player 3',
    seed    => -20,     # Initial rating
);

my @games;
push @games, $collection->add_game(
    komi        => 5.5,          # Komi
    handicap    => 0,            # Handicap
    whiteWins   => 0,           # True if White wins
    white       => $players[0], # 10K beats 11K, expected
    black       => $players[1],
);
#push @games, $collection->add_game(
#    komi        => -8,           # Komi
#    handicap    => 8,           # Handicap
#    whiteWins   => 1,           # True if White wins
#    white       => $players[2], # 12K beats 20K, expected
#    black       => $players[3],
#);

$collection->calc_ratings;
show_players(\@players);


sub show_players {
    my ($p) = @_;
    foreach my $player (@{$p}) {
        printf("%s\t% 5.3g=>%g (sigma=% 5.3g)\n",
            $player->get_id,
            $player->get_seed,
            $player->get_rating,
            $player->get_sigma);
    }
}

#ok(in_range($handicapeqv, $expect->[0], .00005), "handicapeqv(is $handicapeqv, expect $expect->[0])");
