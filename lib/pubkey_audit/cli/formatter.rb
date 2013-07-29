module PubkeyAudit
  module CLI
    class Formatter
      attr_accessor :host

      def self.pp(hosts)
        hosts.map { |host| new(host).pp }.join("\n\n")
      end

      def initialize(host)
        @host = host
      end

      def summary
        { name: host.name,
          uri: "#{host.user}@#{host.host_name}",
          users: host.key_map.users && host.key_map.users.map { |user|
            { name: user.name, email: user.email, github: user.github }
          },
          anonymous_keys: host.key_map.anonymous_keys,
          status: !host.retriever.message,
          message: host.retriever.message, }
      end

      def detail
        { name: host.name,
          uri: "#{host.user}@#{host.host_name}",
          keys: host.keys,
          users: host.key_map.users && host.key_map.users.map(&:to_h),
          anonymous_keys: host.key_map.anonymous_keys,
          status: !host.retriever.message,
          message: host.retriever.message, }
      end

      def pp
        str = "## HOST: #{host.name} ##\n#{host.user}@#{host.host_name}\n"
        if host.key_map.users
          str += "Users\n"
          host.key_map.users.each { |user| str += "    #{user.name} <#{user.email}>\n" }
          if host.key_map.anonymous_keys.any?
            str += "Unknown Keys (#{host.key_map.anonymous_keys.length})\n"
            host.key_map.anonymous_keys.each { |k| str += "#{k}\n" }
          end
        elsif host.retriever.message
          str += host.retriever.message
        end
        str
      end
    end
  end
end
