
Shader "Unlit/TunnelShader"
{	
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags {"Queue"="Transparent" "RenderType"="Transparent" }
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

/*
* License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
* Created by bal-khan
*/

float 	t;
float	a; // angle used both for camera path and distance estimator

#define I_MAX		100
#define E			0.001

#define	CAM_PATH 0			// only interesting for the default shape
							// take 0 or 1

//#define	PULSE			// uncomment this line to get it pulsing

//#define	OUTSIDE			// let you see the outside of the shape
//#define	COUNTOURED		// see another rendering mode
#define	CENTERED		// set the view in the middle
//#define	ALTERNATE_DE	// another shape
// #define	NO_MOUSTACHE	// only work with ALTERNATE_DE ENABLED
//#define	EXPERIMENTAL	// only work if ALTERNATE_DE is DISABLED
							// EXPERIMENTAL is beautiful with COUNTOURED enabled
#define	VIGNETTE_RENDER	// vignetting
#define		FWD_SPEED	-5.	// the speed at wich the tunnel travel

float4	march(float3 pos, float3 dir);
float3	camera(float2 uv);
float2	rot(float2 p, float2 ang);
void	rotate(inout float2 v, float angle);

// blackbody by aiekick : https://www.shadertoy.com/view/lttXDn

// -------------blackbody----------------- //

// return color from temperature 
//http://www.physics.sfasu.edu/astro/color/blackbody.html
//http://www.vendian.org/mncharity/dir3/blackbody/
//http://www.vendian.org/mncharity/dir3/blackbody/UnstableURLs/bbr_color.html

float3 blackbody(float Temp)
{
	float3 col = float3(255., 255., 255.);
    col.x = 56100000. * pow(Temp,(-3. / 2.)) + 148.;
   	col.y = 100.04 * log(Temp) - 623.6;
   	if (Temp > 6500.) col.y = 35200000. * pow(Temp,(-3. / 2.)) + 184.;
   	col.z = 194.18 * log(Temp) - 1448.6;
   	col = clamp(col, 0., 255.)/255.;
    if (Temp < 1000.) col *= Temp/1000.;
   	return col;
}

// -------------blackbody----------------- //
float accum;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.vertex = UnityObjectToClipPos(v.vertex);
				UNITY_TRANSFER_FOG(o, o.vertex);
				return o;
			}
			
			float4 frag (v2f i) : SV_Target
			{
				// sample the texture
				t = _Time.x*10.;
				float4 col_o = tex2D(_MainTex, i.uv);

				float3	col;

				// apply fog
//				UNITY_APPLY_FOG(i.fogCoord, col);
//float2 R = iResolution.xy,
//          uv  = float2(f-R/2.) / R.y;
	float2	uv = i.uv-.5;
	float3	dir = camera(uv);
    float3	pos = float3(.0, .0, 20.0);

    #ifndef OUTSIDE
    pos.z = t*FWD_SPEED;
	#endif
    
    accum = 0.0;
    
    float4	inter = (march(pos, dir));

    #ifndef COUNTOURED
    col.xyz = blackbody(( inter.w*.25)*150.1);
    #else
   	float countour = 5.*-inter.x;
    col.xyz = blackbody( inter.w*100. + countour);
	#endif
    #ifdef	VIGNETTE_RENDER
//    col.xyz = blackbody( ( (1.1-length(uv)*1.1)*inter.w) *200. );
    #endif
    			col_o =  accum*float4(col, 1.+sin(t) )*.0;
				return col_o;
			}

float	de_0(float3 p)
{
	float	mind = 1e5;
	float3	pr = p *.35;

	rotate(pr.xy, (a) );

	pr.xy *= 2.;
	pr.xyz = frac(pr.xyz);
	pr -= .5;
    #ifndef ALTERNATE_DE
    mind = length(pr.yz)-.3252;
  //  #ifdef	EXPERIMENTAL
 //   mind += (length(-abs(pr.zz)+abs(pr.xy)) - .91);
    //#endif
    //mind = min(mind, (length(pr.xyz)-1.15 ) );
    mind = min(mind, (length(pr.xy)-.352 ) );
	#else
     #ifndef NO_MOUSTACHE
    	mind = length(pr.yz+abs(pr.xx)*.2 )-.25;
     #else
    	mind = length(pr.yz )-.25;
     #endif
    #endif
    
	return (mind);
}

float	de_1(float3 p) // cylinder
{
	float	mind = 1e5;
	float3	pr = p;	
	float2	q;
    
	q = float2(length(pr.yx) - 4., pr.z );
    #ifdef PULSE
    q.y = rot(q.xy, float2(-1.+sin(t*10.), 0.)).x;
	#else
    q.y = rot(q.xy, float2(-1., 0.)).x;
    #endif
	mind = length(q) - 5.5;

	return mind;
}

// add 2 distances to constraint the de_0 to a cylinder
float	de_2(float3 p)
{
    #ifndef OUTSIDE
    return (de_0(p)-de_1(p)/8.);
    #else
    return (de_0(p)+de_1(p)/8.);
    #endif
}

float	scene(float3 p)
{
    float	mind = 1e5;
    a = (t*1.5) + 1.5*cos( .8*(p.y*.015+p.x*.015+p.z *.15)  + t);
    #ifdef	CAM_PATH
    float2	rot = float2( cos(a+1.57), sin(a+1.57) );
    #else
    float2	rot = float2( cos(t*.5), sin(t*.5) );
    #endif
    #ifndef CENTERED
	 #ifdef	CAM_PATH
      #if CAM_PATH == 0
		p.x += rot.x*2.+sin(t*4.)/2.;
		p.y += rot.y*2.+cos(t*4.)/2.;
      #elif CAM_PATH == 1
    	p.x += rot.x*2.+sin(t*2.);
		p.y += rot.y*2.+cos(t*2.);
      #endif
     #else
    	p.x += rot.x*4.;
		p.y += rot.y*4.;
 	 #endif
    #endif
    #ifdef OUTSIDE
    float2	rot1 = float2( .54, .84 );				// cos(1.), sin(1.)
    p.xz *= mat2(rot1.x, rot1.y, -rot1.y, rot1.x);
	#endif
	mind = de_2(p);
	
    return(mind);
}


float4	march(float3 pos, float3 dir)
{
    float2	dist = float2(0.0, 0.0);
    float3	p = float3(0.0, 0.0, 0.0);
    float4	s = float4(0.0, 0.0, 0.0, 0.0);

    for (int i = -1; i < I_MAX; ++i)
    {
    	p = pos + dir * dist.y;
        dist.x = scene(p);
        dist.x = max(abs(dist.x), 0.002);
        dist.y += dist.x;
        accum += 0.01; // Phantom Mode
        if (dist.x < E || dist.y > 30.)
        {
            s.y = 1.;
            break;
        }
        s.x++;
    }
    s.w = dist.y;
    return (s);
}

// Utilities

void rotate(inout float2 v, float angle)
{
	v = float2(cos(angle)*v.x+sin(angle)*v.y,-sin(angle)*v.x+cos(angle)*v.y);
}

float2	rot(float2 p, float2 ang)
{
	float	c = cos(ang.x);
    float	s = sin(ang.y);
    float2x2	m = float2x2(c, -s, s, c);
    
    return mul(p , m);
}

float3	camera(float2 uv)
{
    float		fov = 1.;
	float3		forw  = float3(0.0, 0.0, -1.0);
	float3    	right = float3(1.0, 0.0, 0.0);
	float3    	up    = float3(0.0, 1.0, 0.0);

    return (normalize((uv.x) * right + (uv.y) * up + fov * forw));
}


			ENDCG
		}
	}
}
