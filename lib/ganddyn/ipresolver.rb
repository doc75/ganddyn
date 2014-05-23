require 'net/http'

module Ganddyn

  class IpResolver

    # urls: hash or ipv4 and ipv6 url services
    #       { :ipv4 => 'http://ipv4_url', :ipv6 => 'http://ipv6_url'}
    def initialize urls = {}
      raise ArgumentError, 'urls is not a Hash' unless urls.is_a? Hash

      @ipv4_url = urls.has_key?(:ipv4) ? urls[:ipv4] : "http://v4.ipv6-test.com/api/myip.php"
      @ipv6_url = urls.has_key?(:ipv6) ? urls[:ipv6] : "http://v6.ipv6-test.com/api/myip.php"
    end

    def get_ipv4
      get_url @ipv4_url
    end

    def get_ipv6
      get_url @ipv6_url
    end

    private
      def get_url( iUrl )
        retval = nil
        uri = URI(iUrl)
        begin
          res = Net::HTTP.get_response(uri)
          if res.code == '200'
            retval = res.body
          end
        rescue SocketError => e
          # normally it happens if the server name is invalid
          # or if no network is available
          # let's return nil
        rescue Exception => e
          # normally it happen if the machine has no ipv6 support
          # let's return nil
        end
        retval
      end
  end
end
