# pixelholder.rb

require 'rubygems'
require 'bundler'
require 'flickr_fu'
require 'RMagick'

class PixelHolder

	# Initialize the object
	def initialize(subject, dimensions, extra_options)
		# In case we ever decide to allow extra formats for whatever reason
		@image_format = extra_options[:image_format]

		# Set image dimensions values
		dimensions = dimensions.downcase.split('x')
		default_dimension = 200

		@width = dimensions[0].to_i

		if dimensions[1].nil? then @height = @width
		else
			@height = dimensions[1].to_i
			if(@height == 0) then @height = default_dimension end
		end

		# Create image with background
		subject = subject.downcase.split(':')
		background_type = subject[0] if subject.length > 1

		case background_type
		when 'color'
			generate_canvas(subject[1])
		when 'gradient'
			gradient_colors = subject[1].split(',')

			if gradient_colors[2].nil? || gradient_colors[2] == 'v'
				end_x = @width
				end_y = 0
			else
				end_x = 0
				end_y = @height
			end

			fill_content = Magick::GradientFill.new(0, 0, end_x, end_y, get_hex(gradient_colors[0]), get_hex(gradient_colors[1])) 

			generate_canvas('000', fill_content)
		else
			seed = extra_options[:seed] ? extra_options[:seed].to_i : 0
			
			flickr = Flickr.new('config/flickr.yml')

			# Grab all images with Creative Commons licencing
			photos = flickr.photos.search(:tags => subject[0], :tag_mode => 'all', :license => '4,5,6,7', :media => 'photo')
			photo = photos[seed]

			generate_canvas()

			unless photo.nil?
				image_background = Magick::ImageList.new
				image_url = open(photo.url(:large))
				image_format = @image_format
		
				# Read the Flickr image as a blob
				image_background.from_blob(image_url.read) do
					self.format = image_format
					self.quality = 100
				end

				# Make the image meet the dimensions
				image_background.resize_to_fill!(@width, @height)
				@canvas.composite!(image_background, Magick::CenterGravity, Magick::CopyCompositeOp)
			end
		end
		
		# Text overlay
		if extra_options[:text]
			generate_overlay_text(extra_options[:text], extra_options[:text_color])
		end

	end

	# Returns a blob string of the generated image
	def get_blob
		@canvas.to_blob
	end

	# Returns a hex color code
	def get_hex(color)
		"##{generate_color(color).downcase}"
	end

	# Returns the appropriate color code string
	def generate_color(color)
	    return color.ljust(6, color)            if (1..2).include?(color.length)
	    return color.scan(/((.))/).flatten.join if color.length == 3
	    return color.ljust(6, '0')              if (4..5).include?(color.length)
	    return color[0..5]                      if color.length > 6
	    return color
	end

	# Generates an Imagick canvas
	def generate_canvas(background = '000', fill_content = nil)
		background = get_hex(background)
		image_format = @image_format

		if fill_content.nil?
			@canvas = Magick::Image.new(@width, @height) do 
				self.background_color = background
				self.format = image_format
			end
		else
			@canvas = Magick::Image.new(@width, @height, fill_content) do
				self.format = image_format
			end
		end
	end

	# Add a text overlay to the image
	def generate_overlay_text(string, color = false)
		if string == 'add_dimensions' then string = "#{@width} #{215.chr} #{@height}" end
	
		overlay_text = string
		overlay = Magick::Draw.new

		overlay.fill = color ? get_hex(color) : get_hex('fff')
		overlay.stroke = "rgba(0,0,0,0.15)"
		overlay.stroke_width = 20
		overlay.font_weight = Magick::BoldWeight
		overlay.pointsize = 500
		overlay.gravity = Magick::CenterGravity
		overlay.interline_spacing = -500

		font_size = overlay.get_type_metrics(overlay_text)

		overlay_canvas = Magick::Image.new(font_size.width, font_size.height) do
			self.background_color = 'transparent'
		end

		overlay.annotate(overlay_canvas, 0, 0, 0, 0, overlay_text)

		overlay_height = @height * 0.8

		overlay_canvas.resize_to_fit!(@width * 0.8, overlay_height)

		@canvas.composite!(overlay_canvas, Magick::CenterGravity, Magick::OverCompositeOp)
	end

	private :generate_canvas, :generate_overlay_text

end