Shader "Cookie/CubicTorusUnderground"
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
*/

float 	t;

#define I_MAX		100
#define E			0.00001
#define FAR			30.


float4	march(float3 pos, float3 dir);
float3	camera(float2 uv);
float3	calcNormal(in float3 pos, float e, float3 dir);
float2	rot(float2 p, float2 ang);
void	rotate(inout float2 v, float angle);

float3	id;
float3	base;
float3	h;

void mainImage(out float4 c_out, float3 dir, float3 pos)
{
    h *= 0.;
    t = _Time.y;

    float4	inter = (march(pos, dir));
	float3	col = float3(0, 0, 0);

    base = float3(1., 1, 1);
    /*
	if (inter.y == 1.)
	{
		float3	v = pos+(inter.w)*dir;
        float3	n = calcNormal(v, E, dir);
        float3	ev = normalize(v - pos);
		float3	ref_ev = reflect(ev, n);
        float3	light_pos   = pos*0.+float3(.0, 1.0, -5.0);
        //light_pos.x+=40.*sin(t*10.);
		float3	light_color = float3(1., .5, .2);
        float3	vl = normalize( (light_pos - v) );
		float	diffuse  = max(.5, dot(vl, -n));
		float	specular = pow(max(0., dot(vl, ref_ev)), 1. );
        col.xyz = light_color * (specular) + diffuse * base;

        //col += h;
    }
    */

//    base = float3(.5, .18, .2);
    base = float3
        (
    		abs(sin(id.z+id.x+id.y+0.00) )
            ,
            abs(sin(id.z+id.x+id.y+1.04) )
            ,
            abs(sin(id.z+id.x+id.y+2.08) )
        );
    if (inter.y == 1.)
	    col.xyz = base * ( -1.*inter.w*.05 + 1. -inter.x*.001 );

//    col.xyz = col * (3. - 2. * col);
    /*
    base.xyz = texture(iChannel0, float2( ((pos+inter.w*dir).zz)*.042)).xyz;
    if (inter.y == 1.)
    {
	    col += 1.-inter.w*.0061251;
	    col *= base;
        //col += -h;
    }
*/
//    col = .4-h;
//    col += h*.25-exp(-3.+h);

    col = .5 - h;

    c_out =  float4(col, h.x);
}    

float	mylength(float3 p)
{
	float	ret = 1e5;
    
    p = p*p;
    p = p*p;
    p = p*p;
    
    ret = p.x + p.y + p.z;
    ret = pow(ret, 1./8.);
    
    return ret;
}

float	mylength(float2 p)
{
	float	ret = 1e5;
    
    p = p*p;
    p = p*p;
    p = p*p;
    
    ret = p.x + p.y;
    ret = pow(ret, 1./8.);
    
    return ret;
}

float	de_0(float3 p) // Spaghettis
{
    float	balls;
	float	mind = 1e5;
	float	a = (t*2.*0.)*1.+( (p.y*.015+p.x*.015+p.z *.15)  + t/3.*0.) * 4.;
	float3	pr = p*.45;//*.804;//p*.804;

    balls = length(p.yx)-.5;//mylength(q)-.02305;
    
    //balls = max(balls, max((length(float2(length(pr.xy)-2., pr.z))-.3), (length(float2(length(pr.xy)-2., pr.z))-.7)) );
    
    balls *= .5;
    mind = balls;
    if (mind == balls)
        base = float3(.4, .75, .2);
	return (mind);
}

float sdCappedCylinder( float3 p, float2 h )
{
	float2 d = abs(float2(length(p.xy),p.z )) - h;
	return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}


float	scene(float3 p)
{
    float	mind = 1e5;
    p.z -= -20.;
    p.z -= _Time.y*5.;

    p.y += sin(_Time.y*-1.+p.z*.5)*.5;
    p.x += cos(_Time.y*-1.+p.z*.5)*.5;
    rotate(p.xy, p.z*.25 + 1.0*sin(p.z*.125 - _Time.y*0.5) + 1.*_Time.y);
    
    float	tube = max(-(length(p.yx)-2.), (length(p.yx)-8.));
    tube = max(tube, p.z-10.-0./length(p.yx*.06125) );
    tube = max(tube, -p.z-10.-0./length(p.yx*.06125) );
    float3	pr = p;
    
    pr.xy = frac(p.xy*.5)-.5;
    id = float3(floor(p.xy*.5), floor(p.z*2.));
    p.z += (fmod(id.x*1., 2.)-1. == 0. ? 5. : 0. );
    p.z += (fmod(id.y*1., 2.)-1. == 0. ? 5. : 0. );
    rotate(pr.xy, clamp( (fmod(floor(p.z*.5), 2.)-1. == 0. ? 1. : -1.)+(fmod(id.x, 2.)-1. == 0. ? 1. : -1.) + (fmod(id.y, 2.)-1. == 0. ? 1. : -1.), -2., 2.) * _Time.y*2.+(fmod(id.x, 2.)-1. == 0. ? -1. : -1.)*p.z*2.5 + _Time.y*0. );
    
    pr.xy = abs(pr.xy)-.05-(sin(p.z*0.5+_Time.y*0.)*.15);
    pr.xy *= clamp(1./length(pr.xy), .0, 2.5);
    pr.z = (frac(pr.z*2.)-.5);
	mind = mylength(float2(mylength(pr.xy)-.1, pr.z ))-.04;

//    mind = max(mind, tube );
    
    return(mind);
}


float4	march(float3 pos, float3 dir)
{
    float2	dist = float2(0.0, 0.0);
    float3	p = float3(0.0, 0.0, 0.0);
    float4	step = float4(0.0, 0.0, 0.0, 0.0);
	float3	dirr;

    for (int i = -1; i < I_MAX; ++i)
    {
        dirr = dir;
    	rotate(dirr.zx, .025*dist.y );
    	p = pos + dirr * dist.y;
        dist.x = scene(p);
        dist.y += dist.x*.5;
        float3	s = p- 1.*float3(.0,7.0,0.0); // lightpos
        float	d = length(s.xy)-.1;
        h -= float3(.3, .2, .0)*.1/ (d+.0);//(dot(d, d) );
        h += (
            .001/(dist.x*dist.x+0.01) 
            -
            1./(dist.y*dist.y+40.)
             )
            *
            float3
        (
    		abs(sin(id.z+id.x+id.y+0.00) )
            ,
            abs(sin(id.z+id.x+id.y+1.04) )
            ,
            abs(sin(id.z+id.x+id.y+2.08) )
        );
        if (log(dist.y*dist.y/dist.x/1e5)>0. || dist.x < E || dist.y >= FAR)
        {
            if (dist.x < E || log(dist.y*dist.y/dist.x/1e5)>0.)
	            step.y = 1.;
            break;
        }
        step.x++;
    }
    step.w = dist.y;
    return (step);
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

float3 calcNormal( in float3 pos, float e, float3 dir)
{
    float3 eps = float3(e,0.0,0.0);

	return normalize(float3(
           march(pos+eps.xyy, dir).w - march(pos-eps.xyy, dir).w,
           march(pos+eps.yxy, dir).w - march(pos-eps.yxy, dir).w,
           march(pos+eps.yyx, dir).w - march(pos-eps.yyx, dir).w ));
}

float3	camera(float2 uv)
{
    float		fov = 1.;
	float3		forw  = float3(0.0, 0.0, -1.0);
	float3    	right = float3(1.0, 0.0, 0.0);
	float3    	up    = float3(0.0, 1.0, 0.0);

    return (normalize((uv.x-.85) * right + (uv.y-0.5) * up + fov * forw));
}

			ENDCG
		}
	}
}
