
Shader "Cookie/Thing1Underground"
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

float 	t;

#define I_MAX		100
#define E			0.01

float4	march(float3 pos, float3 dir);
float3	camera(float2 uv);
float3	calcNormal(in float3 pos, float e, float3 dir);
float3	color_func(float3 pos, float3 dir);
void	rotate(inout float2 v, float angle);

float	neo, h, accum, trinity, rabbit;
float	col_id;

float4	render(float3 dir, float3 pos)
{
	col_id = 0.;
	neo = 0.;h = 0.;accum = 0.;trinity = 0.;rabbit = 0.;
    t = _Time.x;

    float3	col = float3(0., 0., 0.);

    float4	inter = (march(pos-float3(0.,0.,t*30.), dir));

	float3	base = float3(.8, .0, 1.);
    //rotate(dir.zx, .001251*inter.w+t*.1);
//float3	p = inter.w*dir + pos;
//    col.xyz = 
//        -float3(.0,.0,.5)*(sin(3.14+p.z*1.*(inter.w>100.?0.:1.) ))
//        +
//        200.*(1./((length(p.xy+sin(p.z*2.)*.25)-4.5)*(length(p.xy+sin(p.z*2.)*.25)-4.5)) )
//        -
//        1.*(float3(.17, .3,.6))*(inter.x*.0051+0.-inter.w*.0751);//*(1.+inter.x*.01+inter.w*.005*(inter.x/float(I_MAX) )));
//        if (inter.w <= 0.)
//        	col.x = 1;
    float4	c_out =  float4(col,1.0)*1.;
    c_out.xyz += neo * float3(.7, .6, .3);
    if (col_id == 2.)
    {
    	c_out.xyz += (1.-inter.w*.051)*float3(.3,.4,.7);

    }
    if (col_id == 1.)
    {
    	c_out.xyz += (1.-inter.w*.051)*float3(.38,.75,.5);
    	    	c_out.xyz += rabbit*.00001*float3(1., .4, .5);
    }
//    if (col_id == 0.)
    	c_out.xyz += (inter.x*.0051)*float3(.5,.3,.25)*h;
c_out.xyz += .0051*trinity*float3(.2, .150, .950);
    	c_out.xyz *= accum;
   //c_out.x += step(uv.x, .502)*step(.5, uv.x);
// c_out.w = 0.;
    return	c_out;
}

void mainImage(out float4 fragColor, float3 dir, float3 org)
{
    fragColor = render(dir, org);
}

#define POWER	9.
#define PI		3.14

void rotate(inout float2 v, float angle)
{
	v = float2(cos(angle)*v.x+sin(angle)*v.y,-sin(angle)*v.x+cos(angle)*v.y);
}

float udBox( float3 p, float3 b )
{
  return length(max(abs(p)-b,0.0));
}

float	mylength(float p)
{
	float	ret = 0.;
    p = p*p*p*p;
    ret = p;
    ret = pow(ret, 1./3.);
    return (ret);
}

float	mylength(float2 p)
{
	float	ret = 0.;
    p = p*p*p*p;
    ret = p.x+p.y;
    ret = pow(ret, 1./4.);
    return (ret);
}


float	mylength(float3 p)
{
	float	ret = 0.;
    p = p*p*p*p;
    ret = p.x+p.y+p.z;
    ret = pow(ret, 1./4.);
    return (ret);
}

