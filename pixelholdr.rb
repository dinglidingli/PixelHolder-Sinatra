# pixelholdr.rb

require 'rubygems'

require 'bundler'
Bundler.require

include Magick

class PixelHoldr < Sinatra::Base

	configure do
	  MongoMapper.setup({'production' => {'uri' => "mongodb://localhost:27017/pixelholdr"}}, 'production')
	end

	class Placeholder
	  include MongoMapper::Document

	  key :key, String
	  key :url, String
	end

	class ColorHelpers

		def self.get_hex(color)
			case 
			when color.length == 1
				generated_color = color * 6
			when color.length == 2
				generated_color = color * 3
			when color.length == 3
				generated_color = (color[0] * 2) + (color[1] * 2) + (color[2] * 2)
			when color.length < 6 && color.length > 3
				generated_color = color + ("0" * (6 - color.length))
			when color.length > 6
				generated_color = color[0..5]
			else
				generated_color = color
			end

			return "##{generated_color}"
		end

	end

	error do 
		"PixelHoldr could not generate an image with the settings provided."
	end

	get '/:subject_string/:dimensions/?:options_string?' do |subject_string, dimensions, options_string|

		subject = subject_string.downcase.split(':')

		options = Hash.new(false)

		# Check if the options string is not nil or a numeric string
		unless options_string == nil || options_string =~ /^-?(\d+(\.\d+)?|\.\d+)$/ then

			# Assign each of the options to the hash
			options_string.split(',').each do |option|
				key, value = option.split(":")
				options[key.to_sym] = value
			end

			pos = (options[:seed]) ? options[:seed].to_i : 0

		else

			pos = options_string.to_i

		end

		key = "#{subject_string}-#{dimensions}-#{options_string}"

		if Placeholder.find_by_key(key).nil?

			default_width = 200

			dimensions = dimensions.downcase.split('x')

			# If X is 0 after setting to an integer, make minimum value
			x = dimensions[0].to_i
			if x == 0 then x = default_width end

			# If Y isn't set, set to X
			if dimensions[1].nil? 
				y = x
			else 
				# If X is 0 after setting to an integer, make minimum value
				y = dimensions[1].to_i
				if y == 0 then y = default_width end
			end

			# Seriously, who the hell would make a placeholder that's even this big?
			if x > 2500 || y > 2500
				halt "Sorry, the image dimensions you specified far exceed any reasonable placeholder size."
			end

			# We are going to use JPG as the file format because it shouldn't really
			# make any difference in most use cases what format the image is delivered in.
			# But anyways, TODO: Add an option to specify the file format
			file_extension = 'jpg'

			action_case = subject[0] if subject.length > 1

			case action_case
			when 'color'

				img = Magick::Image.new(x, y) do
					self.background_color = ColorHelpers.get_hex(subject[1])
					self.format = file_extension
				end

			when 'gradient'

				colors = subject[1].split(',')

				if colors[2].nil? || colors[2] == 'v'
					end_x = x
					end_y = 0
				else
					end_x = 0
					end_y = y
				end

				grad = Magick::GradientFill.new(0, 0, end_x, end_y, ColorHelpers.get_hex(colors[0]), ColorHelpers.get_hex(colors[1])) 

				grad_overlay = Magick::Image.new(x, y, grad)

				img = Magick::Image.new(x, y, grad) do
					self.format = file_extension
				end

			else

				flickr = Flickr.new('config/flickr.yml')

				# Grab all images with Creative Commons licencing
				photos = flickr.photos.search(:tags => subject[0], :tag_mode => 'all', :license => '4,5,6,7', :media => 'photo')

				photo = (pos.nil? || pos == 0) ? photos[0] : photos[pos]

				overlay = Magick::ImageList.new

				# The new image canvas
				img = Magick::Image.new(x, y) do
					self.background_color = 'black'
					self.format = file_extension
					self.quality = 90
				end

				unless photo.nil?
					url_image = open(photo.url(:large))
			
					# The flickr image
					overlay.from_blob(url_image.read) do
						self.format = file_extension
						self.quality = 100
					end

					# Make the image meet the dimensions
					overlay.resize_to_fill!(x, y)

					img.composite!(overlay, Magick::CenterGravity, Magick::CopyCompositeOp)
				end

			end

			# Hide the dimensions watermark if specified in the options
			# TODO: Custom text replacing dimensions
			unless options[:dimensions] == "hide" then 
				# Add the text watermarks
				watermark_text = "#{x} #{215.chr} #{y}"
				watermark = Magick::Draw.new
				watermark.fill = (options[:text]) ? "#{ColorHelpers.get_hex(options[:text])}" : "white"
				# TODO: Choose font
				watermark.font = 'Helvetica Black'
				watermark.stroke = "rgba(0,0,0,0.15)"
				watermark.stroke_width = 20
				watermark.font_weight = Magick::BoldWeight
				watermark.pointsize = 500
				watermark.gravity = Magick::CenterGravity
				watermark.interline_spacing = -500

				font_size = watermark.get_type_metrics(watermark_text)

				watermark_canvas = Magick::Image.new(font_size.width, font_size.height) do
					self.background_color = 'transparent'
				end

				watermark.annotate(watermark_canvas, 0, 0, 0, 0, watermark_text)
				watermark_canvas.resize_to_fit!(x * 0.8, y * 0.8)

				img.composite!(watermark_canvas, Magick::CenterGravity, Magick::OverCompositeOp)
			end


			unless photo.nil? 

				attribution_text = " #{photo.owner_name} on Flickr "

				attribution = Magick::Draw.new
				attribution.fill = (options[:text]) ? "#{ColorHelpers.get_hex(options[:text])}" : "white"
				# TODO: Choose font
				attribution.font = 'Helvetica Black'
				attribution.pointsize = 300
				attribution.stroke = "rgba(0,0,0,0.3)"
				attribution.stroke_width = 15
				attribution.font_weight = Magick::BoldWeight
				attribution.gravity = Magick::SouthGravity

				attr_font_size = attribution.get_type_metrics(attribution_text)

				attribution_canvas = Magick::Image.new(attr_font_size.width, attr_font_size.height) do
					self.background_color = 'transparent'
				end

				attribution.annotate(attribution_canvas, 0, 0, 0, 5, attribution_text)
				attribution_canvas.resize_to_fit!(x * 0.8, 20)

				img.composite!(attribution_canvas, Magick::SouthGravity, Magick::OverCompositeOp)

			end

			# Save the image
			file_path = key.gsub(":", "-").gsub(',', "-") + "." + file_extension

			File.open("./img/" + file_path, 'w') { |file| file.write(img.to_blob) }

			@placeholder = Placeholder.new({
				:key => key, 
				:url => "./img/" + file_path
			})

			@placeholder.save

		end

		content_type 'image/jpg'

		open(Placeholder.find_by_key(key).url)

	end

end

PixelHoldr.run!