module PubkeyAudit
  class Host
    class ConfigMissingError < StandardError; end

    attr_accessor :name, :config, :keys, :users, :anonymous_keys

    def self.retrieve_keys(hosts, concurrency: 8, force_update: false, &block)
      parallel_options = { in_threads: concurrency}
      parallel_options[:finish] = block if block_given?

      hosts = Parallel.map hosts, parallel_options do |name_or_options|
        Host.init_and_load(name_or_options, force_update)
      end
    end

    def self.init_and_load(name, force_update = false)
      host = new(name)
      if host.keys_saved? && ! force_update
        host.load_keys
      else
        host.retrieve_keys
        host.save_keys
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

      @retriever  = options[:retriever] || Retriever.new(self)
      @storage    = options[:storage]   || Storage.new(self)
    end

    # Needs an array of [ {key: user}, {key: user} ]
    # sets the users and anonymous keys hashes
    def map_users(users_hash)
      @users = if keys
        @anonymous_keys, users =  keys.map { |key| [ key, users_hash[key] ] }
                                      .partition { |key, user| user.nil? }

        @users = users.map { |key, user| user }
      else
        nil
      end
    end

    def ssh_start
      out = ""
      Net::SSH.start(host_name, user) do |ssh|
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

    def to_h
      { name: name,
        uri: "#{user}@#{host_name}",
        keys: keys,
        users: @users.map(&:to_h),
        anonymous_keys: @anonymous_keys,
        message: @retriever.message, }
    end

    def heading
      "#{name}\n#{user}@#{host_name}\n"
    end

    def pp
      str = heading
      if keys
        str += keys.join("\n")
      elsif @retriever.message
        str += @retriever.message
      end
    end
  end
end