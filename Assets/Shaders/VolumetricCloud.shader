// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Cookie/VolumetricCloud"
{
	Properties
	{
		_Volume ("Volume", 3D) = "" {}
		_Scale ("Scale", Range(0, 0.1)) = 0
		_Offset ("Offset", Vector) = (0, 0, 0, 0)
		_Phase ("Phase", float) = 0
		_ObjectCenter ("ObjectCenter", Vector) = (0, 0, 0, 0)
		_OffsetObj ("OffsetObj", Vector) = (0, 0, 0, 0)
		_LocalScale ("Local scale", Vector) = (1, 1, 1, 0)
		_expCenter ("expCenter", Vector) = (0, 0, 0, 0)
		_ColorOne ("ColorOne", Color) = (.0,0.5,0.8, 0)
		_ColorTwo ("ColorTwo", Color) = (0.4,0.15,.1, 0)
		expRadius ("expRadius", float) = 2.7
		_AlphaDecay ("AlphaDecay", Range(0, 0.5)) = 0.2
		[Space]_DensityMult ("Density Mult", Range(.25, 10)) = 1
	}
	SubShader
	{
Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Cull Front
        Lighting Off
        ZWrite Off
		Blend One One

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
            #pragma multi_compile _ PIXELSNAP_ON
            #pragma multi_compile _ ETC1_EXTERNAL_ALPHA
//            #include "UnitySprites.cginc"
//			#include "UnityCG.cginc"


float	_Scale;
float	_Phase;
float4	_LocalScale;
float Speed = .3;
float4 	_ObjectCenter;
float4 	_OffsetObj;
float3	expCenter;
float4	_expCenter;
float	_AlphaDecay;
float	_DensityMult;
float4	_ColorOne;
float4	_ColorTwo;
float4	_Lights[10];

			struct appdata
			{
				float4 vertex : POSITION;
				float3 uv : TEXCOORD0;
			};

			struct v2f
			{
				float3 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 position : TEXCOORD2;
				float3 org : TEXCOORD1;
			};

			sampler3D	_Volume;
			float4		_Offset;



// nvidia : http://http.download.nvidia.com/developer/presentations/2005/GDC/Sponsored_Day/GDC_2005_VolumeRenderingForGames.pdf

typedef struct s_Ray
{
	float3	o;
	float3	d;
}		Ray;

bool	IntersectBox(Ray r, float3 boxmin, float3 boxmax, out float tnear,
out float tfar)
{
	// compute intersection of ray with all six bbox planes
	float3 invR = 1.0 / r.d;
	float3 tbot = invR * (boxmin.xyz - r.o);
	float3 ttop = invR * (boxmax.xyz - r.o);
	// re-order intersections to find smallest and largest on each axis
	float3 tmin = min (ttop, tbot);
	float3 tmax = max (ttop, tbot);
	// find the largest tmin and the smallest tmax
	float2 t0 = max (tmin.xx, tmin.yz);
	tnear = max (t0.x, t0.y);
	t0 = min (tmax.xx, tmax.yz);
	tfar = min (t0.x, t0.y);
	// check for hit
	bool hit;
	if ((tnear > tfar))
		hit = false;
	else
	hit = true;
	return hit;
}





			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);				
				o.position = mul(v.vertex + _ObjectCenter / _LocalScale.xyz, unity_ObjectToWorld);
				o.uv = mul(v.vertex + 1.*_ObjectCenter-_Offset, unity_ObjectToWorld).xyz;
				o.org = _WorldSpaceCameraPos.xyz - _ObjectCenter.xyz*1. ;
				return o;
			}

	float expRadius;

float	di(float3 p)
{
	float	ret = 1e5;

	ret = length(p.xyz);

	return ret;
}

float3 computeColour( float density, float radius )
{
    // these are almost identical to the values used by iq
    
    // colour based on density alone. gives impression of occlusion within
    // the media
	// float3 result = lerp( 1.1*float3(.0,0.,0.8), float3(0.4,0.15,.1), density );
    float3 result = lerp( 1.1*float3(.80,0.2,0.), float3(0.104,0.15,.1), density );
    
    // colour added for nebula
    float3 colBottom = 3.1*float3(0.8,1.0,1.0);
    float3 colTop = 2.*float3(0.48,0.53,0.5);
    result *= lerp( colBottom*2.0, colTop, min( (radius+.5)/1.7, 1.0 ) );
    
    return result;
}

