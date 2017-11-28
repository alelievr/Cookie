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
		_expCenter ("expCenter", Vector) = (0, 0, 0, 0)
		expRadius ("expRadius", float) = 2.7
		_AlphaDecay ("AlphaDecay", Range(0, 0.5)) = 0.2
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
//#pragma exclude_renderers d3d11
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
//			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

float	_Param;
float	_Phase;
float4	_LocalScale;
float Speed = .3;
float4 	_ObjectCenter;
float4 	_OffsetObj;
float3	expCenter;
float4	_expCenter;
float	_AlphaDecay;

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
				// o.uv = v.vertex.xyz+_Offset.xyz;
				o.org = _WorldSpaceCameraPos.xyz - _ObjectCenter.xyz*1. ;
				//  o.uv = v.uv+_Offset.xyz;
				// o.uv = mul(v.uv.xyz+_Offset.xyz, UNITY_MATRIX_TEXTURE0);
				// o.uv = mul(v.vertex.xyz+_Offset.xyz, UNITY_MATRIX_TEXTURE0);
				// o.uv = TRANSFORM_TEX(v.uv, _Volume);
				return o;
			}
    
// #define _Time.x (fmod(_Time.x, 1.))

	float Map(float3 Position)
	{
		//Position += float3(0, _Phase*Speed*.1, 0);
	    float3 P = (Position+1.*tex3D(_Volume,Position*2.+_Phase*Speed*.2).www*.02);
		// float3 P = Position + float3(0, _Phase, 0);

	    float C = tex3D(_Volume,P).w;
	    // C *= 5.*tex3D(_Volume,P*float3(.5,1,.5)).w;
	    	C = C*.9+.1*pow(tex3D(_Volume,P*5.1).w,2.);
		// return tex3D(_Volume, Position ).w;
		// was C-.3
	    return max((C-.3)*sqrt((Position.z-.1)/.3),0.)/.5;
	}

	float4	distfunc(float3 P)
	{
		float4	ret = 0;

		// ret.w = length(P)-2.5;//step(1.0, length(P)-.05);
		ret.xyz = ret.www;
		// ret = Map( (P-_OffsetObj)*_Param )*100.;
		ret = tex3D(_Volume, (P-_OffsetObj)*_Param).wwww;

	// ret += 10./(light*light)*float4(1.0, .01, .4, 1.);
		
		// ret = Map( (P-_OffsetObj)*_Param) ;
// ret.xyz = ret.www;
		return ret;
	}

float   noise(float3 p)
{
    return tex3D(_Volume, p).w;
}

	float expRadius;

// assign colour to the media
inline float3 computeColour( float density, float radius )
{
    // colour based on density alone. gives impression of occlusion within
    // the media
	float3 result = lerp( 1.1*float3(.0,0.,0.8), float3(0.4,0.15,.1), density );
    // float3 result = lerp( 1.1*float3(.80,0.2,0.), float3(0.104,0.15,.1), density );
    
    // colour added for nebula
    float3 colBottom = 3.1*float3(0.8,1.0,1.0);
    float3 colTop = 2.*float3(0.48,0.53,0.5);
    result *= lerp( colBottom*2.0, colTop, min( (radius+.5)/1.7, 1.0 ) );
    
    return result;
}

#define EXPLOSION_SEED	2.

// maps 3d position to colour and density
float densityFn( in float3 p, in float r, out float rawDens, in float rayAlpha )
{
	// p = -.90*p;///dot(p,p);
	// float2	q;
	// q.x = length(p.xz-expCenter.xz)-.51;
	// q.y = p.y-expCenter.y;
	// r = length(q) -.5;
//	p.x += .1*cos(_Phase+p.y);
//	p.z += .1*sin(_Phase+p.y);
    float l = length(p-0.5);//-0.5;
    float mouseIn = 0.75;
    float mouseY = 1.0 - mouseIn;
    float den = 5.*tex3D(_Volume, p-0*1*float3(-_Phase*.1, .0, .0)).w +0- .85*r;// - 1.5*r*(4.*mouseY+.5);

	// den = den*.5+ .25 * den * exp(1/r);

	// den = den * exp(1/(r*r));
	// den = den * exp(1/(abs(r)-.1));

    // float den = 5.*Map(p-1*float3(-_Phase*.1, .0, .0)) - .25*r;
    // offset noise based on seed
    // float t = .1;
    // float3 dir = float3(1.,1.,1.);
    
    // participating media    
	/*
    float f;
    float3 q = p - dir* t; f  = 0.50000*noise( q );
    q = q*2.02 - dir* t; f += 0.25000*noise( q );
    q = q*2.03 - dir* t; f += 0.12500*noise( q );
    q = q*2.40 - dir* t; f += 0.06250*noise( q );
    q = q*2.50 - dir* t; f += 0.03125*noise( q );
*/    
    // add in noise with scale factor
    rawDens = den;// +1.* 4.0*f;
    
    den = clamp(rawDens, 0., 1.);//clamp( rawDens, 0.0, 1.0 );
    
    // if (den>0.9) den = 1-.5*den;
    
    // thin out the volume at the far extends of the bounding sphere to avoid
    // clipping with the bounding sphere
    
	// den *= l*0.6-1.;//-smoothstep(0.8,0., 1);
    
    return den;
}

