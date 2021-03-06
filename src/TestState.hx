package;

import openfl.display.BitmapData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.graphics.frames.FlxAtlasFrames;

class TestState extends FlxState {
	
	// generic sprit
	var sprite:FlxSprite;
	// shader magic
	var shader:SpotlightShader;
	// info to pass into the shader, encoded as RGB
	var posTex:BitmapData;
	
	var radius:Float = 40;
	var maxRadius:Float = 80;
	var minRadius:Float = 20;
	var radiusIncr:Float = 0.5;
	
	// you have to hardcode stuff sometimes for shaders. This number shows up in the shader too
	// you can't pass this into the shader, gotta be hardcoded or else compile error
	final MAX_SPOTLIGHT_COUNT:Int = 3;
	
	override function create()
	{
		super.create();
		
		FlxG.cameras.bgColor = 0xffffff;
		
		sprite = new FlxSprite(0, 0, "assets/Untitled.png");
		add(sprite);
		
		posTex = new BitmapData(MAX_SPOTLIGHT_COUNT, 1, true, 0x0);
		
		// encode x,y positions into the bitmap. These positions are relative to the sprite not the screen
		// you could also add 2 more things per pixel, like the brightness or radius. Will do later
		posTex.setPixel32(0, 0, encodeSpotlight(100, 100, radius));
		posTex.setPixel32(1, 0, encodeSpotlight(200, 100, 25));
		posTex.setPixel32(2, 0, encodeSpotlight(300, 100, 50));
		
		// give the shader to the sprite
		shader = new SpotlightShader();
		sprite.shader = shader;
		
		// give the shader some info. Pass in the encoded bitmap as well as sprite bounds info
		shader.spotlightData.input = posTex;
		shader.spriteWH.value = [sprite.frameWidth, sprite.frameHeight];
		shader.screenWH.value = [640, 360];
		
		// add some velocity to prove that this will work when sprites move around
		// sprite.velocity.set(-10, 0);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		
		// vary the radius over time
		// you can do stuff like this inside the shader as well, if you pass in a "time" uniform variable
		
		radius += radiusIncr;
		
		if (radius >= maxRadius) {
			radius = maxRadius;
			radiusIncr *= -1;
		}
		
		else if (radius <= minRadius) {
			radius = minRadius;
			radiusIncr *= -1;
		}
		
		// the first light source (x,y) will be the relative mouse position
		// obv this can change per frame, so we edit the bitmap in update()
		// future: probably need to involve FlxCamera's offset or something
		posTex.setPixel32(0, 0, encodeSpotlight(FlxG.mouse.x - sprite.x, FlxG.mouse.y - sprite.y, radius));
	}

	function encodeSpotlight(x:Float, y:Float, radius:Float):Int {
		// this is the encoding function
		// good bit of credit to @Idenner in haxe discord!
		
		// scale xy from screen space into RGB
		// future: no clue how zoom affects this
		var xx = 255 * (x / 640);
		var yy = 255 * (y / 360);
		
		// if x,y is offscreen, set the radius of the spotlight to 0
		// after scaling, offscreen will be < 0 or > 255
		if (xx < 0 || xx > 255 || yy < 0 || yy > 255) radius = 0;
		
		// we limit the radius to 255 px because that's pretty big
		// you could scale this down so it fits into the encoded 32 bits, then scale it back up in the shader
		radius = Math.min(255, radius);
		
		// looks like alpha value is premultiplied into the RGBs when it passes through the shader, which alters the position data
		// future: some workaround?
		return 255 << 24 | Math.round(xx) << 16 | Math.round(yy) << 8 | Std.int(radius) << 0;
	}
}