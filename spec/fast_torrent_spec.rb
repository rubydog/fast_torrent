describe 'FastTorrent' do

  it 'should have 20 bytes peer id' do
    expect(fast_torrent.peer_id.bytes.count).to eq(20)
    expect(fast_torrent.peer_id).not_to be_nil
  end

  it 'should have port number' do
    expect(fast_torrent.port).to eq(6881)
  end

  it 'adds new torrent for downloading' do
    expect{fast_torrent.instance.add(tom_single_file_torrent)}.
      to change{fast_torrent.instance.downloading.count}.by(1)
  end
end
