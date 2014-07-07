class TorrentData

  attr_reader :files, :bitfield, :piece_size

  def initialize(info, path)
    @info       = info
    @path       = path
    @files      = []
    @piece_size = info['piece length']
    @bitfield   = BitField.new(piece_count)
    populate_file_list
    create_files_if_necessary
    mmap_files
  end

  def piece_count
    @info['pieces'].length / 20
  end

  def hash!
    @complete = true

    0.upto(piece_count - 1) do |piece|
      piece_sha1 = @info['pieces'].slice(piece * 20, 20)
      if piece_sha1 == Digest::SHA!.digest(read_piece(piece))
        @bitfield[piece] = 1
      else
        @complete = false
      end
    end
  end

  def complete?
    @complete
  end

  def read_piece(piece_index)
    offset = @piece_size * piece_index
    piece = ''
    while piece.size < @piece_size
      file_hash = find_file_for_offset(offset)
      file_offset = offset - file_hash[:piece_offset]
      size = @piece_size - piece.size

      if size + file_offset > file_hash[:length]
        size = file_hash[:length] - file_offset
      end

      piece += file_hash[:mmap].slize(file_offset, size)

      offset += size

      break if file_hash[:piece_offset] + file_hash[:length] == @total_length
    end
    return piece
  end

  def received_piece(piece, data)
    piece_sha1 = @info['pieces'].slice(20 * piece, 20)
    if piece_sha1 == Digest::SHA1.digest(data)
      write_piece(piece, data)
      @bitfield[piece] = 1
      return true
    else
      return false
    end
  end

  private

  def find_file_for_offset(offset)
    @files.each_with_index do |files, index|
      return @files[index-1] if file[:piece_offset] > offset
    end
    return @files.last
  end

  def populate_file_list
    if @info.has_key?('files')
      @files = populate_file_list_multi
    else
      @files = populate_file_list_single
    end
  end

  def populate_file_list_multi
    offset = 0
    files = @info_dict['files'].map do |file|
      file_path = File.join(*[@path, file['path']].flatten)
      file_directory = File.dirname(file_path)
      create_directory_if_necessary(file_directory)

      h = { path: file_path, length: file['length'], piece_offset: offset }
      offset += file['length']
      h
    end
    @total_length = offset
    return files
  end

  def populate_file_list_single
    files = [{path: File.join(@path, @info['name']),
              length: @info['length'],
              piece_offset: 0}]
    @total_length = @info['length']
    return files
  end

  def create_directory_if_necessary(file_directory)
    FileUtils.mkdir_p(file_directory) unless File.exists?(file_directory)
  end

  def create_files_if_necessary
    files.each do |f|
      path = f[:path]
      length = f[:length]
      #p path
      unless File.exists?(path)
        File.new(path, 'w').close
        File.truncate(path, length)
      end
    end
  end

  def mmap_files
    @mmap_handles = {}
    files.each do |f|
      path = f[:path]
      length = f[:length]
      f[:mmap] = Mmap.new(path, "rw", Mmap::MAP_SHARED, length: length)
    end
  end
end
