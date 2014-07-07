describe 'TorrentData' do
  context 'single file torrent' do
    before(:each) do
      @info = BEncode.load_file(File.dirname(__FILE__) +
                                '/data/single_file.torrent')['info']
      FileUtils.mkdir_p('/test/fst/')
    end

    after(:each) do
      FileUtils.rm_rf('/test/fst/')
    end

    context 'creating torrent data' do
      it 'should create file' do
        TorrentData.new(@info, '/test/fst')
        File.exist?('/test/fst/single_file.data').should == true
      end
    end

    context 'torrent data' do
      before(:each) do
        @torrent_data = TorrentData.new(@info, '/test/fst/')
      end

      it 'should provide torrents piece count' do
        @torrent_data.piece_count.should == 4
      end

      it 'should provide hash of files' do
        @torrent_data.files.first[:path].should == '/test/fst/single_file.data'
      end


      context 'hashing' do
        context 'full file' do
          before(:each) do
            FileUtils.cp("#{TEST_DATA}/single_file.data", '/test/fst')
            @torrent_data = TorrentData.new(@info, '/test/fst/')
          end

          it 'should be complete' do
            @torrent_data.hash!
            @torrent_data.complete?.should == true
          end
        end

        context 'empty file' do
          before(:each) do
            @torrent_data = TorrentData.new(@info, '/test/fst/')
          end

          it 'should not be complete' do
            @torrent_data.hash!
            @torrent_data.complete?.should == false
          end
        end
      end
    end
  end
end
