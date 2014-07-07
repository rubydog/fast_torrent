describe 'Protocol' do
  INFO_HASH = 'fooba' * 4
  PEER_ID   = 'lorem' * 4

  before(:each) do
    @protocol = Protocol.new
  end

  context 'incoming data' do
    context 'receive handshake' do
      it 'should have an incoming handshake msg' do
        @protocol << "\023BitTorrent protocol\000\000\000\000\000\000\000\000#{INFO_HASH}#{PEER_ID}"
        @protocol.incoming_messages.first.should == [BTMessage::HANDSHAKE,
                                                     19, 'BitTorrent protocol',0,0,0,0,0,0,0,0, INFO_HASH, PEER_ID]
      end

      it 'should have no incoming message for partial handshade' do
        @protocol << "\023BitTorrent protocol\000\000\000\000\000\000\000\000#{INFO_HASH}"
        @protocol.incoming_messages.empty?.should == true
      end
    end

    context 'handshaded connnection' do
      before(:each) do
        @protocol << "\023BitTorrent protocol\000\000\000\000\000\000\000\000#{INFO_HASH}#{PEER_ID}"
        @protocol.incoming_message
      end

      it 'should handle keep alive messages' do
        10.times { @protocol << "\000\000\000\000" }
        incoming_messages = @protocol.incoming_messages
        incoming_messages.size.should == 10
        incoming_messages.first.should == [BTMessage::KEEP_ALIVE]
      end

      it 'should handle choke messages' do
        @protocol << "\000\000\000\001\000"
        @protocol.incoming_messages.first.should == [BTMessage::CHOKE]
      end

      it 'should handle unchoke messages' do
        @protocol << "\000\000\000\001\001"
        @protocol.incoming_messages.first.should == [BTMessage::UNCHOKE]
      end

      it 'should handle interested messages' do
        @protocol << "\000\000\000\001\002"
        @protocol.incoming_messages.first.should == [BTMessage::INTERESTED]
      end

      it 'should handle uninterested messages' do
        @protocol << "\000\000\000\001\003"
        @protocol.incoming_messages.first.should == [BTMessage::UNINTERESTED]
      end

      it 'should handle have messages' do
        @protocol << "\000\000\000\005\004\000\000\000\f"
        @protocol.incoming_messages.first.should == [BTMessage::HAVE, 12]
      end

      it 'should handle bitfield messages' do
        @protocol << "\000\000\000\020\005\000\000\000\000\000\000\000\000\000\000\000\000\000\000\200"
        @protocol.incoming_messages.first.should == [BTMessage::BITFIELD,
                                                     "\000\000\000\000\000\000\000\000\000\000\000\000\000\000\200"]
      end

      it 'should handle request messages' do
        @protocol << "\000\000\000\r\006\000\000\000\f\000\000\000\002\000\000@\000"
        @protocol.incoming_messages.first.should == [BTMessage::REQUEST, 12,2,16*1024]
      end

      it 'should handle piece messages' do
        data  = "\000" * (2**14)
        @protocol << "\000\000@\t\a\000\000\000\000\000\000\000\000" + data
        @protocol.incoming_messages.first.should == [BTMessage::PIECE, 0,0, data]
      end

      it 'should handle cancel messages' do
        @protocol << "\000\000\000\r\b\000\000\000\f\000\000\000\002\000\000@\000"
        @protocol.incoming_messages.first.should == [BTMessage::CANCEL, 12,2,16*1024]
      end
    end
  end
end
