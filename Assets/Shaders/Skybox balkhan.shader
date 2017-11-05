// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Skybox/Procedural" {
Properties {
    [KeywordEnum(None, Simple, High Quality)] _SunDisk ("Sun", Int) = 2
    _SunSize ("Sun Size", Range(0,1)) = 0.04
    _SunSizeConvergence("Sun Size Convergence", Range(1,10)) = 5

    _AtmosphereThickness ("Atmosphere Thickness", Range(0,5)) = 1.0
    _SkyTint ("Sky Tint", Color) = (.5, .5, .5, 1)
    _GroundColor ("Ground", Color) = (.369, .349, .341, 1)

    _Exposure("Exposure", Range(0, 8)) = 1.3

	_sam ("Texture", 2D) = "white" { }

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

    #if defined(UNITY_COLORSPACE_GAMMA)
        #define GAMMA 2
        #define COLOR_2_GAMMA(color) color
        #define COLOR_2_LINEAR(color) color*color
        #define LINEAR_2_OUTPUT(color) sqrt(color)
    #else
        #define GAMMA 2.2
        // HACK: to get gfx-tests in Gamma mode to agree until UNITY_ACTIVE_COLORSPACE_IS_GAMMA is working properly
        #define COLOR_2_GAMMA(color) ((unity_ColorSpaceDouble.r>2.0) ? pow(color,1.0/GAMMA) : color)
        #define COLOR_2_LINEAR(color) color
        #define LINEAR_2_LINEAR(color) color
    #endif

        // RGB wavelengths
        // .35 (.62=158), .43 (.68=174), .525 (.75=190)
        static const float3 kDefaultScatteringWavelength = float3(.65, .57, .475);
        static const float3 kVariableRangeForScatteringWavelength = float3(.15, .15, .15);

        #define OUTER_RADIUS 1.025
        static const float kOuterRadius = OUTER_RADIUS;
        static const float kOuterRadius2 = OUTER_RADIUS*OUTER_RADIUS;
        static const float kInnerRadius = 1.0;
        static const float kInnerRadius2 = 1.0;

        static const float kCameraHeight = 0.0001;

        #define kRAYLEIGH (lerp(0.0, 0.0025, pow(_AtmosphereThickness,2.5)))      // Rayleigh constant
        #define kMIE 0.0010             // Mie constant
        #define kSUN_BRIGHTNESS 20.0    // Sun brightness

        #define kMAX_SCATTER 50.0 // Maximum scattering value, to prevent math overflows on Adrenos

        static const half kHDSundiskIntensityFactor = 15.0;
        static const half kSimpleSundiskIntensityFactor = 27.0;

        static const half kSunScale = 400.0 * kSUN_BRIGHTNESS;
        static const float kKmESun = kMIE * kSUN_BRIGHTNESS;
        static const float kKm4PI = kMIE * 4.0 * 3.14159265;
        static const float kScale = 1.0 / (OUTER_RADIUS - 1.0);
        static const float kScaleDepth = 0.25;
        static const float kScaleOverScaleDepth = (1.0 / (OUTER_RADIUS - 1.0)) / 0.25;
        static const float kSamples = 2.0; // THIS IS UNROLLED MANUALLY, DON'T TOUCH

        #define MIE_G (-0.990)
        #define MIE_G2 0.9801

        #define SKY_GROUND_THRESHOLD 0.02

        // fine tuning of performance. You can override defines here if you want some specific setup
        // or keep as is and allow later code to set it according to target api

        // if set vprog will output color in final color space (instead of linear always)
        // in case of rendering in gamma mode that means that we will do lerps in gamma mode too, so there will be tiny difference around horizon
        // #define SKYBOX_COLOR_IN_TARGET_COLOR_SPACE 0

        // sun disk rendering:
        // no sun disk - the fastest option
        #define SKYBOX_SUNDISK_NONE 0
        // simplistic sun disk - without mie phase function
        #define SKYBOX_SUNDISK_SIMPLE 1
        // full calculation - uses mie phase function
        #define SKYBOX_SUNDISK_HQ 2

        // uncomment this line and change SKYBOX_SUNDISK_SIMPLE to override material settings
        // #define SKYBOX_SUNDISK SKYBOX_SUNDISK_SIMPLE

        #ifndef SKYBOX_SUNDISK
            #if defined(_SUNDISK_NONE)
                #define SKYBOX_SUNDISK SKYBOX_SUNDISK_NONE
            #elif defined(_SUNDISK_SIMPLE)
                #define SKYBOX_SUNDISK SKYBOX_SUNDISK_SIMPLE
            #else
                #define SKYBOX_SUNDISK SKYBOX_SUNDISK_HQ
            #endif
        #endif

        #ifndef SKYBOX_COLOR_IN_TARGET_COLOR_SPACE
            #define SKYBOX_COLOR_IN_TARGET_COLOR_SPACE 0
        #endif

        // Calculates the Rayleigh phase function
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
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct v2f
        {
            float4  pos             : SV_POSITION;

        //#if SKYBOX_SUNDISK == SKYBOX_SUNDISK_HQ
            // for HQ sun disk, we need vertex itself to calculate ray-dir per-pixel
            half3   vertex          : TEXCOORD0;
 //       #elif SKYBOX_SUNDISK == SKYBOX_SUNDISK_SIMPLE
 //       #else
            // as we dont need sun disk we need just rayDir.y (sky/ground threshold)
//            half    skyGroundFactor : TEXCOORD0;
//        #endif

            // calculate sky colors in vprog
            half3   groundColor     : TEXCOORD1;
            half3   skyColor        : TEXCOORD2;

        #if SKYBOX_SUNDISK != SKYBOX_SUNDISK_NONE
            half3   sunColor        : TEXCOORD3;
        #endif

            UNITY_VERTEX_OUTPUT_STEREO
        };


        float scale(float inCos)
        {
            float x = 1.0 - inCos;
        #if defined(SHADER_API_N3DS)
            // The polynomial expansion here generates too many swizzle instructions for the 3DS vertex assembler
            // Approximate by removing x^1 and x^2
            return 0.25 * exp(-0.00287 + x*x*x*(-6.80 + x*5.25));
        #else
            return 0.25 * exp(-0.00287 + x*(0.459 + x*(3.83 + x*(-6.80 + x*5.25))));
        #endif
        }

float3	camera(float2 uv)
{
    float   fov = 1.;
	float3    forw  = float3(0.0, 0.0, -1.0);
	float3    right = float3(1.0, 0.0, 0.0);
	float3    up    = float3(0.0, 1.0, 0.0);

    return (normalize((uv.x) * right + (uv.y) * up + fov * forw));
}

        v2f vert (appdata_t v)
        {
            v2f OUT;
            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
            OUT.pos = UnityObjectToClipPos(v.vertex);

            float3 kSkyTintInGammaSpace = COLOR_2_GAMMA(_SkyTint); // convert tint from Linear back to Gamma
            float3 kScatteringWavelength = lerp (
                kDefaultScatteringWavelength-kVariableRangeForScatteringWavelength,
                kDefaultScatteringWavelength+kVariableRangeForScatteringWavelength,
                half3(1,1,1) - kSkyTintInGammaSpace); // using Tint in sRGB gamma allows for more visually linear interpolation and to keep (.5) at (128, gray in sRGB) point
            float3 kInvWavelength = 1.0 / pow(kScatteringWavelength, 4);

            float kKrESun = kRAYLEIGH * kSUN_BRIGHTNESS;
            float kKr4PI = kRAYLEIGH * 4.0 * 3.14159265;

            float3 cameraPos = float3(0,kInnerRadius + kCameraHeight,0);    // The camera's current position

            // Get the ray from the camera to the vertex and its length (which is the far point of the ray passing through the atmosphere)
            float3 eyeRay = normalize(mul((float3x3)unity_ObjectToWorld, v.vertex.xyz));

            float far = 0.0;
            half3 cIn, cOut;

                // Sky
                // Calculate the length of the "atmosphere"
                far = sqrt(kOuterRadius2 + kInnerRadius2 * eyeRay.y * eyeRay.y - kInnerRadius2) - kInnerRadius * eyeRay.y;

                float3 pos = cameraPos + far * eyeRay;

                // Calculate the ray's starting position, then calculate its scattering offset
                float height = kInnerRadius + kCameraHeight;
                float depth = exp(kScaleOverScaleDepth * (-kCameraHeight));
                float startAngle = dot(eyeRay, cameraPos) / height;
                float startOffset = depth*scale(startAngle);



			float2	dist = float2(0,0);
			float3	tex = float3(1.,1.,1.)*tex2Dlod (_sam, float4(-normalize(eyeRay).xyz*3.+1.,.0));//tex2D(_sam, float2(0.,0.) ).xyz;
			float	h = 0;

float	id = 0.;
			for(float i = -16.; i < 0; i++)
			{
				pos += startOffset*0. +0.*float3(cos(tex.x*1.+6.28*i/50.+_Time.x*.01), sin(tex.y*1.+6.28*i/50.+_Time.x*.01)*1., -sin(tex.z*1.+6.28*i/50.+_Time.x*.01+.5))*.51 
				+ (eyeRay.xyz)*(dist.y*dist.x);

				//pos = abs(pos)-5.5; // comment this line for best fog (it cost fps ... or not depending on the app mem left, I have a feeling something's leaking)
				pos.zxy = frac(pos.zxy*.1)-.5;
				pos *= 5.;
				pos = abs(pos)-2.;
				pos.zxy = frac(pos.yxz*.1)-.5;
				pos *= 5.;
				pos = abs(pos)-1.;
				dist.x = length( ( ((pos-tex*1.1) ) )*1. )-.00001;//-5.1*tex.x;
				dist.y += dist.x;
				h += exp(-dist.y*.051)*5.51/(dist.y*.51+dist.x*dist.x+.001);
				if ( abs(dist.x) < .1)
				{
			//		dist.y = 1e5;
					break;
				}
				id++;
			}


			OUT.skyColor    = float4(0.,0.,0.,0.);
//			dist = abs(dist);
			OUT.skyColor = h*float4(.3+abs(sin(id+dist.y)), .5, .7, 1.)*.1-10.*float4(.2, .5, .7, 1.)*( 1.*dist.x-dist.y*.000001);//*.000041);
//			OUT.skyColor/=20.;
//			OUT.skyColor = -OUT.skyColor;
//			OUT.skyColor *= (OUT.skyColor>= 2.?0.:1.);

        #if defined(UNITY_COLORSPACE_GAMMA) && SKYBOX_COLOR_IN_TARGET_COLOR_SPACE
            OUT.groundColor = sqrt(OUT.groundColor);
            OUT.skyColor    = sqrt(OUT.skyColor);
            #if SKYBOX_SUNDISK != SKYBOX_SUNDISK_NONE
                OUT.sunColor= sqrt(OUT.sunColor);
            #endif
        #endif

            return OUT;
        }

        half4 frag (v2f IN) : SV_Target
        {
            half3 col = half3(0.0, 0.0, 0.0);

            // if we did precalculate color in vprog: just do lerp between them
            col = IN.skyColor;//col = lerp(IN.skyColor, IN.groundColor, saturate(y));
/*
float3 pos = (UnityObjectToClipPos(IN.pos.xyz-0.));//eyeRay.z += 300.;eyeRay.x += 200;
//IN.pos.xyz-200.;//normalize(UnityObjectToClipPos(IN.pos.xyz-0.));//normalize(mul((float3x3)UNITY_MATRIX_MVP, IN.pos.xyz-2000.));
//		eyeRay = camera(eyeRay.xy);//normalize(mul((float3x3)unity_ObjectToWorld, v.vertex.xyz));
float3	eyeRay = camera(pos.xy);
				float height = kInnerRadius + kCameraHeight;
                float depth = exp(kScaleOverScaleDepth * (-kCameraHeight));
                float startAngle = dot(eyeRay, 1.+float3(0.,0.,0.) ) / height;
                float startOffset = depth*scale(startAngle);



			float2	dist = float2(0,0);
			float3	tex = float3(1.,1.,1.)*tex2Dlod (_sam, float4(-normalize(eyeRay).xyz,.0));//tex2D(_sam, float2(0.,0.) ).xyz;
			float	h = 0;
			float3	p;
			for(float i = -150.; i < 0; i++)
			{
				p = 0.*startOffset*1.
				 +0.*float3(cos(tex.x*1.+6.28*i/50.+_Time.x*.01*0.), sin(tex.y*1.+6.28*i/50.+_Time.x*.01*0.)*1., -sin(tex.z*1.+6.28*i/50.+_Time.x*.01*0.+.5))*.51
				 + pos + normalize(eyeRay.xyz)*(dist.y);

				//pos.z = frac(pos.z*30.)-.5;
				//pos *= 30.;
				dist.x = length( ( ((p-tex*0.1*0.) ) )*1. )-1.0;//-5.1*tex.x;
//				dist.x = max(abs(dist.x), .002);
				dist.y += dist.x;
				h += .51/(dist.x*dist.x+0.*1.51);
				if ((dist.x) < .1)
				{
					dist.y = 0.;
//					dist.y = 1e3;
					break;
				}
			}
		col = h*float3(.3, .5, .7)*.1*0.+float3(.2, .5, .7)*( 1.*dist.x*.0000000051+0.*dist.y*.000041);
*/

//		col.x += step(1000.1+_Time.x*400.1, length(eyeRay*5.)-1.)*step(length(eyeRay*5.)-1., 1100.+_Time.x*40.1);
//		col.y += step(1000.1+_Time.x*400.1, length(eyeRay.xz*5.)-1.)*step(length(eyeRay.xz*5.)-1., 1100.1+_Time.x*400.1);


        #if defined(UNITY_COLORSPACE_GAMMA) && !SKYBOX_COLOR_IN_TARGET_COLOR_SPACE
            col = LINEAR_2_OUTPUT(col);
        #endif

            return half4(col,1.0);

        }
        ENDCG
    }
}

}