float sdCappedCylinder( float3 p, float2 h )
{
  float2 d = abs(float2(length(p.xy),p.z)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float2	rot(float2 p, float2 ang)
{
	float	c = cos(ang.x);
    float	s = sin(ang.y);
    float2x2	m = float2x2(c, -s, s, c);
    
    return mul(p , m);
}

float	plane_de(float3 p)
{
	float	ret = dot(p, float3(1.0, 1.0, -1.) ) + 1. ;
  	return ret;
}

float sdTorus( float3 p, float2 t )
{
	float2 q = float2(length(p.zy)-t.x,p.x);

    return length(q)-t.y;
}

float	scene(float3 p)
{
	float	minf = 1e5;
	float	mind = 1e5;
	float	ming = 1e5;
	float	minr = 1e5;
	float	mins = 1e5;
	float	minc = 1e5;
	float3	id = 0.;
//	float	dst[2];
	minr = length(p.xy)-1.;
	mins = length(p-float3(.0,.0,0.-t*20.));//-25.01;
	minr = max(minr, -(length(p.xy)-.99) );
	float	outer = length(p.xy)-.25;
	//p.xy += float2(sin(_Time.x*100.), cos(_Time.x*100.))*.2;
	float	s = p.z;
	id.z  = floor(p.z*3.);
	p.z = frac(p.z*3.)-.5;
	p.xy -= float2(cos(id.z*0.+fmod(s*1000., 10000.)/(.1+mins*mins)+_Time.x*1.),sin(id.z*0.+fmod(s*1000., 10000.)/(.1+mins*mins)+_Time.x*1.))*.02512;
	id.xy = floor(p.xy * 10.);
	p.xy  = frac(p.xy*(7.5+fmod(id.z, 2.5) ))-.5;

minf = max(abs(p.x), max(abs(p.y), abs(p.z)))-.0125-.17*abs(sin(s*.125+.0*id.z));//*(sin( (lerp(id.y,id.x,.5+.5*sin(id.z*10000.1)))*30.14));
minc = min(minc, (length(frac(p.xy*(3.+ 7.*fmod(-id.z*10., 70.)/70. ) )-.5)-.2501) );
minc = min(minc, (length(frac(p.yz*(3.+ 7.*fmod(+id.x*10., 70.)/70. ) )-.5)-.2501) );
minc = min(minc, (length(frac(p.zx*(3.+ 7.*fmod(+id.y*10., 70.)/70. ) )-.5)-.2501) );
//minf = max(minf, -minc);
 trinity = .51/(.0+minc*minc);
 minc = max(minc, - minf);
 rabbit += .0051/(.0000001+minc*minc);
//max(abs(p.x), max(abs(p.y), abs(p.z)))-.0125-.07*(sin(abs(lerp(id.y,id.x,.5+.5*sin(id.z*.1)))*30.14));
//neo -= .002/(ming*ming+1.2);
ming = max(minf, -outer);
neo += .02/(2.1+ming*ming);
h += 5.1/(mins*mins);
	mind = min(minr, ming);
	mind = min(mind, mins);
	col_id = (mind == minf) ? 2. : col_id;
	col_id = (mind == minr) ? 1. : col_id;
	col_id = (mind == mins) ? 0. : col_id;
	//col_id = (mind == minc) ? 3. : col_id;
    return mind;//r2;//.085+.5*(abs(p.x))/scale);
}

float4	march(float3 pos, float3 dir)
{
    float2	dist = float2(0.0, 0.0);
    float3	p = float3(0.0, 0.0, 0.0);
    float4	step = float4(0.0, 0.0, 0.0, 0.0);
	float3	dirr;
	float	dynamiceps = E;
    for (int i = 1; i < I_MAX; ++i)
    {
        dirr = dir;
        //rotate(dirr.xy, .51*dist.y-t*2.1);
        rotate(dirr.xy, -(.51*dist.y*0.-.001*floor(t*2000.1-dist.y*300.))) ;
    	p = pos + dirr * dist.y;
        //p.z -=20.;
        dynamiceps = -dist.x+(dist.y)/(50.);
        dist.x = scene(p);
        dist.y += dist.x*.3;//*1.*exp(0.-dist.y);//dist.x*1.3/(dist.y*1.1+.2);//*.3;
        accum += .01;
        if (log((dist.y*dist.y/dist.x)/1e5)>0. || (dist.x) < dynamiceps)// || dist.y > 20.)
        {
//            step.y = 1.;
//            if (dist.y < 4.)
  //              step.y = 0.;
            break;
        }
        step.x++;
    }
    step.w = dist.y;
    return (step);
}

// Utilities

float3 calcNormal( in float3 pos, float e, float3 dir)
{
    //pos.z += e*dir.z*10.;
    e /= 100.;
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

	
	//	}
		ENDCG
	}
}
}