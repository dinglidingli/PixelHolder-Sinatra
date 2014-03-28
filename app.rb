# app.rb

require 'rubygems'
require 'bundler'
require 'sinatra/base'
require 'github/markdown'

require 'pixelholder'

class App < Sinatra::Base

	error do
		"PixelHolder could not generate an image with the settings provided."
	end

	get '/' do
		md = File.read("./README.md")
		parsed_md = GitHub::Markdown.render(md)
		erb :index, :locals => {:body_content => parsed_md}
	end

	# Fill
	# /fill/300x500/extra_options
	# Gradient
	# /gradient/300x500/extra_options
	# Flickr
	# /flickr/300x500/extra_options
	get '/:type/:dimensions/?:extra_options?' do |type,dimensions,extra_options|
		options = {}

		unless extra_options.nil?
			extra_options.split(',').each do |option|
				key, value = option.split(':')
				options[key.to_sym] = value
			end
		end

		split_dimensions = dimensions.split('x')

		if split_dimensions[1].nil?
			options[:width] = options[:height] = split_dimensions[0]
		else
			options[:width], options[:height] = split_dimensions
		end

		# Replace double underscore with space if we have overlay text
		unless options[:text].nil?
			options[:text].gsub!("__", " ")
		end

		add_hash = lambda do |color_code|
			return "##{color_code}" unless color_code.nil?
			return nil
		end

		options[:background_color] = add_hash.call(options[:background_color])
		options[:text_color] = add_hash.call(options[:text_color])

		if type == "gradient"
			options[:start_color] = add_hash.call(options[:start_color])
			options[:end_color] = add_hash.call(options[:end_color])
		end

		options[:image_format] = options[:image_format] || 'jpg'

		content_type "image/#{options[:image_format]}"

		file_path = "./img/#{type}-#{dimensions}-#{extra_options}".gsub(/:|,/, "-").gsub(' ', '_') + ".#{options[:image_format]}"

		unless File.exist?(file_path)
			pixelholder = PixelHolder::Fill.new(options)
			File.open(file_path, 'w') { |file| file.write(pixelholder.canvas.to_blob()) }
		end

		open(file_path)
	end

end

App.run!
