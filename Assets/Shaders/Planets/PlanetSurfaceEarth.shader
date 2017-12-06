Shader "Cookie/PlanetSurfaceEarth"
{
	Properties
	{
		[HideInInspector]_ObjectCenter ("Object Center", Vector) = (0, 0, 0)
		[HideInInspector]_LocalScale ("Local scale", Vector) = (1, 1, 1, 1)
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

			#define ITER	100
			#define EPSY	0.01

const float PI = 3.14159265359;
#define FOV (67.0 / 180.0 * PI)
const float MAX = 10000.0;

// scatter constants
const float K_R = 0.166;
const float K_M	 = 0.025;
const float E = 14.3; // light intensity
const float3 C_R = float3(0.3, 0.7, 1.0); // 1 / wavelength ^ 4
const float G_M = -0.85; // Mie g

const float R_INNER = 1.0;
#define R (R_INNER * 1.025)
#define SCALE_H (4.0 / (R - R_INNER))
#define SCALE_L (1.0 / (R - R_INNER))

const int NUM_OUT_SCATTER = 10;
const float FNUM_OUT_SCATTER = 10.0;

const int NUM_IN_SCATTER = 10;
const float FNUM_IN_SCATTER = 10.0;

const float WATER_HEIGHT = 0.7;
const float3 LIGHT = float3(0, 0, 1.0);

#define SEED 171.

float2 ray_vs_sphere(float3 p, float3 dir, float r)
{
	float b = dot(p, dir);
	float c = dot(p, p) - r * r;

	float d = b * b - c;
	if (d < 0.0)
		return float2(MAX, -MAX);
	d = sqrt(d);

	return float2(-b - d, -b + d);
}

float phase_mie(float g, float c, float cc)
{
	float gg = g * g;

	float a = (1.0 - gg) * (1.0 + cc);

	float b = 1.0 + gg - 2.0 * g * c;
	b *= sqrt(b);
	b *= 2.0 + gg;

	return 1.5 * a / b;
}

float phase_reyleigh(float cc)
{
	return 0.75 * (1.0 + cc);
}

float density(float3 p)
{
	return exp(-(length(p) - R_INNER) * SCALE_H);
}

float optic(float3 p, float3 q)
{
	float3 step = (q - p) / FNUM_OUT_SCATTER;
	float3 v = p + step * 0.5;

	float sum = 0.0;
	for (int i = 0; i < NUM_OUT_SCATTER; i++)
	{
		sum += density(v);
		v += step;
	}
	sum *= length(step) * SCALE_L;

	return sum;
}

float3 in_scatter(float3 o, float3 dir, float2 e, float3 l)
{
	float len = (e.y - e.x) / FNUM_IN_SCATTER;
	float3 step = dir * len;
	float3 p = o + dir * e.x;
    float3 pa = p;
    float3 pb = o + dir * e.y;
	float3 v = p + dir * (len * 0.5);

	float3 sum = float3(0.0, 0, 0);
	for (int i = 0; i < NUM_IN_SCATTER; i++)
	{
		float2 f = ray_vs_sphere(v, l, R);
		float3 u = v + l * f.y;

		float n = (optic(p, v) + optic(v, u)) * (PI * 4.0);

		sum += density(v) * exp(-n * (K_R * C_R + K_M));

		v += step;
	}
	sum *= len * SCALE_L;

	float c = dot(dir, -l);
	float cc = c * c;
	return sum * (K_R * C_R * phase_reyleigh(cc) + K_M * phase_mie(G_M, c, cc)) * E;
}

float3 scatter(float3 ro, float3 rd, float2 f)
{
	float2 e = ray_vs_sphere(ro, rd, R);
	if (e.x > e.y)
		return float3(0, 0, 0);

	e.y = min(e.y, f.x);

	return in_scatter(ro, rd, e, LIGHT);
}
//###### end scatter

//###### noise
// credits to iq for this noise algorithm

float3x3 m = float3x3(0.00, 0.80, 0.60,
		-0.80, 0.36, -0.48,
		-0.60, -0.48, 0.64);

float hash(float n)
{
	return frac(sin(n) * 43758.5453);
}

float noise(in float3 x)
{
	float3 p = floor(x);
	float3 f = frac(x);

	f = f * f * (3.0 - 2.0 * f);

	float n = p.x + p.y * 57.0 + 113.0 * p.z;

	float res = lerp(lerp(lerp(hash(n + 0.0), hash(n + 1.0), f.x),
				lerp(hash(n + 57.0), hash(n + 58.0), f.x), f.y),
			lerp(lerp(hash(n + 113.0), hash(n + 114.0), f.x),
				lerp(hash(n + 170.0), hash(n + 171.0), f.x), f.y), f.z);
	return res;
}

float fbm(float3 p)
{
	float f;
	f = 0.5000 * noise(p);
	p = mul(m, p) * 2.02;
	f += 0.2500 * noise(p);
	p = mul(m, p) * 2.03;
	f += 0.1250 * noise(p);
	p = mul(m, p) * 2.01;
	f += 0.0625 * noise(p);
	return f;
}

//###### end noise

float rnd(float r)
{
	return r - fmod(r, 0.04);
}

float terrain(float3 p)
{
	return fbm(p * 10.) / 5. + fbm(p + SEED) - (1. / 5.);
}

float3 waterColor(float h)
{
	return lerp(float3(0, .29, 0.85), float3(0, 0, .25), h);
}

float3 terrainColor(float h)
{
//	h *= 1.2;
	return h < .5 ?
        lerp(float3(1., 1, 1), float3(.41, .54, .09), h * 2.) :
		lerp(float3(.41, .54, .0), float3(.91, .91, .49), (h - .5) * 2.);
}

float3 surfaceColor(float height, float longitude) {
    if (height < (1.-WATER_HEIGHT))
        return terrainColor(1.0 - abs(longitude + height + WATER_HEIGHT - 1.0));
    else
        return waterColor(height / WATER_HEIGHT);
}

float3x3 rm(float3 axis, float angle)
{
	axis = normalize(axis);
	float s = sin(angle);
	float c = cos(angle);
	float oc = 1.0 - c;

	return float3x3(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s,
		oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s,
		oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c);
}

float3 render(float3 ro, float3 rd)
{
	float3x3 r = rm(float3(0, 1, 0), _Time.x);
    float2 d = ray_vs_sphere(ro, rd, R_INNER);
	float3 atmosphere = float3(.5, .5, .5);//scatter(ro, rd, d);
    
    if (d.x < 10000 - 1.0)
	{
		float3 hit = mul(normalize(d.x * rd + ro), r);
		float h = (fbm(hit * 10.0) / 5.0 + fbm(hit + SEED)) - 0.2;
		return surfaceColor(h, hit.y) * length(atmosphere * 1.5) * (atmosphere + 0.75);
	}
    
    return atmosphere;
}

void mainImage(out float4 fragColor, in float3 dir, in float3 pos)
{
	float3 up = float3(0, 1, 0);


	float3 color = render(pos, dir);

	fragColor = float4(color, 1);
}
		
			ENDCG
		}
	}
}
