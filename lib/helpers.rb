class Helpers

	def self.get_hex(color)
		"##{generate_color(color).downcase}"
	end

	def self.add_text(options = {})

		# Add the text watermarks
		watermark_text = options[:text]
		watermark = Magick::Draw.new
		watermark.fill = (options[:text_color]) ? "#{Helpers.get_hex(options[:text_color])}" : "white"

		case options[:font]
		when "courier"
			font = "Courier"
		else
			font = "Helvetica Black"
		end

		watermark.font = font
		watermark.stroke = "rgba(0,0,0,0.15)"
		watermark.stroke_width = options[:stroke_width]
		watermark.font_weight = Magick::BoldWeight
		watermark.pointsize = 500
		watermark.gravity = options[:gravity]
		watermark.interline_spacing = -500

		font_size = watermark.get_type_metrics(watermark_text)

		watermark_canvas = Magick::Image.new(font_size.width, font_size.height) do
			self.background_color = 'transparent'
		end

		watermark.annotate(watermark_canvas, 0, 0, 0, 0, watermark_text)

		watermark_height = options[:height] ? options[:height] * 0.8 : 20

		watermark_canvas.resize_to_fit!(options[:width] * 0.8, watermark_height)

		return watermark_canvas

	end


	private
	
	def self.generate_color(color)
	    return color.ljust(6, color)            if (1..2).include?(color.length)
	    return color.scan(/((.))/).flatten.join if color.length == 3
	    return color.ljust(6, '0')              if (4..5).include?(color.length)
	    return color[0..5]                      if color.length > 6
	    return color
	end

end