# pubkey_audit

Maps public keys on your servers against a Google Docs-based identity file to determine who has access to your servers.

## Installation

Make a Google Spreadsheet with all your peeps and their pubkeys. It should have the following columns: "Name"; "Email"; "Github", plus as many "Public Key" columns as you need.

Clone the repo:

    $ git clone git@github.com:dleavitt/pubkey_audit.git

Install dependencies:

    $ bundle

Copy and customize the config file:

    $ cp config.sample.toml config.toml
    $ vim config.toml

## Usage

Run the following for a list of commands

    $ thor -T

And the following to get help on a command

    $ thor -h pubkey:<command>

## Todos

- Prettier output.
- Instructions for using as a library.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
