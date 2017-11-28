Shader "Cookie/texture3D"
{
	Properties
	{
		_Volume ("Volume", 3D) = "" {}
		_Offset ("Offset", Vector) = (0,0,0,0)
		_Zoom ("Zoom", float) = 1
		_Alpha ("alpha", float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent"}
		LOD 100

        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct vs_input {
				float4 vertex : POSITION;
				float4 pos : SV_POSITION;
			};
			
			struct ps_input {
				float4 pos : SV_POSITION;
				float3 uv : TEXCOORD0;
			};
			
			sampler3D		_Volume;
			float4			_Offset;
			float			_Zoom;
			float			_Alpha;
			
			ps_input vert (vs_input v)
			{
				ps_input o;
				o.pos = UnityObjectToClipPos (v.vertex);
				o.uv = mul (unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}
			
			float4 frag (ps_input i) : COLOR
			{
				float3 uv = i.uv * _Zoom+_Offset.xyz;
				// return tex3D (_Volume, i.uv);
				if (_Alpha > .1f)
					return float4(1, 1, 1, tex3D(_Volume, uv).a);
				else
					return float4(tex3D (_Volume, uv).aaaa);
			}

			ENDCG
		}
	}
}