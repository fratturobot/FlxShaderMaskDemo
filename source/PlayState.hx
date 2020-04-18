package;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxObject;
import flash.display.BlendMode;
import openfl.filters.ShaderFilter;
import flixel.FlxCamera;
import openfl.Vector;
import openfl.display.BitmapData;

using CameraExtension;

@:access(flixel.FlxGame)
class PlayState extends FlxState
{

    var _shapeCam:FlxShaderMaskCamera;
    var _waveShader:OpenFLWaveShader;
    var _waveTime:Float;

    var _bg:FlxSprite;
    var _floor:FlxObject;
    var _player:FlxSprite;

	override public function create():Void
	{
        super.create();
        _waveShader = new OpenFLWaveShader();
        _waveTime = 0;
        _shapeCam = new FlxShaderMaskCamera(_waveShader, 0, 0, FlxG.width, FlxG.height);
        _shapeCam.bgColor = FlxColor.BLUE;
        FlxG.cameras.reset(_shapeCam);

        FlxG.worldBounds.set(0, 0, 640, 180);
        FlxG.camera.setScrollBounds(0, 640, 0, 180);

        _floor = new FlxObject(0, 170, 640, 20);
        _floor.solid = true;
        _floor.immovable = true;
        add(_floor);

        var waveBackdrop = new FlxSprite(60, 110, AssetPaths.wave_backdrop__png);
        add(waveBackdrop);
        var waveSquare = new FlxSprite(120, 110);
        waveSquare.makeGraphic(60, 60, FlxColor.WHITE);
        _shapeCam.addMaskSprite(waveSquare);

        var manBackdrop = new FlxSprite(240, 20, AssetPaths.man_backdrop__png);
        add(manBackdrop);
        var waveMan = new FlxSprite(240, 20, AssetPaths.man__png);
        _shapeCam.addMaskSprite(waveMan);

        _player = new FlxSprite(30, 30, AssetPaths.miku__png);
        _player.maxVelocity.set(80, 200);
		_player.acceleration.y = 200;
		_player.drag.x = _player.maxVelocity.x * 4;
        add(_player);

        FlxG.camera.follow(_player);

	}

    var overlay: FlxSprite;

	override public function update(elapsed:Float):Void
	{
        _player.acceleration.x = 0;

		if (FlxG.keys.anyPressed([LEFT, A]))
		{
            _player.acceleration.x = -_player.maxVelocity.x * 4;
            _player.flipX = true;
		}

		if (FlxG.keys.anyPressed([RIGHT, D]))
		{
            _player.acceleration.x = _player.maxVelocity.x * 4;
            _player.flipX = false;
		}

		if (FlxG.keys.anyJustPressed([SPACE, UP, W]) && _player.isTouching(FlxObject.FLOOR))
		{
			_player.velocity.y = -_player.maxVelocity.y / 2;
        }
        
        _waveTime += 3*elapsed;
        if(_waveTime > 2 * Math.PI) _waveTime -= 2*Math.PI;
        _waveShader.uTime.value = [_waveTime];

        super.update(elapsed);

        FlxG.collide(_player, _floor);
    }
}
