// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Cookie/VolumetricCloud"
{
	Properties
	{
		_Volume ("Volume", 3D) = "" {}
		_Param ("Float", float) = 0
		_Offset ("Offset", Vector) = (0, 0, 0, 0)
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
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

			struct appdata
			{
				float4 vertex : POSITION;
				float3 uv : TEXCOORD0;
			};

			struct v2f
			{
				float3 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler3D	_Volume;
			float4		_Offset;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.vertex.xyz+_Offset.xyz;
				// o.uv = v.uv+_Offset.xyz;
				// o.uv = mul(v.uv.xyz+_Offset.xyz, UNITY_MATRIX_TEXTURE0);
				// o.uv = mul(v.vertex.xyz+_Offset.xyz, UNITY_MATRIX_TEXTURE0);
				// o.uv = TRANSFORM_TEX(v.uv, _Volume);
				//UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
float	_Param;
float Speed = .3;
    
// #define _Time.x (fmod(_Time.x, 1.))

	float Map(float3 Position)
	{
	    float3 P = (Position*0.5+tex3D(_Volume,Position*2.+_Time.x*Speed*.2).www*.02);
    
	    float C = tex3D(_Volume,P).w;
	    C *= tex3D(_Volume,P*float3(.5,1,.5)).w;
	    C = C*.9+.1*pow(tex3D(_Volume,P*5.1).w,2.);
		// return tex3D(_Volume, Position ).w;
		// was C-.3
	    return max((C-.35)*sqrt((Position.z-.1)/.3),0.)/.5;
	}

            float4 frag (v2f i) : SV_Target
            {
				//return tex3D(_Volume, i.uv ).wwww; // all is in alpha ... I'm stupid
				//return float4(i.uv, 1);
                float4 Color = float4(0.,0.,0.,1.);//tex3D(_Volume, i.uv);

			    float3 R = float3((i.uv.xyz) );
				R *= _Param;
			    float3 P = float3(0,1.*_Time.x*Speed*1.,0);
			    float3 r = float3(0., 0., 0.);
		    	float4 C = float4(0,0,0,0);
		    	float M1;
	    		for(float I = .2;I<.5;I+=.01)
	    		{
	    		    M1 = Map(P*1.+R*I);
			//        float M2 = Map(P+R*I);
			        C.xyzw += float4((.6+float3(.6,.5,.4)*(exp(-M1*10.)-M1)),1)*M1*(1.-C.a);
		    	    r += .005/ ((length(R-float3(-.5,.25, 1.5) )-.5)*(length(R-float3(-.5,.25, 1.5) )-.5 )+.00 )*float3(.0,.2,.5);
		    	    //r += .01/ (M1*M1+2.1)*float3(.0,.2,.5);
		    	    //if (C.a>.99) break;
			    }
				C.xyz += r;
				//C.w = length(C.xyz)*.5;
			    Color = C;//+float4(r, length(r)*1.);//+float4(float3(.5,.7,.9)-R.y*.4,1)*(1.-C.a);
				//Color.w = 1.;

	            return Color;
            }


			ENDCG
		}
	}
}
