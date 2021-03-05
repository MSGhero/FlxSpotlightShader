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
		posTex.setPixel32(0, 0, getColorFromXY(100, 100));
		posTex.setPixel32(1, 0, getColorFromXY(200, 100));
		posTex.setPixel32(2, 0, getColorFromXY(300, 100));
		
		// give the shader to the sprite
		shader = new SpotlightShader();
		sprite.shader = shader;
		
		// give the shader some info. Pass in the encoded bitmap as well as sprite bounds info
		shader.circlePos.input = posTex;
		shader.wh.value = [sprite.frameWidth, sprite.frameHeight];
		
		// add some velocity to prove that this will work when sprites move around
		// sprite.velocity.set(-10, 0);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		
		// the first light source (x,y) will be the relative mouse position
		// obv this can change per frame, so we edit the bitmap in update()
		// future: probably need to involve FlxCamera's offset or something
		posTex.setPixel32(0, 0, getColorFromXY(FlxG.mouse.x - sprite.x, FlxG.mouse.y - sprite.y));
	}

	function getColorFromXY(x:Float, y:Float):Int {
		// this is the encoding function
		// good bit of credit to @Idenner in haxe discord!
		
		// clamp between 0 and screen width/height
		// ie offscreen spotlights
		x = Math.max(0, Math.min(x, 640));
		y = Math.max(0, Math.min(y, 360));
		
		// future: "if x,y is offscreen, set the radius of the spotlight to 0"
		
		// scale xy from screen space into RGB
		// future: no clue how zoom affects this
		var xx = 255 * (x / 640);
		var yy = 255 * (y / 360);
		
		// we can pass more info in where the 0 is
		// future: is 255 required? seems like openfl/flixel is deleting the info otherwise...
		return 255 << 24 | Math.round(xx) << 16 | Math.round(yy) << 8 | 0 << 0;
	}
}