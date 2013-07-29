module PubkeyAudit
  class Host
    class KeyMap
      attr_accessor :key_map, :users, :anonymous_keys

      def initialize(keys, users_hash)
        @key_map = {}
        @users = []
        @anonymous_keys = []
        if keys
          keys.each do |key|
            key.gsub!(/ \S+$/, '')
            user = users_hash[key]
            @key_map[key] = user
            if user
              @users << user
            else
              @anonymous_keys << key
            end
          end
        end
      end

      def rows
        @key_map.map do |key, user|
          [user && user.name || "anonymous", "#{key[0..6]}...#{key[-16..-1]}"]
        end
      end
    end
  end
end
