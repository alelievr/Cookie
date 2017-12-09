
Shader "Cookie/GyrospokeUnderground"
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

			#include "PlanetShader.cginc"

/*
* License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
*/

float 	t;

#define I_MAX		200
#define E			0.001
#define FAR			100.

#define	FUDGE
// artifactus disparatus !! (fudge needed cuz of high curvature distorsion)
// #define PHONG

float4	march(float3 pos, float3 dir);
float3	camera(float2 uv);
float3	calcNormal(in float3 pos, float e, float3 dir);
void	rotate(inout float2 v, float angle);
float	mylength(float2 p);
float	mylength(float3 p);

float3	base;
float3	h;
float3	volumetric;

void mainImage(out float4 c_out, float3 dir, float3 pos)
{
    h *= 0.;
    volumetric *= 0.;
    t = _Time.x;
    float3	col = float3(0., 0., 0.);
//	float3	dir = camera(uv);
    // float3	pos = float3(-.0, .0, 25.0-sin(_Time.x*.125)*25.*0.-21.+2.);

    float4	inter = (march(pos-float3(-5.0,.0, 0.), dir));

    if (inter.y == 1.)
    {
    	base = float3(.4, .5, .2);
	    #ifdef PHONG
        // substracting a bit from the ray to get a better normal
		float3	v = pos+(inter.w-E*10.)*dir;
        float3	n = calcNormal(v, E, dir);
        float3	ev = normalize(v - pos);
		float3	ref_ev = reflect(ev, n);
        float3	light_pos   = float3(0.0, -100.0, 1000.0);
		float3	light_color = float3(1.8, .5, .2);
        float3	vl = normalize( (light_pos - v) );
		float	diffuse  = max(0., dot(vl, n));
		float	specular = pow(max(0., dot(vl, ref_ev)), 10.8 );
        col.xyz = light_color * (specular) + diffuse * base;
        float	dt = 1. - dot(n, normalize(-ev) );
        col += smoothstep(.0, 1.0, dt)*float3(.2, .7, .90);
	#else
    	col.xyz = 1.*( +float3(.85, .4, .2)*inter.w * .3-inter.x*.1 * float3(.3, .2, .15) );
	#endif
    	// col  -= -.25 + h;
    }
    col += volumetric;
    c_out =  float4(col, 1.);
}

float	scene(float3 p)
{
//    p.z+=sin(t*1.5)*2.;
    float	balls = 1e5;
    float	lumos = 1e5;
	float3	pr;

    float2	q;
    
    pr = p;
    
    rotate(pr.xz , _Time.x*10.);
	
    /*
	* Trying to get an ID for the 4 big toruses and rotating them with it
	* Turns out I might need recursivity, I'll try to tackle this problem later
	* ID's of not twisted toruses are given by the following
    q = float2(length(pr.xy)-2., pr.z);
    float	ara;
    ara = 
	        (( (q.x) > 0. && q.y <= -abs(q.y) ) ?0.70:1.0)
            *
		    (( (q.x) > 0. && q.y >= +abs(q.y) ) ?2.70:1.0)
            *
	        (( (q.y) > 0. && q.x <= -abs(q.x) ) ?1.50:1.0)
            *
	        (( (q.y) < 0. && q.x <= -abs(q.x) ) ?4.57:1.0)
	        ;
    rotate(pr.xy, ara+_Time.x);
	*/
        
    float	ata = atan2(pr.x, pr.y)*1.+0.;
    
    q = float2(length(pr.xy)-2., pr.z);
    
    rotate(q.xy, +_Time.x*20.+ata*3. );
    
    q.xy = abs(q.xy)-.25;
    
    rotate(q.xy, -_Time.x*2.+ata*8. );
    q.xy = abs(q.xy)-.1; // .25 == butterflys
    rotate(q.xy, +_Time.x*2.+ata*4. );
    q.xy = abs(q.xy)-.051;
    balls = mylength(q)+(-.0305-.011*(abs(ata)-3.00));//sin(6.28*ata+_Time.x)*1.;
    p.y -= 2.;
    rotate(p.xz , _Time.x*1.);
    float	light = dot(p,p);
    balls = max(balls, -(light-.65) ); // Cut the extremities

	#ifdef	FUDGE
    balls *= .5;
    #endif
    rotate(p.yx, _Time.x*.5);
    #ifdef	FUDGE
    lumos = length(p.y-18.)-10.1;
    h += .251/(lumos + 10.1)*float3(.0,.0,.5);
    lumos = length(p.y+18.)-10.1;
    h += .251/(lumos + 10.1)*float3(.0, .5, .0);
    balls = min(balls, light);
    volumetric += .0251/(light+.01)*float3(.085,.105,.505);
    #else
    lumos = length(p.y-18.)-10.1;
    h += .51/(lumos + 10.1)*float3(.0,.0,.5);
    lumos = length(p.y+18.)-10.1;
    h += .51/(lumos + 10.1)*float3(.0, .5, .0);
    balls = min(balls, light);
    volumetric += .051/(light+.01)*float3(.085,.105,.505);
    #endif
	
    return(balls);
}

float4	march(float3 pos, float3 dir)
{
    float2	dist = float2(0.0, 0.0);
    float3	p = float3(0.0, 0.0, 0.0);
    float4	step = float4(0.0, 0.0, 0.0, 0.0);

    for (int i = -1; i < I_MAX; ++i)
    {
    	p = pos + dir * dist.y;
        dist.x = scene(p);
        dist.y += dist.x*1.;
        // log trick by aiekick
        if (dist.x < E || dist.y >= FAR)
        {
            if (dist.x < E)
	            step.y = 1.;
            break;
        }
        step.x++;
    }
    step.w = dist.y;
    return (step);
}

// Utilities

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

void rotate(inout float2 v, float angle)
{
	v = float2(cos(angle)*v.x+sin(angle)*v.y,-sin(angle)*v.x+cos(angle)*v.y);
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

    return (normalize((uv.x) * right + (uv.y) * up + fov * forw));
}


		ENDCG
	}
}
}