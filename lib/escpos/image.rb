module Escpos
  class Image

    VERSION = "0.0.1"

    def initialize(image_path, opts = {})
      @printer = opts.fetch(:printer, Printer.new)
      if opts.fetch(:convert_to_monochrome, false)
        require_mini_magick!
        image = convert_to_monochrome(image_path, opts)
        @image = ChunkyPNG::Image.from_file(image.path)
      else
        @image = ChunkyPNG::Image.from_file(image_path)
      end

      unless @image.width % 8 == 0 && @image.height % 8 == 0
        raise ArgumentError.new("Image width and height must be a multiple of 8.")
      end
    end

    def to_escpos
      
      stream = ""

      0.upto(@image.height - 1) do |y|
        bits = []
        mask = 0x80
        i = 0
        temp = 0

        0.upto(@image.width - 1) do |x|
          r, g, b, a =
            ChunkyPNG::Color.r(@image[x, y]),
            ChunkyPNG::Color.g(@image[x, y]),
            ChunkyPNG::Color.b(@image[x, y]),
            ChunkyPNG::Color.a(@image[x, y])
          px = (r + g + b) / 3
          raise ArgumentError.new("PNG images with alpha are not supported.") unless a == 255
          value = px > 128 ? 255 : 0
          # puts "#{x}/#{y} = #{value}"
          value = (value << 8) | value
          temp |= mask if value == 0
          mask = mask >> 1
          i = i + 1
          if i == 8
            # puts "y=#{y}, x=#{x}, temp=#{temp}"
            bits << temp
            mask = 0x80
            i = 0
            temp = 0
          end
        end

        n1 = (bits.length*8) % 256
        n2 = (bits.length*8) / 256
        puts "bits.length = #{bits.length}, n1 = #{n1}, n2 = #{n2}"
        stream += [
          @printer.sequence(:IMAGE),
          [n1, n2].pack("CC"),
          bits.pack("C*"),
          @printer.sequence(:CTL_CR),
          @printer.sequence(:CTL_LF)
        ].join
      end
      
      
      # [
      #   @printer.sequence(:IMAGE),
      #   [@image.width / 8, @image.height ].pack("CC"),
      #   bits.pack("C*")
      # ].join

      # n1 = @image.width % 256
      # n2 = @image.width / 256
      # puts "bits.length = #{bits.length}, n1 = #{n1}, n2 = #{n2}"
      # [
      #   @printer.sequence(:IMAGE),
      #   [n1, n2].pack("CC"),
      #   bits.pack("C*"),
      #   @printer.sequence(:CTL_LF)
      # ].join

      stream
    end

    private

    def require_mini_magick!
      unless defined?(MiniMagick)
        begin 
          require 'mini_magick'
        rescue LoadError => e
          raise 'Required options need the mini_magick gem installed.'
        end
      end
    end

    def convert_to_monochrome(image_path, opts = {})
      image = MiniMagick::Image.open(image_path)
      image.flatten
      image.grayscale 'Rec709Luma'
      if opts.fetch(:dither, true)
        image.monochrome
      else
        image.monochrome '+dither'
      end
      if opts.fetch(:extent, true)
        image.extent "#{(image.width/8.0).round*8}x#{(image.height/8.0).round*8}"
      end
      image
    end

  end
end
