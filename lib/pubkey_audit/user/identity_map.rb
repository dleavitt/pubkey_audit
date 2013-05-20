module PubkeyAudit
  class User
    class IdentityMap
      extend Forwardable

      def_delegators :@storage, :load, :save, :saved?

      def initialize(options = {})
        @retriever  = options[:retriever]   || Retriever.new(options)
        @storage    = options[:storage]     || Storage.new(self)
      end

      def users(force_update = false)
        return @users if @users && ! force_update

        user_hashes = if ! saved? || force_update
          h = @retriever.get_spreadsheet
          @storage.save(h)
          h
        else
          load
        end

        @users = user_hashes.map { |h| User.new(h) }
      end
    end
  end
end