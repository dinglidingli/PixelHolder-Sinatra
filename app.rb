# app.rb

require 'rubygems'
require 'bundler'
require 'sinatra/base'
require 'github/markdown'

require './lib/pixelholder'

class App < Sinatra::Base

	error do 
		"PixelHoldr could not generate an image with the settings provided."
	end

	get '/' do 
		md = File.read("./README.md")
		parsed_md = GitHub::Markdown.render(md)
		erb :index, :locals => {:body_content => parsed_md}
	end

	get '/:subject_string/:dimensions/?:options_string?' do |subject_string, dimensions, options_string|
		options = Hash.new(false)

		unless options_string.nil?
			options_string.split(',').each do |option|
				key, value = option.split(':')
				options[key.to_sym] = value
			end
		end

		options[:image_format] = options[:image_format] ? options[:image_format] : 'jpg'

		content_type "image/#{options[:image_format]}"

		file_path = "./img/#{subject_string}-#{dimensions}-#{options_string}".gsub(/:|,/, "-").gsub(' ', '_') + ".#{options[:image_format]}"

		unless File.exist?(file_path)
			pixelholder = PixelHolder.new(subject_string, dimensions, options)
			File.open(file_path, 'w') { |file| file.write(pixelholder.get_blob()) }
		end

		open(file_path)
	end

end

App.run!
