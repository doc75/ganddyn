require 'spec_helper'

require 'ganddyn'

describe Ganddyn::Client do
  before :each do
    @input = StringIO.new
    @output = StringIO.new
    @terminal = HighLine.new(@input, @output)

    @ipv4 = '12.34.56.78'

    @cur_ver = 123
    @other_ver = 456
    @vers = [@cur_ver, @other_ver]

    @mash   = Hashie::Mash.new({:version => @cur_ver, :versions => [@cur_ver, @other_ver]})
    @domain = 'domain.com'
    @name   = 'rspec'

    @host = { :hostname    => 'rspec.domain.com' }
    @key  = { :api_key     => 'FAKEAPIKEY' }
    @cfg  = { :config_file => '/etc/ganddyn.yaml' }
    @param = @host.merge(@key).merge(@cfg)
    allow(YAML).to receive(:load_file).and_return({:ipv4 => @ipv4})

    @api = double('api_gandi')
    allow(@api).to receive(:domain).and_return(@api)
    allow(@api).to receive(:zone).and_return(@api)
    allow(@api).to receive(:info).and_return(@mash)

    allow(@api).to receive(:version).and_return(@api)
    allow(@api).to receive(:new_version).and_return(3)

    allow(@api).to receive(:record).and_return(@api)
    allow(@api).to receive(:add).and_return([])
    allow(@api).to receive(:delete).and_return(1)
    allow(@api).to receive(:update).and_return([])
    allow(@api).to receive(:list).and_return([])

    allow(@api).to receive(:version).and_return(@api)
    allow(@api).to receive(:set).and_return(true)

    allow_any_instance_of(Ganddyn::Client).to receive(:update_config_file).and_return(true)
  end

  describe '#initialize' do
    before :each do
    end
    it 'takes 1 parameters' do
      expect(Ganddyn::Client.new(@param)).to be_a Ganddyn::Client
    end

    it 'raises an error if parameter opts is not a Hash' do
      expect { Ganddyn::Client.new('rspec.domain.com') }.to raise_error(ArgumentError, /opts is not a Hash/)
    end

    it 'raises an error if parameter opts does not contain :hostname key' do
      expect { Ganddyn::Client.new( {:host_name => 'rspec.domain.com'}.merge(@key).merge(@cfg)) }.to raise_error(ArgumentError, /opts does not contain key :hostname/)
    end

    it 'raises an error if parameter opts does not contain :api_key key' do
      expect { Ganddyn::Client.new({:apikey => 'FAKEAPIKEY'}.merge(@host).merge(@cfg)) }.to raise_error(ArgumentError, /opts does not contain key :api_key/)
    end

    it 'raises an error if parameter opts does not contain :config_file key' do
      expect { Ganddyn::Client.new({ :configfile => '/etc/ganddyn.yaml'}.merge(@host).merge(@key)) }.to raise_error(ArgumentError, /opts does not contain key :config_file/)
    end

    it 'loads the config file' do
      expect(YAML).to receive(:load_file).with(@cfg[:config_file]).and_return({:ipv4 => @ipv4})
      Ganddyn::Client.new( @param )
    end
  end

  describe '#update' do
    before :each do
      allow_any_instance_of(Ganddyn::IpResolver).to receive(:get_ipv4).and_return('11.22.33.44')
      @gand = Ganddyn::Client.new( @param.merge({:terminal => @terminal}) )
      allow(@gand).to receive(:gandi_api).and_return(@api)
      allow(@gand).to receive(:system).and_return(true)
    end

    context 'when yaml config file is not found' do
      before :each do
        expect(YAML).to receive(:load_file).and_return(false)
        @gand = Ganddyn::Client.new( @param.merge({:terminal => @terminal}) )
        allow(@gand).to receive(:gandi_api).and_return(@api)
        allow(@gand).to receive(:system).and_return(true)
        allow(@gand).to receive(:get_record)
      end

      it 'asks gandi for ipv4' do
        expect(@gand).to receive(:get_record).with('A').and_return(@ipv4)
        expect(@gand.update).to be_truthy
      end

    end

    context 'when yaml config file exist' do
      it 'does not ask Gandi' do
        allow(@gand).to receive(:get_record)
        expect(@gand.update).to be_truthy
        expect(@gand).to_not have_received(:get_record)
      end
    end

    context 'when no network' do
      before :each do
        allow(@gand).to receive(:system).and_return(false)
      end

      it 'does not ask for IPv4 information' do
        expect_any_instance_of(Ganddyn::IpResolver).to_not receive(:get_ipv4)
        expect(@gand.update).to be_nil
      end
    end

    context 'when no ip to update' do
      before :each do
        allow_any_instance_of(Ganddyn::IpResolver).to receive(:get_ipv4).and_return('')
      end

      it 'returns true' do
        expect(@gand.update).to be_truthy
      end

      it 'does not modify the yaml config file' do
        expect(@gand).to_not receive(:update_config_file)
        @gand.update
      end
    end

    context 'when ip to update' do
      it 'updates the ip' do
        expect(@gand.update).to be_truthy
      end

      it 'updates the yaml config file content' do
        expect(@gand).to receive(:update_config_file).and_return(true)
        @gand.update
      end
    end
  end

