module PubkeyAudit
  class Mapper
    def initialize(hosts, users)
      @hosts = hosts
      @users = users
    end

    def map
      pk_to_user_map = {}
      @users.each { |user| user.keys.each { |key| pk_to_user_map[key] = user } }

      @hosts.map do |host|
        host.map_users(pk_to_user_map)
      end
    end
  end
end