PixelHolder
==========

PixelHolder is a self-hosted image placeholder generator built on top of [Sinatra](https://github.com/sinatra/sinatra). Using the Flickr API, Creative Commons licenced images are retrieved and cropped to your specified dimensions. The first load may be slow while the file is downloaded off Flickr, but generated images are cached on your harddrive and will be used instead if present.

If you want to integrate PixelHolder directly into your Ruby app, you can use the [PixelHolder RubyGem](https://rubygems.org/gems/pixelholder).

Installation
------------
1. Clone the repository
2. Navigate to the folder in the terminal
3. Run `bundle install`
4. Run `ruby app.rb`

Usage
-----
PixelHolder works with the following URL format

```
http://localhost:4567/{image type}/{image dimensions}/{optional image settings}
```

To add an image to your HTML, simply insert the URL in the `src` attribute of the `img` tag.

e.g.:
```
<img src="http://localhost:4567/fill/500x500/background_color:ff0000">
```

Image Type
----------
PixelHolder currently generates three types of image placeholders: image, solid fill, and gradient fill. The image type is specified in the first segment of the URL.

The image type can by specified by making the value either `fill`, `gradient`, or `flickr`

Image Dimensions
----------------
Dimensions can be specified in the second segment of the URL as either `{width}x{height}` for rectangular images or `{width}` for square images. e.g. 800x300

Optional Image Settings
-----------------------
For a list of options you can use, please refer to the [PixelHolder RubyGem](https://rubygems.org/gems/pixelholder) documentation.

Image settings are provided as comma separated entries and take a key:value format:

e.g.

```
background_color:ff0000,text:show_dimensions
```
