Shader "Cookie/PlanetUnderground"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		[HideInInspector]_ObjectCenter ("Object Center", Vector) = (0, 0, 0)
		[HideInInspector]_LocalScale ("Local scale", Vector) = (1, 1, 1, 1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 position : TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 	_ObjectCenter;
			float4	_LocalScale;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				
				o.position = mul(v.vertex + _ObjectCenter / _LocalScale.xyz, unity_ObjectToWorld).xyz;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 org = _WorldSpaceCameraPos - _ObjectCenter;
				float3 dir = normalize(i.position - _WorldSpaceCameraPos.xyz);

				return float4(-dir, 1);

				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				return col;
			}
			ENDCG
		}
	}
}
