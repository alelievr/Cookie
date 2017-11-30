Shader "Cookie/PlanetSurfaceShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		[HideInInspector]_ObjectCenter ("Object Center", Vector) = (0, 0, 0)
		[HideInInspector]_LocalScale ("Local scale", Vector) = (1, 1, 1, 1)
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 100

		Blend SrcAlpha OneMinusSrcAlpha

		CGPROGRAM

		#pragma surface planetSurfaceFunc Standard vertex:vertFunc nofog alpha
		
		#include "UnityCG.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 tangent : TANGENT;
		};

		struct Input
		{
			float3 position;
			float3 origin;
			float3 normal;
		};

		float4	_LocalScale;
		float4 	_ObjectCenter;

		#define ITER	60
		#define EPSY	0.1
		
		void vertFunc (inout appdata v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.position = mul(v.vertex + _ObjectCenter / _LocalScale.xyz, unity_ObjectToWorld).xyz;
			o.origin = _WorldSpaceCameraPos - _ObjectCenter;
			o.normal = v.normal;
		}

		float map(float3 pos)
		{
			return length(pos) - (.99 * _LocalScale.x);
		}
		
		void planetSurfaceFunc (Input i, inout SurfaceOutputStandard o)
		{
			float3	dir = normalize(i.position - _WorldSpaceCameraPos.xyz);
			float3	org = i.origin;
			float4	col = float4(0, 0, 0, 0);
			float	t = 0;

			o.Albedo = float3(0, 0, 0);
			o.Emission = float3(i.position);
			o.Alpha = 1;
			// return ;

			for (int i = 0; i < ITER; i++)
			{
				float3 p = org + dir * t;

				float d = map(p);

				if (d < EPSY)
				{
					col = float4(0, 1, 1, 1);
					break ;
				}

				t += d;
			}

			o.Emission = col;
			o.Albedo = col;
			o.Alpha = 1;
			o.Normal = float3(0, 1, 0);
		}
		ENDCG
	}
}
