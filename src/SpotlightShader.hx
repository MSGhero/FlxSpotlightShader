package;

import flixel.graphics.tile.FlxGraphicsShader;

class SpotlightShader extends FlxGraphicsShader {
	
	// openfl and flixel give you some good shader magic by default
	// we extend flixel's shader and link to the default stuff using #pragma
	// for the lighting effect itself, see the last bit of this shader
	
	// a fragment shader takes original pixel values and changes them up based on your shader function below
	// this code is happening per pixel, per frame
	@:glFragmentSource("
		#pragma header
		
		// uniforms are stuff we pass into the shader from outside
		// sampler2D is a bitmapdata
		uniform sampler2D spotlightData;
		
		uniform vec2 spriteWH;
		uniform vec2 screenWH;
		
		// hardcoded max spotlight count. A float so we can do some math with it
		const float MAX_SPOTLIGHT_COUNT = 3.0;
		
		void main(void) {
			
			// grab the original pixel color and save it
			// if the pixel is outside of every spotlight, its color is just the original color
			gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
			vec4 temp = gl_FragColor;
			
			// the default pixel position from OpenFL is a percentage, scale it up to real pixel values
			// the percentage is nice sometimes, I'm just not very used to it
			vec2 pos = openfl_TextureCoordv * spriteWH;
			
			// (a shader god could optimize the following)
			
			// for each spotlight, draw a black circle
			// we use the built-in `distance` function to do a 'point-in-circle' intersection check
			for (float i = 0.0; i < MAX_SPOTLIGHT_COUNT; i++) {
				
				// future: if the circle radius is 0, continue;
				
				// shaders use percents to index into bitmaps... texture2D is the bitmap index function
				// this grabs the < x = 0,1,2,..., y = 0 >-th pixel
				vec4 samp = texture2D(spotlightData, vec2(i / (MAX_SPOTLIGHT_COUNT - 1.0), 0.0));
				
				// scale it up by the screen size because I like pixels and not percents
				vec2 sampPos = samp.xy * screenWH;
				
				// we encoded the radius into the bitmap as well. Scale it up from a percent
				float radius = samp.z * 255;
				
				// point in circle check
				// this is equivalent to saying 'if the distance between the two points is less than the radius, set our pixel's RGB to 0'
				// we're multiplying the original RGB by either 0 or 1 basically, and remembering to give it alpha = 1
				gl_FragColor = vec4(gl_FragColor.rgb * step(radius, distance(sampPos, pos)), 1.0);
			}
			
			// for each spotlight, now draw a smaller circle, filled with your lighting effect
			// this deletes the unwanted outlines when circles intersect
			for (int i = 0.0; i < MAX_SPOTLIGHT_COUNT; i++) {
				
				vec4 samp = texture2D(spotlightData, vec2(i / (MAX_SPOTLIGHT_COUNT - 1.0), 0.0));
				vec2 sampPos = samp.xy * screenWH;
				float radius = samp.z * 255;
				
				// how big we want the outline of the circles to be
				float outlineThickness = 2.0;
				
				// two part condition, first is another point in circle check, but using a smaller radius this time (so the black circle from before ends up as an outline)
				// second part is making sure we're not adding lighting to pure black pixels, just leaving them alone
				bool shouldBlend = step(radius - outlineThickness, distance(sampPos, pos)) < 0.5 && temp.rgb != vec3(0.0);
				
				// this part can be anything, this is your 'blendmode'. I'm adding some lightness to the original pixel RGBs
				// you can pass some parameters in as part of the encoded bitmap OR do some math here based off the distance or whatever
				vec4 blended = vec4(temp.rgb + 0.2, 1.0);
				
				// the mix function, used with a boolean float (0.0 or 1.0), means pick the first one if false or the second one if true
				// we want to leave the pixel alone if we shouldn't blend it, or blend it if we want to
				gl_FragColor = mix(gl_FragColor, blended, float(shouldBlend));
			}
		}
	")
	
	public function new() {
		super();
	}
}