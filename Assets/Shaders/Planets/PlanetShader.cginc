#pragma vertex vert
#pragma fragment frag
// make fog work
#pragma multi_compile_fog

#include "UnityCG.cginc"

float	_PlanetSize;
float4	_PlanetHole;
float4 	_ObjectCenter;
float4 	_Rotation;
float4	_LocalScale;

struct appdata
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
};

struct StandardPlanetSurface
{
	float3	hitPos;
	float	dist;
	float4	color;
	float3	normal;
	float3	emission;
};

struct StandardPlanetInput
{
	float3	dir;
	float3	org;
	float	length;
};

struct Input
{
	float3 position;
	float3 normal;
	float3 org;
};

struct PlanetAppdata
{
	float4	vertex : POSITION;
	float3	normal : NORMAL;
	float4	tangent : TANGENT;
};

StandardPlanetSurface planetSurface(inout StandardPlanetInput spi);
StandardPlanetSurface planetUnderground(inout StandardPlanetInput spi);

#define INITIALIZE_PLANET_SURFACE(spo, spi) { \
	spo.hitPos = spi.org; \
	spo.dist = spi.length; \
	spo.color = float4(1, 1, 0, 1); \
	spo.normal = float3(0, 1, 0); \
	spo.emission = float3(0, 0, 0); \
}

void	vertFunc(inout PlanetAppdata v, out Input o)
{
	UNITY_INITIALIZE_OUTPUT(Input, o);
	o.position = mul(v.vertex + _ObjectCenter / _LocalScale.xyz, unity_ObjectToWorld).xyz;//mul((float4x4)unity_ObjectToWorld, v.vertex);//v.vertex.xyz;//mul(v.vertex.xyz, (float3x3)unity_WorldToObject);
	float3 cam = _WorldSpaceCameraPos;//-o.position;
//cam.xz = mul(float2x2(cos(_Time.x*50.), sin(_Time.x*50.), -sin(_Time.x*50.), cos(_Time.x*50.) ), cam.xz);
	o.org = cam - _ObjectCenter;//+o.position;
	o.normal = v.normal;
}

float	sdSphere(float3 p)
{
	return length(p) - _PlanetSize;
}

float	sdcyl(float3 p)
{
	return length(p.xy - _PlanetHole.xy) - _PlanetHole.z;
}

float	planetDE(float3 p, out bool inside)
{
	p /= 5;
	float	s = sdSphere(p);
	float	t = sdcyl(p);

	inside = (t < s);

	return min(s, t);
}

#define MAX_PLANET_ITER		30
#define SURFACE_MIN			0.1f

void	planetSurfaceFunc(Input input, inout SurfaceOutputStandard o)
{
	StandardPlanetInput	spi;
	spi.org = input.org;
	spi.dir = normalize(input.position - _WorldSpaceCameraPos.xyz);
	spi.length = 0;

	o.Albedo = float3(0, 0, 0);
	o.Emission = float3(input.position);
	// o.Alpha = .2;

	return ;

	bool 	inside = false;
	float	surfDist = 1e20;

	for (int i = 0; i < MAX_PLANET_ITER; i++)
	{
		float3 p = spi.org + spi.dir * spi.length;
		surfDist = planetDE(p, inside);
		spi.length += surfDist / 1;

		if (surfDist < SURFACE_MIN)
			break ;
	}


	if (surfDist > SURFACE_MIN)
	{
		o.Alpha = 0;
		return ;
	}

	StandardPlanetSurface	sps;

	INITIALIZE_PLANET_SURFACE(sps, spi);

	if (inside)
		sps = planetSurface(spi);
	else
		sps = planetUnderground(spi);
	
	o.Albedo = sps.color.rgb;
	o.Alpha = sps.color.a;
	o.Emission = sps.emission;
	o.Normal = sps.normal;
}