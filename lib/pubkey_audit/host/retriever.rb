module PubkeyAudit
  class Host
    class Retriever
      attr_accessor :host, :status, :message, :keys

      def initialize(host)
        @host = host
      end

      def get_authorized_keys
        begin
          key_string = @host.ssh_start do |ssh|
            ssh.exec! "cat ~/.ssh/authorized_keys"
          end

          @status = true
          @keys = parse_key_file(key_string)
        rescue SocketError => ex
          @message = "Couldn't connect"
          @status = false
        rescue Net::SSH::AuthenticationFailed => ex
          @message = "Couldn't authorize"
          @status = false
        rescue Errno::ETIMEDOUT => ex
          @message = "Timeout"
          @status = false
        end
      end

      def parse_key_file(key_string)
        key_string.split("\n").find_all { |line|
          line !=~ /^\s*#/ && line =~ /^\s*ssh-(rsa|dss) /
        }.map { |line|
          line[/ssh-(rsa|dss) .*$/]
        }
      end
    end
  end
end
