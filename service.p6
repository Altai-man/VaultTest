use Cro::HTTP::Router;
use Cro::HTTP::Client;
use Cro::HTTP::Log::File;
use Cro::HTTP::Server;

my $application = route {
    get -> {
        content 'text/html', '';
    }
};

my Cro::Service $http = Cro::HTTP::Server.new(
    http => <1.1>,
    host => %*ENV<VAULT_PERL6_HOST> ||
        die("Missing VAULT_PERL6_HOST in environment"),
    port => %*ENV<VAULT_PERL6_PORT> ||
        die("Missing VAULT_PERL6_PORT in environment"),
    :$application,
    after => [
        Cro::HTTP::Log::File.new(logs => $*OUT, errors => $*ERR)
    ]
);

say 1;
my $res = await Cro::HTTP::Client
    .new(:headers[:content-type<application/json>, X-Vault-Token => 'my-very-big-and-dev-only-token'])
    .post("http://localhost:32770/v1/auth/token/create",
          body => { policies => ["web"] });
say 2;
say $res;
say 3;
say await $res.body-text;
say 4;

$http.start;
say "Listening at http://%*ENV<VAULT_PERL6_HOST>:%*ENV<VAULT_PERL6_PORT>";
react {
    whenever signal(SIGINT) {
        say "Shutting down...";
        $http.stop;
        done;
    }
}
