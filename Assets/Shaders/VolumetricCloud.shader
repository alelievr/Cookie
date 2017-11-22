// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Cookie/VolumetricCloud"
{
	Properties
	{
		_Volume ("Volume", 3D) = "" {}
		_Param ("Float", float) = 0
		_Offset ("Offset", Vector) = (0, 0, 0, 0)
		_Phase ("Phase", float) = 0
		_ObjectCenter ("ObjectCenter", Vector) = (0, 0, 0, 0)
		_OffsetObj ("OffsetObj", Vector) = (0, 0, 0, 0)
		_LocalScale ("Local scale", Vector) = (1, 1, 1, 0)
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 100

		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Front

		Pass
		{
			CGPROGRAM
// Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct appdata members org)
#pragma exclude_renderers d3d11
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

float	_Param;
float	_Phase;
float4	_LocalScale;
float Speed = .3;
float4 	_ObjectCenter;
float4 	_OffsetObj;

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
				float3 position : TEXCOORD2;
				float3 org : TEXCOORD1;
			};

			sampler3D	_Volume;
			float4		_Offset;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);				
				o.position = mul(v.vertex + _ObjectCenter / _LocalScale.xyz, unity_ObjectToWorld);
				o.uv = mul(v.vertex + 1.*_ObjectCenter-_Offset, unity_ObjectToWorld).xyz;
				// o.uv = v.vertex.xyz+_Offset.xyz;
				o.org = _WorldSpaceCameraPos.xyz - _ObjectCenter.xyz*1. ;
				//  o.uv = v.uv+_Offset.xyz;
				// o.uv = mul(v.uv.xyz+_Offset.xyz, UNITY_MATRIX_TEXTURE0);
				// o.uv = mul(v.vertex.xyz+_Offset.xyz, UNITY_MATRIX_TEXTURE0);
				// o.uv = TRANSFORM_TEX(v.uv, _Volume);
				//UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
    
// #define _Time.x (fmod(_Time.x, 1.))

	float Map(float3 Position)
	{
	    float3 P = (Position*0.5+tex3D(_Volume,Position*2.+_Phase*Speed*.2).www*.02);
		// float3 P = Position + float3(0, _Phase, 0);

	    float C = tex3D(_Volume,P).w;
	    C *= tex3D(_Volume,P*float3(.5,1,.5)).w;
	    C = C*.9+.1*pow(tex3D(_Volume,P*5.1).w,2.);
		// return tex3D(_Volume, Position ).w;
		// was C-.3
	    return max((C-.3)*sqrt((Position.z-.1)/.3),0.)/.5;
	}

            float4 frag (v2f i) : SV_Target
            {
				//return tex3D(_Volume, i.uv ).wwww; // all is in alpha ... I'm stupid
				//return float4(i.uv, 1);
				//return float4(_Phase, 0,0, 1.);
                float4 Color = float4(0.,0.,0.,1.);//tex3D(_Volume, i.uv);

			    float3 R = float3((i.uv.xyz) );
				//R *= _Param;
			    float3 P = float3(0, _Phase*Speed*1., 0);
			    float3 r = float3(0., 0., 0.);
		    	float4 C = float4(0,0,0,0);
		    	float M1;

				/*
	    		for(float I = .2;I<1.;I+=.01)
	    		{
	    		    M1 = Map(P*1.+R*I);
			//        float M2 = Map(P+R*I);
			        C.xyzw += float4((.6+float3(.6,.5,.4)*(exp(-M1*10.)-M1)),1)*M1*(1.-C.a);
		    	    //r += .005/ ((length(R-float3(-.5,.25, 1.5) )-.5)*(length(R-float3(-.5,.25, 1.5) )-.5 )+.00 )*float3(.0,.2,.5);
		    	    //r += .01/ (M1*M1+2.1)*float3(.0,.2,.5);
		    	    //if (C.a>.99) break;
			    }*/
				float3	dir = normalize(i.position - _WorldSpaceCameraPos.xyz );
				float3	org = i.org;
				float3	p;
				float2	dist = 0;
				float	ball;
				//for (float i = 0.; i < 30.; i++)

#define	STEP_CNT	160.
#define	STEP_SIZE	1./STEP_CNT

float4 dst = 0;
float3 stepDist = dir * STEP_SIZE;
		
		float3	pos = R;//i.position;
		for(int k = 0; k < STEP_CNT; k++)
		{
			float4 src = tex3D(_Volume, pos*_Param).aaaa;//tex2D(_MainTex, toTexPos(pos));
	        
	        //Front to back blending
		    //dst.rgb = dst.rgb + (1 - dst.a) * src.a * src.rgb;
		   	//dst.a   = dst.a   + (1 - dst.a) * src.a;     
	        
	        //src.rgb *= src.a;
	        
	        dst = (1.0f - dst.a) * src + dst*.5; 
			pos += stepDist;
		}
		r.xyz = dst.aaa;
				/*
				for(float I = .2;I<1.;I+=.01)
				{
					p = org + (dist.y * dir);
					M1 = Map(P*0.+p);
					dist.x = M1;//length(p-_OffsetObj)-.1*_Param-Map(p-_Offset)*5.1;//length(p-_OffsetObj)-.1*_Param;
					ball = length(p-_OffsetObj)-.1;
					dist.x = M1;//min(dist.x, ball );
					//C.xyzw += float4((.6+float3(.6,.5,.4)*(exp(-M1*10.)-M1)),1)*M1*(1.-C.a);
					dist.y += dist.x;
					r += .5/ (ball*ball+.00 )*float3(.0,.2,.5);
					if ( (dist.x) < .001)
					{
						//C.w += .1;
						//continue;
						break;
					}
					if (C.w > .99)
						break;
				}
				if (dist.x < .001)// && dist.x == ball )
				r += dist.y*.1*float3(1,0,0);
				*/
				C.xyzw = float4(r, dst.a);
				//C.w = length(C.xyz)*.5;
			    Color = C;//+float4(r, length(r)*1.);//+float4(float3(.5,.7,.9)-R.y*.4,1)*(1.-C.a);
				//Color.w = 1.;

	            return Color;
            }


			ENDCG
		}
	}
}
