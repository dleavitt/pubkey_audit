module PubkeyAudit
  class Host
    class Storage
      def initialize(host)
        @host = host
        FileUtils.mkdir_p(path)
      end

      def exists?
        File.exist? file_path
      end

      def save
        File.write(file_path, @host.keys.join("\n"))
      end

      def load
        File.read(file_path).split("\n")
      end

      def file_path
        File.join(path, @host.name)
      end

      def path
        @path ||= File.join(Dir.tmpdir, "pubkey_audit", "hosts")
      end
    end
  end
end