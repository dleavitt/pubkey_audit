require 'thor'
require 'pry'
require 'toml'
require 'highline/import'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')
require 'pubkey_audit'
require "pubkey_audit/cli/formatter"

$config = TOML.load_file('config.toml')
$config["env"].each { |k,v| ENV[k] = v }

class Pubkey < Thor
  class_option :force_update, aliases: "-f", default: false, type: :boolean
  class_option :silent, aliases: "-s", default: false, type: :boolean

  desc "interactive", "Stuff"
  def interactive
    puts "Select a host"
    host_name = choose(*config["hosts"].sort)
    host = PubkeyAudit::Host.init_and_load(host_name, {
      force_update: options[:force_update],
    })
    users = get_users
    PubkeyAudit::Mapper.new([host], users).map

    host.ssh_start do |ssh|
      loop do
        puts "Authorized keys"
        key = choose do |m|
          host.key_map.key_map.each do |key, user|
            if user
              str = set_color("#{user.name}: #{key[0..6]}...#{key[-16..-1]}", :green)
              m.choice(str) { key }
            else
              str = set_color("anon: #{key[0..6]}...#{key[-16..-1]}", :red)
              m.choice(str) { key }
            end
          end

          m.choice("Exit") { break(2) }
        end

        if yes? "Really delete key #{key[0..6]}...#{key[-16..-1]}?"
          keys = ssh.exec!("cat ~/.ssh/authorized_keys").split("\n")
            .select { |line| line !=~ /^\s*#/ && line[key] }
          # TODO: delete keys
          # TODO: not all keys are showing up
        end
      end
    end
  end

  desc "host HOST", "Get public keys for a single repo"
  def host(host_name)
    host = PubkeyAudit::Host.init_and_load(host_name, {
      force_update: options[:force_update],
    })

    users = get_users
    PubkeyAudit::Mapper.new([host], users).map
    puts PubkeyAudit::CLI::Formatter.pp([host]) unless options[:silent]
  end

  desc "hosts", "Get public keys for all repos in config.toml"
  method_options %w( concurrency -c ) => 8
  def hosts
    bar = ProgressBar.create( title: "Scanning for PKs",
                              total: config["hosts"].length,
                              format: "%t (%c/%C): |%B|") if STDOUT.tty?

    hosts = PubkeyAudit::Host.retrieve_keys(config["hosts"], {
      concurrency: options[:concurrency],
      force_update: options[:force_update],
      ssh: { auth_methods: ["publickey"] },
    }) { |_,_| bar.increment if STDOUT.tty? }

    users = get_users

    PubkeyAudit::Mapper.new(hosts, users).map

    # TODO: remove user keys to make this more readable
    puts PubkeyAudit::CLI::Formatter.pp(hosts)
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