float	di(float3 p)
{
	float	ret = 1e5;

	ret = length(p.xyz);

	return ret;
}

		#define MAXSTEPS	100.
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
//				return float4(eyeray.d*.00001, 1.);
				float	tnear, tfar;
				bool hit = IntersectBox(eyeray, float3(-3,-3,-3)*3., 3.*float3(3,3,3), tnear, tfar );
				if (!hit)
					discard;//return float4(0,0,0,0);
					// LUL //discard; // much instructions such wow !!
				if (tnear < 0.)
					tnear = 0.;
				float3	pnear = eyeray.o + tnear * eyeray.d;
				float3	pfar = eyeray.o + tfar * eyeray.d;

				float3	vstep = (pnear - pfar) / MAXSTEPS;
				float3	P = pfar;
				float3	PP = 0;
				float2	dist = 0;
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
				// P += -1*float3(-_Phase*3.1, .0, .0);
				PP = eyeray.o + eyeray.d ;
				[loop]
				for(float i = 0.; i < MAXSTEPS; i++)
				{
					// P += .1*eyeray.d;
					if (s.a > .99)
						continue;
					float	rad = -0.105;//di(frac(.1*(P - expCenter - 1*float3(-_Phase*3., .0, .0)*1 ))-.5)+.25;
//s.argb += .1/(rad*rad);
//break;
					// if (rad > expRadius + .01) // always true
						// continue;

					float	dens, rawDens;

					dens = densityFn((P-_OffsetObj)*_Param, rad, rawDens, s.a);

					C = float4(computeColour(dens, rad), dens);
					// C = abs(dens)-.5*C*dens;//float4(computeColour(dens, rad), dens);
					//C.rgb = lerp(float3(.5,.2,.3), float3(.28, .3, .5), dens);
					C.a *= _AlphaDecay;//.2;
					C.rgb *= C.a;
					s = s + C*(1.-s.a);
// C+=.051;
					P += vstep;// - dens*.1*vstep;


					// dark debug magic

//					s = distfunc(P-1*float3(-_Phase*3.1, .0, .0));
					//s.w = clamp(s.w, 0., 60.);
					// C = s.a * s + (1. - s.a) * C;

					PP = pnear + (normalize(pfar-pnear)*dist.y );// * dist.y; 
					// FIXME : Position relative a la cam (doit etre fixe dans l espace)
					// FIXED 
					// commencer a pfar puis avancer de dir == normalize(pnear-pfar)*dist.y
					// doesn't work , wtf is this shit ?

					// PP = eyeray.o + eyeray.d * dist.y;

					PP += -1*float3(-_Phase*30.1, .0, .0);

					float	id = _expCenter.w*floor(((PP*(_OffsetObj.w))) ).x;
					/// aaaaaargh
					// WOUHOU
PP.y += sin(id*8.)*3.;
					if (dist.x < .01 && i > 1)
						continue; // skip sinuses
					// float	light = length(_expCenter.w*PP*(_OffsetObj.w));
					float	light = length(_expCenter.w*(frac(PP*(_OffsetObj.w))-.5))-.0125;
					dist.x = light;
					dist.y += dist.x;
					// if (s.a > 0. )
					h += 
					// dens
					// *
					1
					*
					.00001*1./(light*light*.5)
					//(.1/max(light*light, .085 ))
					*
					// float3(.1, .05, .82)
					// *
					float3
					(
						.15 // abs(sin(_expCenter.w*(floor((PP.x+PP.y+PP.z)*(_OffsetObj.w))-.5)+0.00))
						,
						.15 // abs(sin(_expCenter.w*(floor((PP.x+PP.y+PP.z)*(_OffsetObj.w))-.5)+1.04))
						,
						.95 // abs(sin(_expCenter.w*(floor((PP.x+PP.y+PP.z)*(_OffsetObj.w))-.5)+2.08))
					)
					;

					// if (s.a > 0. )
						// C += .0051/(light*light*.0006251+.1)*float4(0., .01, 1.4, 1.);
					// C += .01/(s*s+0.)*float4(.6, .5, .55, 1.);
					// P += vstep; // /(i*.01+1);
					//  C += float4((.6+float3(.6,.5,.4)*(exp(-s.w*10.)-s.w)),1)*s.w*(1.-C.a);
					// if (C.a>.99) break;
//					C += s*2.;//*float4(.50, .20, 1., 1);
					// C.xyz += .051/exp(length(P-pfar) * s.w);
					dbg++;
				}
				C = s*1.;
				C = C*C*(3.0-2.0*C);
				C = C*C*(3.0-2.0*C);
				C = C*C*(3.0-2.0*C);

				C.xyz += h;

				//return float4(1, 1,1, dbg / 500. );
