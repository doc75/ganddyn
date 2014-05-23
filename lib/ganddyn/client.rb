require 'gandi'

require 'fileutils'
require 'yaml'
require 'highline'

if RUBY_PLATFORM =~ /mingw32/
  require 'certified'
end

module Ganddyn
  class Client

    TTL = 300

    def initialize opts
      raise ArgumentError, 'opts is not a Hash' unless opts.is_a? Hash
      raise ArgumentError, 'opts does not contain key :hostname' unless opts.has_key? :hostname
      raise ArgumentError, 'opts does not contain key :api_key' unless opts.has_key? :api_key
      raise ArgumentError, 'opts does not contain key :config_file' unless opts.has_key? :config_file

      @debug = false

      @api_key     = opts[:api_key]
      @config_file = opts[:config_file]

      tab = opts[:hostname].split('.')
      @name     = tab[0...-2].join('.')
      @domain   = tab[-2..-1].join('.')

      @terminal = opts.has_key?(:terminal) ? opts[:terminal] : HighLine.new

      begin
        last_ips_gandi = YAML.load_file @config_file
        print_debug last_ips_gandi.inspect, 2
      rescue => e
        print_debug 'Cannot load config file', 1
        last_ips_gandi = false
      end

      if last_ips_gandi
        print_debug "last_ips_gandi exist", 2
      else
        print_debug "last_ips_gandi is nil or false", 2
      end
      print_debug last_ips_gandi.inspect, 2
      @last_ipv4 = (last_ips_gandi && last_ips_gandi[:ipv4].size > 0) ? last_ips_gandi[:ipv4] : nil

      print_debug "Last IPv4 (form config file):#{@last_ipv4}", 1

      @cur_ipv4 = nil
      @api      = nil
      @zone_id  = nil

    end

    # return value:
    #   true  => update done
    #   false => update not needed
    #   nil => no network found
    def update
      return nil unless ipv4_available?

      last_ipv4 = @last_ipv4 ? @last_ipv4 : get_gandi_ipv4

      update_config = false

      if @last_ipv4.nil?
        update_config = true
      else
        update_config = true if @last_ipv4.empty?
        update_config = true if last_ipv4 != @last_ipv4
      end

      print_debug "Last IPv4 (form config file or Gandi):#{last_ipv4}", 1

      # TODO: save it in YAML file to reduce Gandi queries
      ip_resolv = IpResolver.new
      cur_ipv4 = ipv4_available? ? ip_resolv.get_ipv4 : ''

      if !cur_ipv4.empty? && cur_ipv4 != last_ipv4
        to_update = cur_ipv4
        update_config = true
      else
        to_update = ''
      end

      print_debug to_update.inspect, 2
      retval = update_ips to_update
      if retval and update_config
        retval = update_config_file cur_ipv4
      end
      retval
    end

    private
      # return value:
      #   nil => no network available for IPv4
      #   ''  => no previous IPv4 stored in Ganddi DNS
      #   otherwise return IPv4 address as a string
      def get_gandi_ipv4
        get_record('A') if ipv4_available?
      end

      def get_ping_option
        if RUBY_PLATFORM =~ /mingw32/
          return '-n', '> NUL'
        else
          return '-c', '> /dev/null 2>&1'
        end
      end

      def ipv4_available?
        return @ipv4_avail unless @ipv4_avail.nil?

        opt, out = get_ping_option
        @ipv4_avail = system("ping #{opt} 1 8.8.8.8 #{out}")
        if @ipv4_avail
          print_info 'IPv4 network available'
        else
          print_info 'IPv4 network not available'
        end
        @ipv4_avail
      end

      def get_record type
        raise ArgumentError, %Q{type is not 'A'} unless type == 'A'
        res = gandi_api.domain.zone.record.list(get_zone_id, 0, {:name => @name, :type => type})
        print_debug res.inspect, 2
        if res.size == 0
          print_debug "record not found: '#{@name}'", 1
          ''
        else
          print_debug "record found: '#{@name}' => #{res[0].value}", 1
          res[0].value
        end
      end

      def update_ips update

        raise(ArgumentError, 'update is not a String') unless update.is_a? String

        if update.size == 0
          print_info 'no update needed'
          return true
        end

        cur_vers, all_vers = get_zone_version
        if all_vers.size == 1
          # create a new version and add it to list of all versions
          new_vers = create_new_zone_version
        else
          all_vers = all_vers - [cur_vers]
          # we take the last version of existing versions (my choice ;-)
          new_vers = all_vers[-1]
          clone_zone_version( cur_vers, new_vers )
        end
        
        retval = false
        if update_ipv4(new_vers, update)
          if activate_updated_version new_vers
            retval = true
            print_info 'update done'
          else
            retval = false
            print_info 'update FAILED'
          end
        end
        retval
      end

      def activate_updated_version version
        res = gandi_api.domain.zone.version.set(get_zone_id, version)
        if res
          print_debug 'activation of zone version successful', 1
        else
          print_debug 'activation of zone version failed', 1
        end
        res
      end

      def update_ipv4 zone_version, ip
        update_record zone_version, ip, 'A'
      end

      def update_record zone_version, ip, type
        return false if ip.empty?
        retval = false
        records = gandi_api.domain.zone.record.list( get_zone_id,
                                                     zone_version,
                                                     {:name => @name, :type => type} )
        if records.size == 0
          res = gandi_api.domain.zone.record.add( get_zone_id,
                                                  zone_version,
                                                  { :name  => @name,
                                                    :type  => type,
                                                    :value => ip,
                                                    :ttl   => TTL } )
          retval = true
        else
          records.each do |rec|
            # only update if ip is different
            if rec.value != ip
              res = gandi_api.domain.zone.record.update( get_zone_id,
                                                         zone_version,
                                                         { :id => rec.id },
                                                         { :name  => rec.name,
                                                           :type  => rec.type,
                                                           :value => ip,
                                                           :ttl   => TTL } )
              retval = true
            end
          end
        end
        retval
      end

      def clone_zone_version src, dest
        src_list = gandi_api.domain.zone.record.list(get_zone_id, src)
        print_debug src_list.inspect, 2

        dest_list = gandi_api.domain.zone.record.list(get_zone_id, dest)
        print_debug dest_list.inspect, 2

        dest_list.each do |elt|

          curs = src_list.select { |e| e.name == elt.name && e.type == elt.type }

          if curs.size > 0
            print_debug "\n#{curs.inspect}", 2
            # normally with the same name and same type we should have only 1 record
            cur = curs[0]

            if cur.ttl != elt.ttl || cur.value != elt.value
              print_debug "Updating record (name: #{elt.name} - type: #{elt.type}) to ttl: #{cur.ttl} - value: #{cur.value}", 1
              res = gandi_api.domain.zone.record.update( get_zone_id, dest, { :id => elt.id }, {:name => cur.name, :type => cur.type, :value => cur.value, :ttl => cur.ttl} )
              print_debug res.inspect, 2
            else
              print_debug "record (name: #{elt.name} - type: #{elt.type}) already up-to-date", 1
            end

            src_list = src_list - [cur]

          else
            # it does not exist in current zone, let's delete this record
            print_debug "\nDeleting record (name: #{elt.name} - type: #{elt.type})", 1
            res = gandi_api.domain.zone.record.delete( get_zone_id, dest, { :id => elt.id } )
            
            if res == 1
              print_debug "Deletion OK", 2
            else
              print_debug "ERROR: deletion of #{res} records", 2
            end
          end
        end

        src_list.each do |cur|
          print_debug "Creating record (name: #{cur.name} - type: #{cur.type} - ttl: #{cur.ttl} - value: #{cur.value}", 1
          res = gandi_api.domain.zone.record.add( get_zone_id, dest, {:name => cur.name, :type => cur.type, :value => cur.value, :ttl => cur.ttl} )
        end
      end

      def update_config_file ip
        if File.open(@config_file, 'w+') { |f| f.write({:ipv4 => ip}.to_yaml) }
          true
        else
          false
        end
      end

      def get_zone_version
        get_zone_id
        infos = gandi_api.domain.zone.info(@zone_id)
        return infos.version, infos.versions
      end

      def create_new_zone_version
        gandi_api.domain.zone.version.new_version(@zone_id)
      end

      def get_zone_id
        @zone_id ||= gandi_api.domain.info(@domain).zone_id
      end

      def gandi_api
        @api ||= Gandi::Session.new(@api_key)
      end

      def print_info str
        @terminal.say str
      end

      def print_debug str, level = 1
        @terminal.say str if @debug and @debug >= level
      end
  end
end
