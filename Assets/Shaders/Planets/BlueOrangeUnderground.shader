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

			/*
* License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
* Created by bal-khan
*/

float2	march(float3 pos, float3 dir);
float3	camera(float2 uv);
void	rotate(inout float2 v, float angle);
float3	calcNormal( in float3 pos, float e, float3 dir);
float	loop_circle(float3 p);
float	circle(float3 p, float phase);
float	sdTorus( float3 p, float2 t, float phase );
float	mylength(float2 p);
float	nrand( float2 n );

float 	t;			// time
float3	ret_col;	// torus color
float3	h; 			// light amount

#define I_MAX		200.
#define E			0.0001
#define FAR			50.
#define MAXI		7.		// num torus
#define PI			3.14


void mainImage(out float4 c_out, float3 dir, float3 pos)
{
    t  = _Time.y*.125;
    float3	col = float3(0., 0., 0.);

    pos.z += 4.5-_Time.y*2.;
    h*=0.;
    float2	inter = (march(pos, dir));
    if (inter.y <= FAR)
        col.xyz = ret_col*(1.-inter.x*.0025);
    else
        col *= 0.;
    col += h*.005125;
    c_out =  float4(col,1.0);
}

/*
* Leon's fmod polar from : https://www.shadertoy.com/view/XsByWd
*/

#undef	PI
#define	PI 3.14159
#define	TAU PI*2.

float2 modA (float2 p, float count) {
    float an = TAU/count;
    float a = atan2(p.y,p.x)+an*.5;
    a = fmod(a, an)-an*.5;
    return float2(cos(a),sin(a))*length(p);
}
float   glob;
float	scene(float3 p)
{  
    float	var = glob;
    float	mind = 1e5;
    float3	op = p;

    var = atan2(p.x, p.y)*1.+0.;
    var = cos(var*2.+floor(p.z) +_Time.x*(fmod(floor(p.z), 2.)-1. == 0. ? -1. : 1.) );
    float	dist_cylinder = 1e5;
    ret_col = 1.-float3(.5-var*.5, .5, .3+var*.5);
    mind = length(p.xy)-1.+.1*var;
    mind = max(mind, -(length(p.xy)-.9+.1*var));
    // p.xy = modA(p.yx, 50. );
	p.z = frac(p.z*1.)-.5;
    rotate(p.xy, (fmod(floor(op.z), 2.)-1. == 0. ? -1. : 1.)*floor(op.z) );
    if (var != 0.)
    {
	    dist_cylinder = length(p.zz)-.0251-.25*sin(op.z*5.5);
	    dist_cylinder = max(dist_cylinder, -p.x+.4 + clamp(var, 0., 1.) );
    }
    mind = 
        min
        (
            mind
            ,
			dist_cylinder*.4
        );

//    mind = min(mind, (length(frac(float2(op.z, ( (op.y)))*3.)-.5)-.01) );
    h += float3(.5,.8,.5)*(var!=0.?0.:1.)*float3(1., 1, 1)*.0125/(.01+(mind-var*.1)*(mind-var*.1) );
    h += float3(.5,.8,.5)*(var!=0.?1.:0.)*float3(1., 1, 1)*.0125/(.01+mind*mind);
    
    return (mind);
}

float2	march(float3 pos, float3 dir)
{
    float2	dist = float2(0.0, 0.0);
    float3	p = float3(0.0, 0.0, 0.0);
    float2	s = float2(0.0, 0.0);
    dir.xz = dir.zx;
    pos.zx = pos.xz;
    rotate(dir.xz, 1.57);
    p = pos + dir * 1.;
glob = atan2(p.x,p.y);
    [loop]
	    for (float i = -1.; i < I_MAX; ++i)
	    {
	    	p = pos + dir * dist.y;
	        dist.x = scene(p);
	        dist.y += dist.x; // makes artefacts disappear
	        if (dist.x*.2 < E || dist.y > FAR)
            {
                break;
            }
	        s.x++;
    }
    s.y = dist.y;
    return (s);
}

float	mylength(float2 p)
{
	float	ret;
    
    p = p*p*p*p;
    p = p*p;
    ret = (p.x+p.y);
    ret = pow(ret, 1./8.);
    
    return ret;
}

// Utilities

void rotate(inout float2 v, float angle)
{
	v = float2(cos(angle)*v.x+sin(angle)*v.y,-sin(angle)*v.x+cos(angle)*v.y);
}

float2	rot(float2 p, float2 ang)
{
	float		c = cos(ang.x);
    float		s = sin(ang.y);
    float2x2	m = float2x2(c, -s, s, c);
    
    return mul(p, m);
}

float3	camera(float2 uv)
{
    float		fov = 1.;
	float3		forw  = float3(0.0, 0.0, -1.0);
	float3    	right = float3(1.0, 0.0, 0.0);
	float3    	up    = float3(0.0, 1.0, 0.0);

    return (normalize((uv.x) * right + (uv.y) * up + fov * forw));
}

float3 calcNormal( in float3 pos, float e, float3 dir)
{
    float3 eps = float3(e,0.0,0.0);

    return normalize(float3(
           march(pos+eps.xyy, dir).y - march(pos-eps.xyy, dir).y,
           march(pos+eps.yxy, dir).y - march(pos-eps.yxy, dir).y,
           march(pos+eps.yyx, dir).y - march(pos-eps.yyx, dir).y ));
}

			ENDCG
		}
	}
}
