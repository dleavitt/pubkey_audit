module PubkeyAudit
  class User
    attr_accessor :name, :email, :github, :org, :keys
    ATTRIBUTES = %i(name email github org keys)

    def self.retrieve(params, force_update = false)
      imap = IdentityMap.new(params)
      imap.users(force_update)
    end

    def initialize(params)
      ATTRIBUTES.each do |attr|
        self.send("#{attr}=", params[attr])
      end
    end

    def to_h
      ATTRIBUTES.each_with_object({}) { |attr, h| h[attr] = send(attr) }
    end
  end
end