class Choker
  UNCHOKED_PEERS = 4
  def initialize(torrent)
    @torrent  = torrent
    @round    = 0
  end

  def start!
    choke!
    @choke_timer = EM.add_periodic_timer(10) { choke! }
  end

  def choke!
    interested_peers_to_unchoke = UNCHOKED_PEERS
    peers_sorted_by_rate.each do |peer|
      if interested_peers_to_unchoke > 0
        peer.unchoke! if peer.choked?
        interested_peers_to_unchoke -= 1 if peer.peer_interested?
      else
        peer.choke!
      end
    end

    choose_optimistic_choke if @round % 3 == 0
    @round += 1
  end

  def stop!
    EM.cancel_timer @choke_timer
  end

  private
  def peers_sorted_by_rate
    if @torrent.seeding?
      peers = @torrent.peer_connections.sort_by { |connection| connection.up_rate }
    else
      peers = @torrent.peer_connections.sort_by { |connection| connection.down_rate }
    end
    peers.reverse
  end

  def choose_optimistic_choke
    choked_and_interested = @torrent.peer_connections.select do |connection|
      connection.choked? && connection.peer_interested?
    end
    return if choked_and_interested.empty?

    peer = choked_and_interested[rand(choked_and_interested.size)]
    peer.unchoke!
  end
end
