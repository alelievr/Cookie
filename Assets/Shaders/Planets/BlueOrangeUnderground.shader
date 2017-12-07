Shader "Cookie/BlueOrangeUnderground"
{
	Properties
	{
		[HideInInspector]_ObjectCenter ("Object Center", Vector) = (0, 0, 0)
		[HideInInspector]_LocalScale ("Local scale", Vector) = (1, 1, 1, 1)
        [HideInInspector]_SoundVolume ("Audio volume", Float) = 0
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

			void mainImage(out float4 fragColor, float3 dir, float3 org)
			{
				fragColor = float4(dir, 1);
			}

			ENDCG
		}
	}
}
