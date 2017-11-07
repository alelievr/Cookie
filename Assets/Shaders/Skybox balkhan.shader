// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Custom/Procedural Skybox" {
Properties {
	_sam ("Texture", 2D) = "white" { }
	_var ("var", Range(-20., 20.)) = 0.5 
	_intensity ("intensity", Float) = 0.5 
}

SubShader {
    Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
    Cull Off ZWrite Off

    Pass {

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag

        #include "UnityCG.cginc"
        #include "Lighting.cginc"

        #pragma multi_compile _SUNDISK_NONE _SUNDISK_SIMPLE _SUNDISK_HIGH_QUALITY

        uniform half _Exposure;     // HDR exposure
        uniform half3 _GroundColor;
        uniform half _SunSize;
        uniform half _SunSizeConvergence;
        uniform half3 _SkyTint;
        uniform half _AtmosphereThickness;

		sampler2D	_sam;
		float		_var;
		float		_intensity;

        half getRayleighPhase(half eyeCos2)
        {
            return 0.75 + 0.75*eyeCos2;
        }
        half getRayleighPhase(half3 light, half3 ray)
        {
            half eyeCos = dot(light, ray);
            return getRayleighPhase(eyeCos * eyeCos);
        }


        struct appdata_t
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct v2f
        {
            float4  pos             : SV_POSITION;

            half3   vertex          : TEXCOORD0;

			float2 uv : TEXCOORD1;

            UNITY_VERTEX_OUTPUT_STEREO
        };


float3	camera(float2 uv)
{
    float   fov = 1.;
	float3    forw  = float3(0.0, 0.0, -1.0);
	float3    right = float3(1.0, 0.0, 0.0);
	float3    up    = float3(0.0, 1.0, 0.0);

    return (normalize((uv.x) * right + (uv.y) * up + fov * forw));
}

	float4	_sam_ST;

        v2f vert (appdata_t v)
        {
            v2f OUT;

            OUT.uv = TRANSFORM_TEX(v.uv, _sam);

            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
            OUT.pos = UnityObjectToClipPos(v.vertex);
            OUT.vertex = v.vertex;
            float far = 0.0;
            half3 cIn, cOut;

            return OUT;
        }

void rotate(inout float2 v, float angle)
{
	v = float2(cos(angle)*v.x+sin(angle)*v.y,-sin(angle)*v.x+cos(angle)*v.y);
}


float	my_rand(float3 id)
{
	float	ret;

    return frac(sin(dot(id.xyz ,float3(12.9898,78.233, 42.424242))) * 43758.5453);


	return ret;
}

float flare( float2 U )   // Fabrice                         // rotating hexagon 
{	float2 A = sin(float2(0, 1.57) );
    //U = abs( mul(mul(U , float2x2(A, -A.y, A.x) )),  float2x2(2,0,1,1.7)); 

	U = abs(mul(mul(U, float2x2(A.x, A.y, -A.y, A.x) ), float2x2(2,0,1,1.7) ) );

  //  return .2/max(U.x,U.y);                      // glowing-spiky approx of step(max,.2)

  return .2*pow(max(U.x,U.y), -2.);
 
}

float	distfunc(float3 p)
{
	float	ret;

//	p = abs(p);

	ret = (length(p) );//max(max(abs(p.x),abs(p.y)),abs(p.z));

float minl;
float3	b = float3(.075, .075, .075);
	minl = max(max(abs(p.x)+.5*abs(p.y)-b.x, abs(p.y)+.5*abs(p.z)-b.y), abs(p.z)+.5*abs(p.x)-b.z);
ret = minl;
	return ret;
}


        const float PI = 3.14159;

        half4 frag (v2f IN) : SV_Target
        {
            half3 col = half3(0.0, 0.0, 0.0);
			float3 eyeRay = camera(IN.uv);//normalize(mul((float3x3)unity_ObjectToWorld, IN.pos.xyz));

float3	cameraPos = float3(0,0,0);
float3	far = float3(0,0,0);
float3	pos;

                // Calculate the ray's starting position, then calculate its scattering offset


			float2	dist = float2(0,0);
			//float3	tex = float3(1.,1.,1.)*tex2Dlod (_sam, float4(-normalize(eyeRay).xyz*3.+1.,.0));//tex2D(_sam, float2(0.,0.) ).xyz;
			float	h = 0;
float	g = 0.;
float	id = 0.;
float3	col_o;


			col    = float4(0.,0.,0.,0.);
//			dist = abs(dist);
			col = 1.*h*float4(.3+abs(sin(id+dist.x*0.)), .5, .7, 1.)*.1*0.+1.*float4(.2, .5, .7, 1.)*id/50.;//*( 1.*dist.x*.1+dist.y*.1*0.);//*.000041);

//			col = _intensity*h*float3(abs(sin(_Time.x+1.04+g)), abs(sin(_Time.x+2.09+g)), abs(sin(_Time.x+3.14+g)))*dist.y;

			float2	u = IN.uv;


//			return half4(normalize(IN.vertex) * .5 + .5, 1);

float3 n = normalize(IN.vertex) * .5 + .5;//normalize(IN.vertex);
//float r = atan2(n.x, n.z) / (2*PI) + 0.5;
//float v = n.y * 0.5 + 0.5;

//			return half4(r, v, 1, 1);
			float3	idd = floor(n*_intensity);
			n = frac(n*_intensity)-.5;
			float	randomed= my_rand(idd+_var);
			float	dst = 10.*(.25-.97*randomed-distfunc(n) );
			col_o.x = dst //+.1/(dst*dst+.1)
			*1.;
			col_o.xyz = col_o.xxx * float3(.85+.5*abs(sin(randomed*PI*2.+1.04)), .85+.5*abs(sin(randomed*PI*2.+0.0) ), .85+.5*abs(sin(randomed*PI*2.+2.08)) );
			col = col_o;//+flare(n.xyz);

            return half4(col,1.0);

        }
        ENDCG
    }
}

}
