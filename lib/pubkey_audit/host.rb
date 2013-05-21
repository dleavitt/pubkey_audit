module PubkeyAudit
  class Host
    class ConfigMissingError < StandardError; end

    attr_accessor :name, :config, :keys, :users, :anonymous_keys, :retriever

    def self.retrieve_keys(hosts, options = {}, &block)
      options = options.dup
      concurrency = options.delete(:concurrency) || 8
      parallel_options = { in_threads: concurrency}
      parallel_options[:finish] = block if block_given?
      hosts = Parallel.map hosts, parallel_options do |name_or_options|
        Host.init_and_load(name_or_options, options)
      end
    end

    def self.init_and_load(name, options)
      options = options.dup
      force_update = options.delete(:force_update) || false
      host = new(name, options)
      if host.keys_saved? && ! force_update
        host.load_keys
      else
        host.retrieve_keys and host.save_keys
      end
      host
    end

    # Public:
    #
    # name    - A string corresponding to a Host in your SSH config
    # OR
    # config  - A hash of options for SSH:
    #           :host_name  - Name of the host, e.g. "domain.com"
    #           :user       - Name of the user to log in as
    def initialize(config, options = {})
      if config.is_a? String
        @name = config
        @config = Net::SSH.configuration_for(name)

        raise ConfigMissingError if @config.empty?
      else
        @config = config
        @name = host_name
      end

      @retriever    = options[:retriever] || Retriever.new(self)
      @storage      = options[:storage]   || Storage.new(self)
      @ssh_options  =  options[:ssh] || {}
    end

    # Needs an array of [ {key: user}, {key: user} ]
    # sets the users and anonymous keys hashes
    def map_users(users_hash)
      if keys
        @anonymous_keys, users =  keys.map { |key| [ key, users_hash[key.gsub(/ \S+$/, '')] ] }
                                      .partition { |key, user| user.nil? }

        @users = users.map { |_, user| user }
        @anonymous_keys = @anonymous_keys.map { |key, _| key }
      else
        @users = nil
      end
    end

    def ssh_start
      out = ""
      Net::SSH.start(host_name, user, @ssh_options) do |ssh|
        out = yield(ssh)
      end
      @status = true
      out
    end

    def host_name
      @config[:host_name]
    end

    def user
      @config[:user]
    end

    def retrieve_keys
      @keys = @retriever.get_authorized_keys
    end

    def save_keys
      @storage.save
    end

    def load_keys
      @keys = @storage.load
    end

    def keys_saved?
      @storage.exists?
    end
  end
end