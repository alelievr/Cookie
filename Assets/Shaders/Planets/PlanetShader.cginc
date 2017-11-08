#pragma vertex vert
#pragma fragment frag
// make fog work
#pragma multi_compile_fog

#include "UnityCG.cginc"

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

struct StandardPlanetOutput
{
	half4 color : SV_TARGET;
};

struct Input
{
	float3 position;
	float3 normal;
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

void	vertFunc(inout appdata_full v, out Input o)
{
	UNITY_INITIALIZE_OUTPUT(Input, o);
	o.position = v.vertex.xyz;
	o.normal = v.normal;
}

float	_PlanetSize;
float3	_PlanetHole;

float	sdSphere(float3 p)
{
	return length(p) - _PlanetSize;
}

float	sdTorus(float3 p)
{
	return length(p.xz - _PlanetHole.xy) - _PlanetHole.z;
}

float	planetDE(float3 p, out bool inside)
{
	float	s = sdSphere(p);
	float	t = sdTorus(p);

	inside = (t < s);

	// return t; //min(s, t);
	return s;
}

#define MAX_PLANET_ITER		100
#define SURFACE_MIN			0.01f

void	planetSurfaceFunc(Input input, inout SurfaceOutputStandard o)
{
	StandardPlanetInput	spi;
	spi.org = _WorldSpaceCameraPos.xyz;
	spi.dir = normalize(input.position - spi.org);
	spi.length = 0;

	// o.Albedo = float3(0, 0, 0);
	// o.Emission = float3(spi.dir);

	// return ;

	bool 	inside = false;
	float	surfDist = 1e20;

	for (int i = 0; i < MAX_PLANET_ITER; i++)
	{
		float3 p = spi.org + spi.dir * spi.length;
		surfDist = planetDE(p, inside);
		spi.length += surfDist / 2;

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

	sps.color = float4(0, 1, 1, 1);

	/*if (inside)
		sps = planetSurface(spi);
	else
		sps = planetUnderground(spi);*/
	
	o.Albedo = sps.color.rgb;
	o.Alpha = sps.color.a;
	o.Emission = sps.emission;
	o.Normal = sps.normal;
}