float	scene(float3 p, out float4 col)
{
    float4	objColor = float4(1, 0, 0, 1);
    float	cloudDensity = -(length(p) )*.05 + 5.*tex3D(_Volume, (p-_OffsetObj.xyz) * _Scale ).w;
	cloudDensity = 5.*tex3D(_Volume, (frac((p-_OffsetObj.xyz) * _Scale * .5)-.0)*.7 ).w;
	cloudDensity = (cloudDensity);
    float   de = -(length(p.xz)-2.1);

   if (de > .001)
       col = _ColorOne;

    return cloudDensity;//max(cloudDensity, de);
}

            float4 frag (v2f i) : SV_Target
            {
				expCenter = _expCenter.xyz;
				// return tex3D(_Volume, (i.uv-_OffsetObj)*_Param ).wwww*10.; // all is in alpha ... I'm stupid
				//return float4(i.uv, 1);
				//return float4(_Phase, 0,0, 1.);
                float4 Color = float4(0.,0.,0.,1.);//tex3D(_Volume, i.uv);
				float4 C = 0;

				Ray	eyeray;
				eyeray.o = i.org;
				// eyeray.o = _WorldSpaceCameraPos;
				eyeray.d = normalize(i.position - _WorldSpaceCameraPos.xyz );
				// return float4(eyeray.d*1.1, 1.);
				float	tnear, tfar;
				bool hit = IntersectBox(eyeray, float3(-3,-3,-3)*3., 3.*float3(3,3,3), tnear, tfar );
				// if (!hit)
					// discard;
				if (tnear < 0.)
				{
					tnear = 0.;
					
				}
				float3	pnear = eyeray.o + tnear * eyeray.d;
				float3	pfar = eyeray.o + tfar * eyeray.d;

				C = 0;
				/*
				
				F = 1/ e ^(t * d).

				Where t is the distance traveled through some media and 
				d is the density of the media. This is how cheap unlit fog has been calculated in games for quite some time. This comes from the Beer-Lambert law which defines transmittance through a volume of particles as: 

				Transmittance = e ^ (-t * d).
				
				*/
				float3	h = 0;
				float4	s = 0;
				float	dbg = 0;
				float	dens, rawDens;
				float3	dir = eyeray.d;//normalize(pnear-pfar);
				
const int nbSample = 150;

float4	color		= float4(0, 0, 0, 0);
float	zMax        = float(nbSample)*.25;
float	dstep        = zMax / float(nbSample);
float3	p           = pnear ;// * 30;
float	T			= 1;
float	absorption	= 1.;
	[loop]
	for(int i=0; i<nbSample; i++)
	{
    	float4 col;
    	float density = scene(p, col);
		//density += scene(p*2., col)*.5;
		//density += scene(p*4., col)*.25;
		//density += scene(p*8., col)*.125;
		//dstep = .25 / (1.+density);
    	if(density > 0.)
    	{
			// density += scene(p*.5, col);
        	float tmp = density / float(nbSample);
        	T *= 1. - tmp * absorption;
        	if( T <= 0.0001)
        	    break;

        	float light = 0;
        	float lightDensity = length(p + float3(5, -10, 5)) / zMax;

        	lightDensity = 1./(lightDensity * lightDensity);//pow(lightDensity, .7);

        	light = lightDensity * absorption / float(nbSample);

        	//Add ambiant + light scattering color
        	color += float4(lerp(_ColorOne.xyz, _ColorTwo.xyz, tmp-T), 1.) * 40. * tmp * T*1 + float4(lerp(_ColorOne.xyz, _ColorTwo.xyz, density -0 * exp(-density) ), 1) * light*80.*tmp;//80. * tmp * T * light;
    	}
    	p += dir * dstep;
	}				
				// color = color*color*(3.0-2.0*color);
				// color = color*color*(3.0-2.0*color);
				// color = color*color*(3.0-2.0*color);
				// C = s*1.;
				// color.w = 1;
				C = (color);
			    Color = C;
				// Color.w = 1.;

	            return Color;
            }


			ENDCG
		}
	}
}
