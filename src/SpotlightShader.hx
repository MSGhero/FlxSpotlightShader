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
		uniform sampler2D circlePos;
		uniform vec2 wh;
		
		// hardcoded max spotlight count. A float so we can do some math with it
		const float MAX_SPOTLIGHT_COUNT = 3.0;
		
		void main(void) {
			
			// grab the original pixel color and save it
			// if the pixel is outside of every spotlight, its color is just the original color
			gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
			vec4 temp = gl_FragColor;
			
			// the default pixel position from OpenFL is a percentage, scale it up to real pixel values
			// the percentage is nice sometimes, I'm just not very used to it
			vec2 pos = openfl_TextureCoordv * wh;
			
			// (a shader god could optimize the following)
			
			// for each spotlight, draw a black circle
			// we use the built-in `distance` function to do a 'point-in-circle' intersection check
			for (float i = 0.0; i < MAX_SPOTLIGHT_COUNT; i++) {
				
				// future: if the circle radius is 0, continue;
				
				// shaders use percents to index into bitmaps... texture2D is the bitmap index function
				// this grabs the < x = 0,1,2,..., y = 0 >-th pixel
				vec4 samp = texture2D(circlePos, vec2(i / (MAX_SPOTLIGHT_COUNT - 1.0), 0.0));
				
				// scale it up by the screen size because I like pixels and not percents
				// future: you'd probably want to pass these in as uniforms
				vec2 sampPos = samp.xy * vec2(640.0, 360.0);
				
				// point in circle check
				if (distance(sampPos, pos) < 50.0) {
					
					// rgb = 0, alpha = 1
					gl_FragColor = vec4(vec3(0.0), 1.0);
				}
			}
			
			// for each spotlight, now draw a smaller circle, filled with your lighting effect
			// this deletes the unwanted outlines when circles intersect
			for (int i = 0.0; i < MAX_SPOTLIGHT_COUNT; i++) {
				
				vec4 samp = texture2D(circlePos, vec2(i / (MAX_SPOTLIGHT_COUNT - 1.0), 0.0));
				vec2 sampPos = samp.xy * vec2(640.0, 360.0);
				
				// two parts, first is another circle intersection, but using a smaller radius this time (so the black circle from before ends up as an outline)
				// second part is making sure we're not adding lighting to pure black pixels, just leaving them alone
				if (distance(sampPos, pos) < 48.0 && temp.rgb != vec3(0.0)) {
					
					// this part can be anything, this is your 'blendmode'. I'm adding some lightness to the original pixel RGBs
					// you can pass some parameters in as part of the encoded bitmap OR do some math here based off the distance or whatever
					
					// rgb += 0.2, alpha = 1
					gl_FragColor = vec4(temp.rgb + 0.2, 1.0);
				}
			}
		}
	")
	
	public function new() {
		super();
	}
}