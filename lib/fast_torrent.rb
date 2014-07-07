require 'singleton'

class FastTorrent
  include Singleton

  attr_accessor :torrents

  def initialize
    @torrents = []
    start_em_server
  end

  def peer_id
    '-BL0001-123456781234'
  end

  def port
    6881
  end

  def download_path
    '~/Downloads'
  end

  def register_torrent(torrent)
    @torrents << torrent
  end

  def register_peer(peer, info_hash, peer_id)
      torrent = @torrents.find { |t| t.info_hash == info_hash && t.state == :started }
      if torrent.nil?
        return false
      end
      torrent.peer_connected(peer)
      return true
    end

  private
  def start_em_server
    EM.start_server '127.0.0.1', port, PeerConnectionProper, self
    HttpServer.new(self).start!
  end

end
