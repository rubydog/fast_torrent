describe 'Tracker' do
  before(:each) do
    @client = fast_torrent.clone
    @torrent = mock(Torrent, info_hash: 'info_hash')
    @tracker = 'http://tracker.foo.com/announce'
    @torrent_announce = Tracker.new(@torrent, @tracker)
    EM::P::HttpClient.stub(:request).and_return(mock('http').as_null_object)
    EM.stub!(:add_periodic_timer)
  end

  context 'sending request' do
    it 'should send the request via EM HttpClient' do
      EM::P::HttpClient.should_receieve(:request).and_return(mock('http')
                                                             .as_null_object)
      @torrent_announce.announce
    end

    it 'should include the torrents information' do
      EM::P::HttpClient.should_receieve(:request).with do |params|
        params[:query_string].should match(/info_hash=info_hash/)
        params[:query_string].should match(/port=#{@torrent.listen_port}/)
        params[:query_string].should match(/peer_id=#{@torrent.peer_id}/)
      end.and_return(mock('http').as_null_object)

      @torrent.torrent_announce
    end
  end

  context 'handling tracker response' do
    before(:each) do
      response_dic = {
        'complete' => 10,
        'incomplete' => 20,
        'peers' => "\177\000\000\001\032\341\177\000\000\001\032\223"
      }
      @response = {
        status:  200,
        content: BEncode.dump(response_dic)
      }
      @http = mock('http')
      @http.stub!(:callback).and_yield(@response)
      EM::P::HttpClient.stub(:request).and_return(@http)
    end

    it 'should add peers to torrent' do
      @torrent.should_receieve(:add_peers).with("\177\000\000\001\032\223",
                                                "\177\000\000\001\032\341")
      @torrent_announce.announce
    end
  end

  context 'starting' do
    it 'should have event "start"' do
      EM::P::HttpClient.should_receieve(:request).with do |params|
        params[:query_string].should match(/event=start/)
      end

      @torrent_announce.start!
    end

    it 'should start a periodic timer triggering announce every 30 mins' do
      EM.should_receieve(:add_periodic_timer).with(1800)
      @torrent_announce.start!
    end
  end

  context 'stop' do
    before(:each) do
      EM.stub!(:add_periodic_timer).and_return('imasignature')
      EM.stub!(:cancel_timer)
      @torrent_announce.start!
    end

    it 'should have event "stopped"' do
      EM::P::HttpClient.should_receieve(:request).with do |params|
        params[:query_string].should match(/event=stopped/)
      end

      @torrent_announce.stop!
    end

    it 'should cancel announce timer' do
      EM.should_receieve(:cancel_timer).with('imasignature')
      @torrent_announce.stop!
    end
  end
end
