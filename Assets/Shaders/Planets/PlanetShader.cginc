#pragma vertex vert
#pragma fragment frag

void mainImage(out float4 color, float3 dir, float3 org);

struct appdata
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
};

struct Input
{
	float4 vertex : SV_POSITION;
	float3 position : TEXCOORD2;
	float3 origin : TEXCOORD1;
};

float4	_LocalScale;
float4 	_ObjectCenter;

Input vert(in appdata v)
{
	Input i;

	i.vertex = UnityObjectToClipPos(v.vertex);
	i.position = mul(v.vertex + _ObjectCenter / _LocalScale.xyz, unity_ObjectToWorld).xyz;
	i.origin = _WorldSpaceCameraPos - _ObjectCenter;

	return i;
}

float    boundingSphere(inout float3 ro, in float3 rd)
{
	float       minSphereDist = 2.;
	float       boundingEpsy = 0.01;
	float       d = 0;
	float       l;
	float3        oro = ro;

	for (int i = 0; i < 40; i++)
	{
		ro = oro + rd * d;

		l = length(ro) - minSphereDist;

		if (l < boundingEpsy)
			return d;

		d += l / 2;
	}
	return -1;
}

fixed4 frag (Input i) : SV_TARGET
{
	float3	dir = normalize(i.position - _WorldSpaceCameraPos.xyz);
	float3	org = i.origin;
	float4	col = float4(1, 1, 1, 0);
	float	t = 0;

	if (boundingSphere(org, dir) == -1)
		return float4(0, 1, 1, 1);
	
	mainImage(col, dir, org);

	return col;
}