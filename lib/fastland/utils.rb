# frozen_string_literal: true

module FastLand
  module Utils
    class Basic
      class << self
        def url_exists?(url:)
          uri = URI.parse(url)
          Net::HTTP.get_response(uri).code == "200"
        end

        def url?(string:)
          string = remove_invalid(string: string)
          uri = URI.parse(string)
          throw "MailToError" if uri.scheme == "mailto"
          throw "TelError" if uri.scheme == "tel"
          !uri.host.nil?
        rescue URI::BadURIError
          false
        rescue URI::InvalidURIError
          false
        rescue => e
          e.to_s.include?("MailToError") || e.to_s.include?("TelError")
        end

        def remove_invalid(string:)
          # See String#encode documentation
          encoding_options = {
            invalid: :replace,
            undef: :replace,
            replace: "",
            universal_newline: true
          }
          string&.encode(Encoding.find("ASCII"), encoding_options)
        end

        def wait(time:)
          sleep(time)
          FastLand::Shopify::Basic.connect
        end

        def local_dir
          ENV["LOCAL_DIR"]
        end

        def local_file(file_name:)
          [local_dir, file_name].join("/")
        end
      end
    end

    class Job
      class << self
        # Return the differences between hashes
        def times_diff(hash1:, hash2:)
        end

        def cron_time(time:)
          hour, minute = time.split(":")
          "#{minute} #{hour} * * *"
        end

        def job_name(time:)
          "Sync Job - #{time}"
        end
      end
    end
  end
end