end

describe_internally Ganddyn::Client do
  before :each do
    @input = StringIO.new
    @output = StringIO.new
    @terminal = HighLine.new(@input, @output)

    @ipv4 = '12.34.56.78'

    @cur_ver = 123
    @other_ver = 456
    @vers = [@cur_ver, @other_ver]

    @mash   = Hashie::Mash.new({:version => @cur_ver, :versions => @vers})
    @domain = 'domain.com'
    @name   = 'rspec'

    @host = { :hostname    => 'rspec.domain.com' }
    @key  = { :api_key     => 'FAKEAPIKEY' }
    @cfg  = { :config_file => '/etc/ganddyn.yaml' }
    @param = @host.merge(@key).merge(@cfg)
    allow(YAML).to receive(:load_file).and_return({:ipv4 => @ipv4})

    @api = double('api_gandi')
    allow(@api).to receive(:domain).and_return(@api)
    allow(@api).to receive(:zone).and_return(@api)
    allow(@api).to receive(:info).and_return(@mash)

    allow(@api).to receive(:version).and_return(@api)
    allow(@api).to receive(:new_version).and_return(3)

    allow(@api).to receive(:record).and_return(@api)
    allow(@api).to receive(:add).and_return([])
    allow(@api).to receive(:delete).and_return(1)
    allow(@api).to receive(:update).and_return([])
    allow(@api).to receive(:list).and_return([])

    allow(@api).to receive(:version).and_return(@api)
    allow(@api).to receive(:set).and_return(true)

    @gand = Ganddyn::Client.new( @param.merge({:terminal => @terminal}) )
    allow(@gand).to receive(:gandi_api).and_return(@api)
    allow(@gand).to receive(:system).and_return(true)

    allow_any_instance_of(Ganddyn::Client).to receive(:update_config_file).and_return(true)
  end

  describe '#get_zone_id' do
    it 'returns the current zone id' do
      expect(@api).to receive(:info).with(@domain).and_return(Hashie::Mash.new({:zone_id => 666}))
      expect(@gand.get_zone_id).to eq(666)
    end

    it 'calls gandi api only once' do
      expect(@api).to receive(:info).once.with(@domain).and_return(Hashie::Mash.new({:zone_id => 666}))
      expect(@gand.get_zone_id).to eq(666)
      expect(@gand.get_zone_id).to eq(666)
    end
  end

  describe '#create_new_zone_version' do
    pending 'not really necessary to test'
  end

  describe '#get_zone_version' do
    it 'returns 2 values' do
      version, versions = @gand.get_zone_version
      expect(version).to eq(@cur_ver)
      expect(versions).to eq(@vers)
    end
  end

  describe '#get_record' do
    before :each do
      @type   = 'A'
      @filter = { :name => @name, :type => @type }
      @res    = Hashie::Mash.new({:value => @ipv4})
    end

    it 'takes 1 parameter as argument' do
      expect(@api).to receive(:list).with(anything(), 0, @filter).and_return([@res])
      @gand.get_record('A')
    end

    context 'when Gandi returns a record' do
      before :each do
        expect(@api).to receive(:list).with(anything(), 0, @filter).and_return([@res])
      end

      it 'returns the IPv4 address' do
        expect(@gand.get_record('A')).to eq(@ipv4)
      end

      # it 'output record found with value' do
      #   @gand.get_record('A')
      #   expect(@output.string).to match /record found: '#{@name}' => #{@ipv4}/
      # end
    end

    context 'when Gandi returns no record' do
      before :each do
        expect(@api).to receive(:list).with(anything(), 0, @filter).and_return([])
      end

      it 'returns an empty string if Gandi returns no record' do
        expect(@gand.get_record('A')).to eq ''
      end

      # it 'output "record not found"' do
      #   @gand.get_record('A')
      #   expect(@output.string).to match /record not found: '#{@name}'/
      # end
    end

    it 'raises an error if type is not A' do
      expect { @gand.get_record('AA') }.to raise_error(ArgumentError, /type is not 'A'/)
    end
  end

  describe '#get_gandi_ipv4' do
    before :each do
      @type   = 'A'
      @filter = { :name => @name, :type => @type }
      @res    = Hashie::Mash.new({:value => @ipv4})
    end

    it 'retrieve the record A from Gandi DNS' do
      expect(@api).to receive(:list).with(anything(), 0, @filter).and_return([@res])
      expect(@gand.get_gandi_ipv4).to eq @ipv4
    end

    it 'returns nil if IPv4 network is not available' do
      allow(@gand).to receive(:get_record).and_return('1.2.3.4')
      expect(@gand).to receive(:ipv4_available?).and_return(false)
      expect(@gand.get_gandi_ipv4).to be_nil
      expect(@gand).to_not have_received(:get_record)
    end
  end

  describe '#update_record' do
    before :each do
      @type = 'A'
      @rec  = { :name => @name, :type => @type, :value => @ipv4, :ttl => Ganddyn::Client::TTL }

    end

    it 'takes 3 arguments' do
      expect(@gand.update_record( @cur_ver, @ipv4, 'A')).to be_truthy
    end

    context 'when input ip is empty' do
      it 'returns false' do
        expect(@gand.update_record( @cur_ver, '', 'A')).to be_falsey
      end
    end 

    context 'when record does not exist yet' do
      it 'adds a new record' do
        expect(@gand.update_record( @cur_ver, @ipv4, 'A')).to be_truthy
        expect(@api).to have_received(:add).with(anything, @cur_ver, @rec )
        expect(@api).to_not have_received(:update)
      end
    end

    context 'when record already exist' do
      before :each do
        @filter = { :name => @name, :type => @type }
        @res    = Hashie::Mash.new({:value => @ipv4})
        expect(@api).to receive(:list).with(anything(), @cur_ver, @filter).and_return([@res])
      end

      context 'and ip is different' do
        it 'updates the record' do
          @gand.update_record( @cur_ver, "#{@ipv4}1", 'A')
          expect(@api).to_not have_received(:add)
          expect(@api).to have_received(:update).once
        end

        it 'returns true' do
          expect(@gand.update_record( @cur_ver, "#{@ipv4}1", 'A')).to be_truthy
        end
      end

      context 'and ip is the same' do
        it 'does not update the record' do
          @gand.update_record( @cur_ver, @ipv4, 'A')
          expect(@api).to_not have_received(:add)
          expect(@api).to_not have_received(:update)
        end

        it 'returns false' do
          expect(@gand.update_record( @cur_ver, @ipv4, 'A')).to be_falsey
        end
      end
    end
  end

  describe '#clone_zone_version' do
    before :each do
      @src = 111
      @src_ret = [ 123, 456 ].map do |id|
                    Hashie::Mash.new({ :id    => id,
                                       :name  => "name#{id}",
                                       :type  => "type#{id}",
                                       :value => "value#{id}",
                                       :ttl   => "ttl#{id}" })
                  end
      @dest = 222
      @dest_ret = [ 123, 789 ].map do |id|
                    Hashie::Mash.new({ :id    => id,
                                       :name  => "name#{id}",
                                       :type  => "type#{id}",
                                       :value => "value#{id}-dest",
                                       :ttl   => "ttl#{id}-dest" })
                  end
      allow(@api).to receive(:list).with(anything(), @src).and_return(@src_ret)
      allow(@api).to receive(:list).with(anything(), @dest).and_return(@dest_ret)
    end

    it 'get the information from source zone' do
      expect(@api).to receive(:list).with(anything(), @src).and_return(@src_ret)
      @gand.clone_zone_version @src, @dest
    end
    
    it 'get the information from destination zone' do
      expect(@api).to receive(:list).with(anything(), @dest).and_return(@dest_ret)
      @gand.clone_zone_version @src, @dest
    end

    it 'deletes the record existing in destination zone but not in source zone' do
      expect(@api).to receive(:delete).with(anything(), @dest, {:id => 789})
      @gand.clone_zone_version @src, @dest
    end

    it 'update the record existing in both zone' do
      ret = @src_ret[0].to_hash.inject({}) { |acc,(k,v)| acc[k.to_sym] = v if k != 'id'; acc }
      expect(@api).to receive(:update).with(anything(), @dest, {:id => 123}, ret)
      @gand.clone_zone_version @src, @dest
    end

    it 'create the record existing only in source zone' do
      ret = @src_ret[1].to_hash.inject({}) { |acc,(k,v)| acc[k.to_sym] = v if k != 'id'; acc }
      expect(@api).to receive(:add).with(anything(), @dest, ret)
      @gand.clone_zone_version @src, @dest
    end
  end

  describe '#activate_updated_version' do
    context 'when activation succeeded' do
      it 'returns true' do
        expect(@gand.activate_updated_version(2)).to be_truthy
      end

      # it 'output activation of zone version successful' do
      #   @gand.activate_updated_version(2)
      #   expect(@output.string).to match /activation of zone version successful/
      # end
    end

    context 'when activation failed' do
      before :each do
        expect(@api).to receive(:set).with(anything(), 9).and_return(false)
      end
      it 'returns false' do
        expect(@gand.activate_updated_version(9)).to be_falsey
      end

      # it 'output activation of zone version failed' do
      #   @gand.activate_updated_version(9)
      #   expect(@output.string).to match /activation of zone version failed/
      # end

    end
  end

  describe '#update_ipv4' do
    pending 'not really necessary to test'
  end


  describe '#update_ips' do
    it 'take 1 input as parameter' do
      expect(@gand.update_ips('')).to be_truthy
    end

    context 'when input is not a String' do
      it 'raise an error' do
        expect{ @gand.update_ips(['1.2.3.4']) }.to raise_error(ArgumentError, /update is not a String/)
      end
    end

    context 'when no ip to update' do
      it 'returns true without doing anything' do
        allow(@gand).to receive(:get_zone_version)
        allow(@gand).to receive(:create_new_zone_version)
        allow(@gand).to receive(:clone_zone_version)

        expect(@gand.update_ips('')).to be_truthy

        expect(@gand).to_not have_received(:get_zone_version)
        expect(@gand).to_not have_received(:create_new_zone_version)
        expect(@gand).to_not have_received(:clone_zone_version)
      end

      it 'output no update needed' do
        @gand.update_ips('')
        expect(@output.string).to match /no update needed/
      end
    end

    context 'when ipv4 to update' do

      it 'updates ipv4 record' do
        expect(@gand).to receive(:update_ipv4).and_return(true)
        @gand.update_ips '1.2.3.4'
      end

      context 'when activation of new zone version is OK' do
        it 'returns true' do
          expect(@gand.update_ips('1.2.3.4')).to be_truthy
        end

        it 'output update done' do
          @gand.update_ips('1.2.3.4')
          expect(@output.string).to match /update done/
        end
      end

      context 'when activation of new zone version is KO' do
        before :each do
          expect(@gand).to receive(:get_zone_version).and_return([666, [666]])
          expect(@api).to receive(:set).with(anything(), 3).and_return(false)
        end

        it 'returns false' do
          expect(@gand.update_ips('1.2.3.4')).to be_falsey
        end

        it 'output update FAILED' do
          @gand.update_ips('1.2.3.4')
          expect(@output.string).to match /update FAILED/
        end
      end

      it 'activate the new zone version' do
        expect(@gand).to receive(:activate_updated_version).and_return(true)
        @gand.update_ips '1.2.3.4'
      end
    end

    context 'when only 1 zone version exists' do
      it 'creates a new version for the zone from current active version' do
        allow(@gand).to receive(:clone_zone_version)
        mash = Hashie::Mash.new({:version => 1, :versions => [1]})
        allow(@api).to receive(:info).and_return(mash)
        expect(@api).to receive(:new_version).and_return(99)

        @gand.update_ips('1.2.3.4')

        expect(@gand).to_not receive(:clone_zone_version)
      end
    end

    context 'when more than 1 zone version exist' do
      it 'clone the last non active version of the zone' do
        expect(@gand).to receive(:clone_zone_version)
        @gand.update_ips('1.2.3.4')
        expect(@api).to_not receive(:new_version)
      end
    end
  end

  describe '#ipv4_available' do
    context 'when network is not available' do
      before :each do
        allow(@gand).to receive(:system).and_return(false)
      end

      it 'returns false' do
        expect(@gand.ipv4_available?).to be false
      end

      it 'output IPv4 network not available' do
        @gand.ipv4_available?
        expect(@output.string).to match /IPv4 network not available/
      end
    end

    context 'when network is available' do
      it 'returns true' do
        expect(@gand.ipv4_available?).to be true
      end

      it 'output IPv4 network available' do
        @gand.ipv4_available?
        expect(@output.string).to match /IPv4 network available/
      end
    end

    context 'on windows platform' do
      it 'redirect output to > NUL'
    end

    context 'on Linux platform' do
      it 'redirect output to > /dev/null 2>&1'
    end
  end

end
