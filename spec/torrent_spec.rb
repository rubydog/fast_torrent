describe 'Torrent' do

  TEST_INFO_HASH = "\234\224\020|\3472v\257\200\005\214\246\367\342q\327hy\343\f"
  ANNOUNCE_URL = 'http://thomasballinger.com:6969/announce'

  before(:all) do
    @client = FastTorrent.clone
  end

  before(:each) do
    @torrent_data = mock(TorrentData, piece_size: 2**14, piece_count: 88).
      as_null_object
    @torrent = Torrent.new(@manager, File.dirname(__FILE__) + '/data/single_file.torrent')
  end

  it 'should provide the torrents info hash' do
    @torrent.info_hash.bytes.count.should == 20
    @torrent.info_hash.should == TEST_INFO_HASH
  end

  it 'should provide trackers' do
    @torrent.http_trackers.should include(ANNOUNCE_URL)
  end

  context 'starting torrent' do
    before(:each) do
      @torrent_announce = mock(TorrentTracker).as_null_object
      TorrentTracker.stub!(:start).and_return(@torrent_announce)
    end

    it 'should announce to the tracker' do
      TorrentTracker.should_receive(:start).with(@torrent, ANNOUNCE_URL)
      @torrent.start!
    end

    it 'should update state to started' do
      @torrent.start!
      @torrent.state.should == :started
    end

    it 'should hash the files' do
      @torrent_data.should_receive(:hash!)
      @torrent.start!
    end
  end

  context 'stopping torrent' do
    before(:each) do
      @torrent_announce = mock(TorrentTracker).as_null_object
      TorrentTracker.stub!(:start).and_return(@torrent_announce)
      @torrent.start!
    end

    it 'should stop tracker' do
      @torrent_announce.should_receive(:stop!)
      @torrent.stop!
    end

    it 'should close all peer connections' do
      peer_connection = mock('peer_connection')
      @torrent.peer_connections.push peer_connection
      peer_connection.should_receive(:close_connection)
      @torrent.stop!
    end
  end

  context 'interested in peer' do
    before(:each) do
      @bitfield = BitField.new(4)
      @bitfield[0] = 1
      @peer = mock(PeerConnection, bitfield: @bitfield)
      @torrent.torrent_data.stub!(:piece_count).and_return(4)
    end

    it 'should return true if peer has a piece we are missing' do
      bitfield = BitField.new(4)
      @torrent.torrent_data.stub!(:bitfield).and_return(bitfield)
      @torrent.interested_in_peer?(@peer).should == true
    end

    it 'should return false if peer has a subset of pieces we have' do
      bitfield = BitField.new(4)
      4.times { |n| bitfield[n] = 1 }
      @torrent.torrent_data.stub!(:bitfield).and_return(bitfield)
      @torrent.interested_in_peer?(@peer).should == false
    end
  end

  context 'received new piece' do
    before(:each) do
      @torrent.torrent_data.stub!(:received_piece).and_return(true)
    end

    it 'should send to torrent data' do
      @torrent.torrent_data.should_receive(:received_piece).and_return(true)
      @torrent.peer_received_piece(12, 'randomdat')
    end

    it 'should update downloaded amount by piece size' do
      @torrent.peer_received_piece(12, 'randomdat')
      @torrent.downloaded.should == @torrent.piece_size
    end
  end

end