//				C *= .5/exp(-length(P-pnear)*s.w);
				//C = s;
				// P -= vstep;
				//P = P + 
				//s = distfunc(P-0*float3(.0,-_Phase*5.1,.0));
				//C += .0051*s*float4(.5, .0, .2, 1);
				// C *=s.x;
				//C.xyz-=vstep;
				//C /= MAXSTEPS;

				// CHANGE WITH STEP()
				// if(C.x <= 0. || C.y <= 0. ||C.z <= 0.)
				//if (!(C.w != 0. && C.x < 0.))
				//	C.w = 0.; // there goes the black points ... 


			/*
			    float3 R = float3((i.uv.xyz) );
				//R *= _Param;
			    float3 P = float3(0, _Phase*Speed*1., 0);
			    float3 r = float3(0., 0., 0.);
		    	float4 C = float4(0,0,0,0);
		    	float M1;
				*/

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
				/*
				float3	dir = normalize(i.position - _WorldSpaceCameraPos.xyz );
				float3	org = i.org;
				float3	p;
				float2	dist = 0;
				float	ball;
				//for (float i = 0.; i < 30.; i++)

#define	STEP_CNT	60.
#define	STEP_SIZE	1./STEP_CNT
dist = 0.;
float4 dst = 0;
float3 stepDist = dir * STEP_SIZE;
		
		float3	pos = i.position-_OffsetObj;//org;//R;//i.position;
		for(int k = 0; k < STEP_CNT; k++)
		{
			pos = org + dist.y*dir;
//			float4 src = tex3D(_Volume, pos*_Param).aaaa;//tex2D(_MainTex, toTexPos(pos));
//			float	argh = Map(pos*_Param);
	        
//			dist.y = length(pos-argh)-2.;
			//src.xyzw = float4(argh, argh, argh, argh);
	        //Front to back blending
		    //dst.rgb = dst.rgb + (1 - dst.a) * src.a * src.rgb;
		   	//dst.a   = dst.a   + (1 - dst.a) * src.a;     
	        
	        //src.rgb *= src.a;

			dist.x = length(pos)-5.5;
			dist.y += dist.x;
			if (dist.x < .001)
			{
				dst.a = 1.;
				break;
			}

	        //dst += (1.0f - dst.a) * src + dst*.5; 
			pos += stepDist;


		}


		*/

		//dist.y*=.0251;
		
//		r.xyz = dst.aaa*1.;
		
		//+dist.y;
//		r.xyz = float3(dist.y, dist.y, dist.y);//dst.aaa;
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
//				C.xyzw = float4(r, dst.a);
				//C.w = length(C.xyz)*.5;
			    Color = C;//+float4(r, length(r)*1.);//+float4(float3(.5,.7,.9)-R.y*.4,1)*(1.-C.a);
				//Color.w = 1.;

	            return Color;
            }


			ENDCG
		}
	}
}
