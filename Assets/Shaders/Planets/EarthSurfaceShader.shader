Shader "Cookie/EarthSurfaceShader"
{
	Properties
	{
		_Seed ("Seed", Float) = 171
		_NoiseResolution ("Noise resolution", Float) = 1
		_TimeScale ("Time scale", Float) = 1
		_PlanetSize ("Planet size", Float) = .98

		[Space]
		_WaterPercent ("Water percent", Range(0, 2)) = 0
		_WaterColorAdjust ("Water color adjust", Range(0, 2)) = 1
		_TerrainAdjust ("Terrain height adjustment", Range(0, 1)) = .5

		_WaterColor1 ("Water color 1", Color) = (0, .2, 1)
		_WaterColor2 ("Water color 2", Color) = (0, .2, 1)

		_TerrainColor1 ("Terrain color 1", Color) = (1, 1, 1)
		_TerrainColor2 ("Terrain color 2", Color) = (.41, .54, .00)
		_TerrainColor3 ("Terrain color 3", Color) = (.91, .91, .49)

		[HideInInspector]_ObjectCenter ("Object Center", Vector) = (0, 0, 0)
		[HideInInspector]_LocalScale ("Local scale", Vector) = (1, 1, 1, 1)
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 100

		ZWrite On
		ZTest On
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
	
			#pragma vertex vert
			#pragma fragment frag

			#include "PlanetShader.cginc"

			#define PI 3.14159265359
			#define FOV (67.0 / 180.0 * PI)
			#define MAX 10000.0
			
			float	_PlanetSize;
			#define R (_PlanetSize * 1.025)
			
			float	_Seed;
			float	_NoiseResolution;
			float	_TimeScale;

			float	_WaterPercent;
			float	_TerrainAdjust;
			float	_WaterColorAdjust;
			
			float4	_WaterColor1;
			float4	_WaterColor2;
			
			float4	_TerrainColor1;
			float4	_TerrainColor2;
			float4	_TerrainColor3;

			float2 raytraceSphere(float3 p, float3 dir, float r)
			{
				float b = dot(p, dir);
				float c = dot(p, p) - r * r;
			
				float d = b * b - c;
				if (d < 0.0)
					return float2(MAX, -MAX);
				d = sqrt(d);
			
				return float2(-b - d, -b + d);
			}
		
			//###### noise
			// credits to iq for this noise algorithm
			
			/*float3x3 m = float3x3(
				0.00, 0.80, 0.60,
				-0.80, 0.36, -0.48,
				-0.60, -0.48, 0.64
			);*/
			
			float hash(float n)
			{
				return frac(sin(n) * 43758.5453);
			}
			
			float noise(in float3 x)
			{
				float3 p = floor(x);
				float3 f = frac(x);
			
				f = f * f * (3.0 - 2.0 * f);
			
				float n = p.x + p.y * 57.0 + 113.0 * p.z;
			
				float res = lerp(lerp(lerp(hash(n + 0.0), hash(n + 1.0), f.x),
							lerp(hash(n + 57.0), hash(n + 58.0), f.x), f.y),
						lerp(lerp(hash(n + 113.0), hash(n + 114.0), f.x),
							lerp(hash(n + 170.0), hash(n + 171.0), f.x), f.y), f.z);
				return res;
			}
			
			float fbm(float3 p)
			{
				p *= _NoiseResolution;
				float f;
				f = 0.5000 * noise(p);
				p = p * 2.02;
				f += 0.2500 * noise(p);
				p = p * 2.03;
				f += 0.1250 * noise(p);
				p = p * 2.01;
				f += 0.0625 * noise(p);
				return f;
			}
			
			//###### end noise
			
			float terrain(float3 p)
			{
				return fbm(p * 10.) / 5. + fbm(p + _Seed) - (1. / 5.);
			}
			
			float3 waterColor(float h)
			{
				return lerp(_WaterColor1, _WaterColor2, h * _WaterColorAdjust);
			}
			
			float3 terrainColor(float h)
			{
				// h *= 1.2;
				return h < .5 ?
					lerp(_TerrainColor1, _TerrainColor2, h * 2.) :
					lerp(_TerrainColor2, _TerrainColor3, (h - .5) * 2.);
			}
			
			float3 surfaceColor(float height, float longitude) {
				if (height < (1.-_WaterPercent))
					return terrainColor(1.0 - abs(longitude + height + _TerrainAdjust - 1.0));
				else
					return waterColor(height / _WaterPercent);
			}
	
			float4 render(float3 ro, float3 rd)
			{
				float2 d = raytraceSphere(ro, rd, _PlanetSize);
				float3 atmosphere = float3(.5, .5, .5);
				
				if (d.x < MAX - 1.0)
				{
					float3 hit = normalize(d.x * rd + ro);
					float h = (fbm(hit * 10.0 + _Seed) / 5.0 + fbm(hit + _Seed + _SinTime.x * _TimeScale)) - 0.2;
					return float4(surfaceColor(h, hit.y) * length(atmosphere * 1.5) * (atmosphere + 0.75), 1);
				}
				
				return float4(0, 1, 1, 0);
			}
			
			void mainImage(out float4 fragColor, float3 dir, float3 org)
			{
				fragColor = render(org, dir);
			}
	
			ENDCG
		}
	}
}
