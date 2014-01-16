PixelHoldr
==========

PixelHoldr is a self-hosted image placeholder generator built on top of [Sinatra](https://github.com/sinatra/sinatra). Using the Flickr API, Creative Commons licenced images are retrieved and cropped to your specified dimensions. The first load may be slow while the file is downloaded off Flickr, but generated images are cached on your harddrive and will be used instead if present. 

I will be discontinuing the hosted service for PixelHoldr 23rd January 2014. If you feel like hosting PixelHoldr, please let me know and I will link to it here.

Requirements
------------
* Ruby 2.0.0
* Imagick

Installation
------------
1. Clone the repository
2. Navigate to the folder in the terminal 
3. Run `bundle install`
4. Update `config/flickr.yml` with your Flickr API details
5. Run `ruby pixelholdr.rb`

Usage
-----
PixelHoldr works with the following URL format 

```
http://localhost:4567/{image type}/{image dimensions}/{optional image settings}
```

To add an image to your HTML, simply insert the URL in the `src` attribute of the `img` tag. 

e.g.:
```
<img src="http://localhost:4567/cat/500">
```

Image Type
----------
PixelHoldr currently generates three types of image placeholders: image, solid fill, and gradient fill. The image type is specified in the first segment of the URL.

Image placeholders are automatically generated depending on the comma separated keywords specified. e.g., you can search for `brown,dogs` to search Flickr for brown dogs.

Solid fills are specified using the following syntax: `color:{hex color code}` e.g. color:333333. Do not use a hash (#) symbol

Gradient fills are specified using the following syntax: `gradient:{starting hex color code},{ending hex color code},{optional: gradient direction - h or v for horizontal and vertical}` e.g. gradient:ffffff,0099cc,h will produce a gradient that goes from white on the left to blue on the right. Gradient directions default to vertical.

Image Dimensions
----------------
Dimensions can be specified in the second segment of the URL as either `{width}x{height}` for rectangular images or `{width}` for square images. e.g. 800x300

Optional Image Settings
-----------------------
These optional image settings are put into the third segment of the URL as comma separated values

* `seed:{number}` e.g. seed:5 - Works only with images. Picks another image
* `dimensions:hide` Hides the dimensions overlay
* `text:{hex color code}` e.g. text:cc9900 - Changes the overlay text color. Do not use a hash (#) symbol
* `font:{courier|helveticablack}` e.g. font:courier - Changes the font used. Uses Helvetica Black by default
