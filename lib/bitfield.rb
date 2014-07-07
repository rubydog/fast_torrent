class BitField
  attr_reader :size, :field
  include Enumerable

  ELEMENT_WIDTH = 8
  ALL_SET_VALUE = 2**8-1

  def initialize(size, field = nil)
    @size = size
    @field = field || Array.new(((size - 1) / ELEMENT_WIDTH) + 1, 0)
  end

  def self.create_with_data(data)
    size = data.length * ELEMENT_WIDTH
    new(size, data)
  end

  class SizeMismatchError < StandardError; end;

  def &(b)
    raise SizeMismatchError if b.size != @size

    intersection = BitField.new(@size)

    b.field.each_with_index do |b_element, idx|
      intersection.field[idx] = b_element.to_i & @field[idx].to_i
    end

    intersection
  end

  def inverse
    inverse = BitField.new(@size)

    @field.each_with_index do |element, idx|
      inverse.field[idx] = element ^ ALL_SET_VALUE
    end

    inverse
  end

  def []=(position, value)
    if value == 1
      @field[position / ELEMENT_WIDTH] |= 1 << (position % ELEMENT_WIDTH)
    elsif (@field[position / ELEMENT_WIDTH]) & (1 << (position % ELEMENT_WIDTH)) != 0
      @field[position / ELEMENT_WIDTH] ^= 1 << (position % ELEMENT_WIDTH)
    end
  end

  def [](position)
    @field[position / ELEMENT_WIDTH] & 1 << (position % ELEMENT_WIDTH) > 0 ? 1 : 0
  end

  def each(&block)
    @size.times { |position| yield self[position] }
  end

  def to_packed_s
    field.pack('C*')
  end

  def to_s
    inject("") { |a, b| a + b.to_s }
  end

  def clear
    @field.each_index { |i| @field[i] = 0 }
  end

  def total_set
    @field.inject(0) { |a, byte| a += byte & 1 and byte >>= 1 until byte == 0; a }
  end
end
