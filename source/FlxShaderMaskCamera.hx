package;

import flixel.util.FlxColor;
import openfl.display.Sprite;
import openfl.display.BitmapData;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import openfl.display.Shader;
import openfl.display.GraphicsShader;
import openfl.display.OpenGLRenderer;
import flixel.system.FlxAssets.FlxShader;

@:access(flixel.FlxGame)
@:access(openfl.display.Graphics)
class FlxShaderMaskCamera extends FlxCamera {

    // Secondary camera used for rendering the 'mask' graphics to a buffer
    // In an ideal world we could use one camera with a depth buffer for this kind of thing,
    // but I have no idea how you'd do that within the constraints of OpenFL (open to advice)
    public var _maskCamera:FlxCamera;

    // Postprocessing filter used to apply the desired effect selectively to this camera's output
    // (based on the contents of the mask buffer)
    var _shaderMaskFilter:FlxShaderMaskFilter;

    // Collection of sprites that will be rendered to the mask buffer rather than the main camera.
    public var maskSprites:FlxTypedGroup<FlxSprite>;

    public function new(effectShader:Shader, X:Int = 0, Y:Int = 0, Width:Int = 0, Height:Int = 0, Zoom:Float = 0) {
        // create this camera (used for rendering the scene)
        super(X, Y, Width, Height, Zoom);
        // create secondary camera (used for rendering mask buffer)
        _maskCamera = new FlxCamera(X, Y, Width, Height, Zoom);
        _maskCamera.bgColor = FlxColor.BLACK;
        // add secondary camera to display hierarchy 
        FlxG.game.addChildAt(_maskCamera.flashSprite, FlxG.game.getChildIndex(FlxG.game._inputContainer));
        // set cacheAsBitmap so the mask camera will render into a buffer we can use
        _maskCamera.flashSprite.cacheAsBitmap = true;
        
        maskSprites = new FlxTypedGroup<FlxSprite>();
        _shaderMaskFilter = new FlxShaderMaskFilter(effectShader, _maskCamera);
        this.setFilters([_shaderMaskFilter]);
        this.filtersEnabled = true;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        maskSprites.update(elapsed);
    }

    @:allow(flixel.system.frontEnds.CameraFrontEnd)
	override function render():Void
	{
        _maskCamera.scroll.copyFrom(this.scroll);
        _maskCamera.clearDrawStack();
        _maskCamera.canvas.graphics.clear();
        _maskCamera.fill(_maskCamera.bgColor, false, 1);
        maskSprites.draw();
        _maskCamera.render();
        _shaderMaskFilter.reset();
        super.render();
        _maskCamera.canvas.graphics.__bounds = this.canvas.graphics.__bounds.clone();
    }
    
    public function addMaskSprite(sprite:FlxSprite) {
        maskSprites.add(sprite);
        sprite.camera = _maskCamera;
    }

    /* TODO
    This class will almost certainly need to override more methods in order to ensure that the mask camera and this camera
    have the same bounds, scale, zoom, etc., but in the interest of time I'll implement those later.
    */
}

@:access(openfl.display.OpenGLRenderer)
@:access(openfl.display.DisplayObject)
class FlxShaderMaskFilter extends BitmapFilter 
{
    var _effectShader:Shader;
    var _maskShader:FlxShaderMaskShader;
    var _baseBitmap:BitmapData;
    var _shapeCam:FlxCamera;

    public function new(shader:Shader, shapeCam:FlxCamera) {
        super();
        _effectShader = shader;
        _maskShader = new FlxShaderMaskShader();
        _shapeCam = shapeCam;
        // the first pass shades the screen, the second selectively applies
        // the results of the first pass based on the mask buffer
        __numShaderPasses = 2;
        __preserveObject = true;
    }

    // every frame, we set __preserveObject to true so we have access to a render buffer containing
    // the original contents of the camera. Then once we have that buffer we'll set it to false, so
    // that that buffer doesn't get drawn over the results of our shader passes
    // This is a workaround for something that's been fixed in the dev branch of OpenFL
    public function reset() {
        __preserveObject = true;
    }

    override private function __initShader (renderer:openfl.display.DisplayObjectRenderer, pass:Int):Shader {
        // On the first shader pass, we grab that buffer out of the renderer, and set some inputs on the shader we'll
        // be returning on the next pass. Then we return a shader that applies the desired effect to the entire camera area.
        if(pass == 0) {
            // this sneaky 'grab the last render target' trick won't be needed once the aforementioned
            // changes from dev OpenFL get released
            var glRend = cast(renderer, OpenGLRenderer);
            _baseBitmap = glRend.__defaultRenderTarget;
            // I feel like there should be a better way to access the cached bitmap of another display object,
            // but I haven't figured one out
            var _maskBitmap = _shapeCam.flashSprite.__cacheBitmapData;
            _maskShader.base.input = _baseBitmap;
            _maskShader.mask.input = _maskBitmap;
            return _effectShader;
        } 
        // On the second pass, we return the shader that merges the original and effect passes based on the
        // contents of the mask buffer
        else {
            // won't be needed with changes to dev OpenFL
            __preserveObject = false;
            return _maskShader;
        }
    }
}

class FlxShaderMaskShader extends GraphicsShader
{
    @:glFragmentSource('
        #pragma header
        
        // bitmap contains a copy of the original texture with the effect applied
        uniform sampler2D base; // original texture
        uniform sampler2D mask; // masking texture: black = no effect, white = effect applied

		void main()
		{
            vec4 baseColor = texture2D(base, openfl_TextureCoordv);
            vec4 effectColor = texture2D(bitmap, openfl_TextureCoordv);
            vec4 maskColor = texture2D(mask, openfl_TextureCoordv);
            // combine base and effect samples based on value of mask sample
			gl_FragColor = effectColor * maskColor.r + baseColor * (1.0-maskColor.r);
        }')
        
    
	public function new()
	{
		super();
	}
}