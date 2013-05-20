require 'thor'
require 'pry'
require 'toml'
require './lib/pubkey_audit'

$config = TOML.load_file('config.toml')
$config["env"].each { |k,v| ENV[k] = v }

class Pubkey < Thor
  class_option %w( force_update -f ) => false
  class_option %w( silent -s ) => false

  desc "host HOST", "Get public keys for a single repo"
  def host(host_name)
    host = PubkeyAudit::Host.init_and_load(host_name, {
      force_update: options[:force_update],
    })
                                            
    users = get_users
    PubkeyAudit::Mapper.new([host], users).map
    puts host.to_h.to_yaml unless options[:silent]
  end

  desc "hosts", "Get public keys for all repos in config.toml"
  method_options %w( concurrency -c ) => 8
  def hosts
    bar = ProgressBar.create( title: "Scanning for PKs",
                              total: config["hosts"].length,
                              format: "%t (%c/%C): |%B|")

    hosts = PubkeyAudit::Host.retrieve_keys(config["hosts"], {
      concurrency: options[:concurrency],
      force_update: options[:force_update],
      ssh: { auth_methods: ["pubkey"] },
    }) { |_,_| bar.increment }

    users = get_users

    PubkeyAudit::Mapper.new(hosts, users).map

    # TODO: remove user keys to make this more readable
    puts hosts.map(&:to_h).to_yaml unless options[:silent]
  end

  desc "users", "Retrieves the identity mapping from the server"
  def users
    users = get_users
    puts users.map(&:to_h).to_yaml unless options[:silent]
  end

  desc "console", "run a console in this context"
  def console
    binding.pry
  end

  no_tasks do
    def config
      $config
    end

    def get_users
      users = PubkeyAudit::User.retrieve({
        :refresh_token   => ENV['GOOGLE_REFRESH_TOKEN'],
        :client_id       => ENV['GOOGLE_CLIENT_ID'],
        :client_secret   => ENV['GOOGLE_CLIENT_SECRET'],
        :spreadsheet_key => ENV['GOOGLE_SPREADSHEET_KEY'],
      }, options[:force_update])
    end

    def reload!
      Dir[File.join('./lib', '**', '*.rb')].each(&method(:load))
    end
  end
end