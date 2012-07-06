package App::Nopaste::Service::Gist;
use strict;
use warnings;
use base 'App::Nopaste::Service';

use JSON;

sub available         { 1 }
sub forbid_in_default { 0 }

sub nopaste {
    my $self = shift;
    $self->run(@_);
}

sub run {
    my ($self, %arg) = @_;
    my $ua = LWP::UserAgent->new;

    my $filename = "paste." . ( $arg{lang} || 'txt' );
    my %payload = (
        public => ($arg{private} ? \0 : \1),
        files => {
            $filename => {
                content => $arg{text},
            },
        },
    );

    $payload{description} = $arg{desc} if $arg{desc};

    my %headers;
    my $token = $self->_get_token;
    $headers{Authorization} = "token $token" if $token;

    my $res = $ua->post( 'https://api.github.com/gists',
        %headers,
        Content => JSON->new->encode(\%payload),
    );

    return $self->return($res);
}

sub _get_token {
    my ($self) = @_;

    {
        open my $fh, '<', "$ENV{HOME}/.gist_token";
        if( $fh ) {
            my $token = <$fh>;
            return $token;
        }
    }

    return;
}

sub return {
    my ($self, $res) = @_;

    if ($res->is_error) {
      return (0, "Failed: " . $res->status_line);
    }

    if (($res->header('Client-Warning') || '') eq 'Internal response') {
      return (0, "LWP Error: " . $res->content);
    }

    my ($id) = $res->header('Location') =~ qr{^https://api\.github\.com/gists/(\d+)$};

    return (0, "Could not find paste link.") if !$id;
    return (1, "http://gist.github.com/$id");
}

1;

__END__

=head1 NAME

App::Nopaste::Service::Gist - http://gist.github.com/

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=cut

