PixelHoldr
==========

This is the source code for the PixelHoldr image placeholder generator. I have provided the code behind the site so that you may self-host the generator / help improve it / do what you want with it.

If you wish to use image placeholders without running this locally, please visit [PixelHoldr.com](http://pixelholdr.com).

Requirements
------------
MongoDB is used by PixelHoldr to keep track of image file paths. PixelHoldr will connect to the collection called `pixelholdr'.

Installation
------------
1. Clone the repository
2. Navigate to the folder in the terminal 
3. Run `bundle install`
4. Update `config/flickr.yml` with your Flickr API details
4. Run `ruby pixelholdr.rb`

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

For complete information about how to use the PixelHoldr service, please visit [PixelHoldr.com](http://pixelholdr.com).