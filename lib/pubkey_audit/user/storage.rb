module PubkeyAudit
  class User
    class Storage
      def initialize(imap)
        @imap = imap
      end

      def load
        saved? && YAML.load_file(path)
      end

      def save(user_hashes)
        File.write(path, user_hashes.to_yaml)
      end

      def saved?
        File.exist? path
      end

      def path
        File.join(Dir.tmpdir, "pubkey_audit", "users.yml")
      end
    end
  end
end