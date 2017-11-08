Shader "Cookie/StandardPlanetShader"
{
	Properties
	{
		_PlanetSize ("Planet size", Float) = 1
		_PlanetHole ("Planet Hole", Vector) = (.1, .1, .1)
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

		#pragma surface planetSurfaceFunc Standard vertex:vertFunc nofog alpha

		StandardPlanetSurface	planetSurface(inout StandardPlanetInput spi)
		{
			StandardPlanetSurface	spo;

			spo.color = float4(1, 1, 0, 1);

			return spo;
		}

		StandardPlanetSurface	planetUnderground(inout StandardPlanetInput spi)
		{
			StandardPlanetSurface	spu;
			
			spu.color = float4(0, 1, 1, 1);

			return spu;
		}
	
		ENDCG
	}
}
