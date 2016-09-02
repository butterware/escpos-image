require 'escpos'
require 'chunky_png'

@printer = Escpos::Printer.new(command_set: :esc_p)

image = Escpos::Image.new '/Users/bourgui/src/perso/bw/escpos-image/examples/small.png', convert_to_monochrome: true, printer: @printer

@printer.write @printer.sequence(:HW_SET_ESCP_MODE)       # ESC i a %d0
@printer.write @printer.sequence(:HW_INIT)                # ESC @
@printer.write @printer.sequence(:LINE_FEED_8)
# @printer.write @printer.sequence(:LANDSCAPE)              # ESC i L 0x01
# @printer.write @printer.sequence(:PAGE_LENGTH)            # ESC ( C 0x02 0x00 0x6a 0x04
# @printer.write @printer.sequence(:ABSOLUTE_HORIZONTAL_POSITION)                        # ESC $ 0x2C 0x01
# @printer.write @printer.sequence(:ABSOLUTE_VERTICAL_POSITION)                        # ESC ( V 0x02 0x00 0x1C 0x02
# @printer.write @printer.sequence(:TXT_FONT_HELSINKI)                        # ESC k 0x0b
# @printer.write @printer.sequence(:TXT_CHARACTER_SIZE)                        # ESC X 0x00 0x64 0x00
# @printer.write "Test"
# @printer.write @printer.sequence(:MARGIN_LEFT_ZERO)
@printer.write image.to_escpos
@printer.write @printer.sequence(:CTL_FF) # FF

puts @printer.to_escpos.chars.map{ |c| "0x#{c.unpack('H*').first}" }.join(' ')
# puts "\n"
# puts @printer.to_base64

puts "\nSending to printer\n"

cmd = %Q|curl -H 'X-Pretty: true' -X POST https://api.printnode.com/printjobs -u 252647d99138a849986e90c24b50ae037f24ee9f: -H 'Content-Type: application/json' -H 'Accept-Version: ~3' -d'{"printerId":"109788","title":"My Test PrintJob","contentType":"raw_base64","content":"#{@printer.to_base64}","source":"api documentation!"}'|

# puts cmd
system cmd