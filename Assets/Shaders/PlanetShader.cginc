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
	float3	histPos;
	float	dist;
	float3	color;
	float3	normal;
};

struct StandardPlanetInput
{
	float3	dir;
	float3	org;
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

void vert(inout appdata_full v, out Input o)
{
	UNITY_INITIALIZE_OUTPUT(Input, o);
	o.position = UnityObjectToClipPos(v.vertex).xyz;
	o.normal = v.normal;
}

void planetSurface (Input i, inout SurfaceOutputStandard o)
{
	StandardPlanetInput	spi;
	spi.org = _WorldSpaceCameraPos.xyz;
	spi.dir = normalize(spi.org - i.position);

	//TODO: raymarching

	o.Albedo = i.normal;
	o.Emission = i.normal;
}