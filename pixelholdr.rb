# pixelholdr.rb

require 'rubygems'

require 'bundler'
Bundler.require

include Magick

class Helpers

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

	def self.add_text(options = {})

		# Add the text watermarks
		watermark_text = options[:text]
		watermark = Magick::Draw.new
		watermark.fill = (options[:text_color]) ? "#{Helpers.get_hex(options[:text_color])}" : "white"

		# TODO: Choose font
		watermark.font = 'Helvetica Black'
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

end

class PixelHoldr < Sinatra::Base

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

		# We are going to use JPG as the file format because it shouldn't really
		# make any difference in most use cases what format the image is delivered in.
		# But anyways, TODO: Add an option to specify the file format
		file_extension = 'jpg'

		file_path = "./img/#{subject_string}-#{dimensions}-#{options_string}".gsub(/:|,/, "-").gsub(' ', '_') + ".#{file_extension}"

		unless File.exist?(file_path)

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

			action_case = subject[0] if subject.length > 1

			case action_case
			when 'color'

				img = Magick::Image.new(x, y) do
					self.background_color = Helpers.get_hex(subject[1])
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

				grad = Magick::GradientFill.new(0, 0, end_x, end_y, Helpers.get_hex(colors[0]), Helpers.get_hex(colors[1])) 

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

				dimensions_annotation = Helpers.add_text({ 
						:text => "#{x} #{215.chr} #{y}", 
						:text_color => options[:text],
						:width => x,
						:height => y,
						:gravity => Magick::CenterGravity,
						:stroke_width => 20
					})

				img.composite!(dimensions_annotation, Magick::CenterGravity, Magick::OverCompositeOp)

			end


			unless photo.nil? 

				attribution_annotation = Helpers.add_text({
						:text => " #{photo.owner_name} on Flickr ",
						:text_color => options[:text],
						:width => x,
						:height => false,
						:gravity => Magick::SouthGravity,
						:stroke_width => 15
					})

				img.composite!(attribution_annotation, Magick::SouthGravity, Magick::OverCompositeOp)

			end

			File.open(file_path, 'w') { |file| file.write(img.to_blob) }

		end

		content_type 'image/jpg'

		open(file_path)

	end

end

PixelHoldr.run!