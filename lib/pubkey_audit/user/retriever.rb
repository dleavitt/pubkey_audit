require 'faraday'
require 'uri'
require 'google_doc_seed'
require 'json'
require 'csv'

module PubkeyAudit
  class User
    class Retriever
      attr_accessor :csv_string

      def initialize(options)
        @options = options
      end

      def get_spreadsheet
        response = Faraday.post "https://accounts.google.com/o/oauth2/token",
          :refresh_token  => @options[:refresh_token],
          :client_id      => @options[:client_id],
          :client_secret  => @options[:client_secret],
          :grant_type     => "refresh_token"

        access_token = JSON.parse(response.body)['access_token']
        seeder = GoogleDocSeed.new(access_token)
        csv_string = seeder.to_csv_string(@options[:spreadsheet_key])

        csv = CSV.parse(csv_string, CSVConverters::CSV_SETTINGS)

        identity_hashes = csv.map do |row|
          pks = []
          while true
            field = row.delete(:public_key)
            if field.length > 1
              pks << field[1] if field[1]
            else
              break
            end
          end

          { :name => row[:name],
            :email => row[:email],
            :github => row[:github],
            :keys => pks, }
        end
      end
    end
  end
end