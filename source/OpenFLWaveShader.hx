package;

import openfl.display.GraphicsShader;

class OpenFLWaveShader extends GraphicsShader
{
	@:glFragmentSource('
        #pragma header
        
        uniform float uTime;

		void main()
		{
            float deltaX =  (2.0 / 320.0) * sin(openfl_TextureCoordv.y * 80.0 * 3.14159 + uTime);
            float newX = max(0.0, min(openfl_TextureCoordv.x + deltaX, 1.0));
            vec2 waveCoord = vec2(newX, openfl_TextureCoordv.y);
			gl_FragColor = texture2D(bitmap, waveCoord);
        }')
        
    
	public function new()
	{
		super();
	}
}