Shader "Cookie/RaytracedSphere"
{
	Properties
	{
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

			#define MAX 10000
			
			float2 ray_vs_sphere(float3 p, float3 dir, float r)
			{
				float b = dot(p, dir);
				float c = dot(p, p) - r * r;
			
				float d = b * b - c;
				if (d < 0.0)
					return float2(MAX, -MAX);
				d = sqrt(d);
			
				return float2(-b - d, -b + d);
			}

			void mainImage(out float4 fragColor, float3 dir, float3 org)
			{
				float2 d = ray_vs_sphere(org, dir, 1);

				fragColor = float4(d.x*d.x*d.x/10, 0, 0, 1);
			}
		
			ENDCG
		}
	}
}
