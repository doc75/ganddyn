require 'spec_helper'

require 'ganddyn'

describe Ganddyn::IpResolver do

  before :each do
    @ip = Ganddyn::IpResolver.new( { :ipv4 => 'http://v4.rspec.domain.com', :ipv6 => 'http://v6.rspec.domain.com' } )
  end

  context '#intialize' do
    it 'takes 0 parameter' do
      expect(Ganddyn::IpResolver.new).to be_a Ganddyn::IpResolver
    end

    it 'take 1 parameter' do
      expect(Ganddyn::IpResolver.new({})).to be_a Ganddyn::IpResolver
    end

    it 'raises an error if parameter is not Hash' do
      expect { Ganddyn::IpResolver.new([]) }.to raise_error(ArgumentError, /urls is not a Hash/)
    end
  end

  context '#get_ipv4' do
    it 'returns the ipv4' do  
      stub_request(:get, 'v4.rspec.domain.com').to_return(:body => '1.2.3.4', :status => 200, :headers => { 'Content-Length' => 3 })
      expect(@ip.get_ipv4).to eq('1.2.3.4')
    end

    it 'returns empty string if client has no ipv4' do
      stub_request(:get, 'v4.rspec.domain.com').to_raise(Exception)
      expect(@ip.get_ipv4).to be_nil
    end

    it 'returns nil if server is not reachable' do
      stub_request(:get, 'v4.rspec.domain.com').to_raise(SocketError)
      expect(@ip.get_ipv4).to be_nil
    end

    it 'returns nil if url is incorrect' do
      stub_request(:get, 'v4.rspec.domain.com').to_return(:body => '<html><head>
<title>404 Not Found</title>
</head><body>
<h1>Not Found</h1>
<p>The requested URL xxx was not found on this server.</p>
<hr>
</body></html>', :status => 404, :headers => { 'Content-Length' => 3 })
      expect(@ip.get_ipv4).to be_nil
    end
  end

  context '#get_ipv6' do
    it 'returns the ipv6' do
      stub_request(:get, 'v6.rspec.domain.com').to_return(:body => '3b12:d24:1e6a:8e81:b6a2:6f67:5627:bf44', :status => 200, :headers => { 'Content-Length' => 3 })
      expect(@ip.get_ipv6).to eq('3b12:d24:1e6a:8e81:b6a2:6f67:5627:bf44')
    end

    it 'returns nil if client has no ipv6' do
      stub_request(:get, 'v6.rspec.domain.com').to_raise(Exception)
      expect(@ip.get_ipv6).to be_nil

    end

    it 'returns nil if server is not reachable' do
      stub_request(:get, 'v6.rspec.domain.com').to_raise(SocketError)
      expect(@ip.get_ipv6).to be_nil
    end

    it 'returns nil if url is incorrect' do
      stub_request(:get, 'v6.rspec.domain.com').to_return(:body => '<html><head>
<title>404 Not Found</title>
</head><body>
<h1>Not Found</h1>
<p>The requested URL xxx was not found on this server.</p>
<hr>
</body></html>', :status => 404, :headers => { 'Content-Length' => 3 })
      expect(@ip.get_ipv6).to be_nil
    end
  end
end
