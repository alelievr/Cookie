Shader "Cookie/StandardPlanetShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "RenderQueue"="Transparent" }
		LOD 100

		ZWrite Off
		Cull Front

		Blend SrcAlpha OneMinusSrcAlpha		
	
		CGPROGRAM

		#include "PlanetShader.cginc"

		#pragma surface planetSurface Standard vertex:vert nofog

		StandardPlanetSurface	planetSurface(StandardPlanetInput spi)
		{
			StandardPlanetSurface	spo;


			return spo;
		}

		StandardPlanetSurface	planetUnderground(StandardPlanetInput spi)
		{
			StandardPlanetSurface	spu;

			return spu;
		}
	
		ENDCG
	}
}
