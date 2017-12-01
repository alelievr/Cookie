Shader "Cookie/PlanetSurfaceShader"
{
	Properties
	{
		_ElevationMap ("Elevation map", 2D) = "white" {}
		_ColorMap ("Color map", 2D) = "white" {}
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

		CGPROGRAM

		#pragma surface planetSurfaceFunc Standard vertex:vertFunc nofog alpha
		
		#include "UnityCG.cginc"
		
		struct appdata
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 tangent : TANGENT;
		};

		struct Input
		{
			float3 position;
			float3 origin;
			float3 normal;
		};

		float4	_LocalScale;
		float4 	_ObjectCenter;

		sampler2D _ColorMap;
		sampler2D _ElevationMap;

		#define ITER	60
		#define EPSY	0.1
		
		void vertFunc (inout appdata v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.position = mul(v.vertex + _ObjectCenter / _LocalScale.xyz, unity_ObjectToWorld).xyz;
			o.origin = _WorldSpaceCameraPos - _ObjectCenter;
			o.normal = v.normal;
		}

		float map(float3 pos)
		{
			return length(pos) - (.99 * _LocalScale.x);
		}
		
		float pi          = 3.1415926535;
		float degrees     = 0.017453292519444;
		float inf         = 10000000000.0;
		
		float square(float x) { return x * x; }
		float pow3(float x) { return x * square(x); }
		float3 square(float3 x) { return x * x; }
		float3 pow3(float3 x) { return x * square(x); }
		float pow4(float x) { return square(square(x)); }
		float pow5(float x) { return x * square(square(x)); }
		float pow8(float x) { return square(pow4(x)); }
		float infIfNegative(float x) { return (x >= 0.0) ? x : inf; }
		
		struct Ray { float3 origin; float3 direction; };	
		struct Material { float3 color; float metal; float smoothness; };
		struct Surfel { float3 position; float3 normal; Material material; };
		struct Sphere { float3 center; float radius; Material material; };
		
		/** Analytic ray-sphere intersection. */
		bool intersectSphere(float3 C, float r, Ray R, inout float nearDistance, inout float farDistance) { float3 P = R.origin; float3 w = R.direction; float3 v = P - C; float b = 2.0 * dot(w, v); float c = dot(v, v) - square(r); float d = square(b) - 4.0 * c; if (d < 0.0) { return false; } float dsqrt = sqrt(d); float t0 = infIfNegative((-b - dsqrt) * 0.5); float t1 = infIfNegative((-b + dsqrt) * 0.5); nearDistance = min(t0, t1); farDistance  = max(t0, t1); return (nearDistance < inf); }
		
		///////////////////////////////////////////////////////////////////////////////////
		// The following are from https://www.shadertoy.com/view/4dS3Wd
		float hash(float n) { return frac(sin(n) * 1e4); }
		float hash(float2 p) { return frac(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }
		float noise(float x) { float i = floor(x); float f = frac(x); float u = f * f * (3.0 - 2.0 * f); return lerp(hash(i), hash(i + 1.0), u); }
		float noise(float2 x) { float2 i = floor(x); float2 f = frac(x); float a = hash(i); float b = hash(i + float2(1.0, 0.0)); float c = hash(i + float2(0.0, 1.0)); float d = hash(i + float2(1.0, 1.0)); float2 u = f * f * (3.0 - 2.0 * f); return lerp(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y; }
		float noise(float3 x) { const float3 step = float3(110, 241, 171); float3 i = floor(x); float3 f = frac(x); float n = dot(i, step); float3 u = f * f * (3.0 - 2.0 * f); return lerp(lerp(lerp( hash(n + dot(step, float3(0, 0, 0))), hash(n + dot(step, float3(1, 0, 0))), u.x), lerp( hash(n + dot(step, float3(0, 1, 0))), hash(n + dot(step, float3(1, 1, 0))), u.x), u.y), lerp(lerp( hash(n + dot(step, float3(0, 0, 1))), hash(n + dot(step, float3(1, 0, 1))), u.x), lerp( hash(n + dot(step, float3(0, 1, 1))), hash(n + dot(step, float3(1, 1, 1))), u.x), u.y), u.z); }
		
		#define DEFINE_FBM(name, OCTAVES) float name(float3 x) { float v = 0.0; float a = 0.5; float3 shift = float3(100, 100, 100); for (int i = 0; i < OCTAVES; ++i) { v += a * noise(x); x = x * 2.0 + shift; a *= 0.5; } return v; }
		DEFINE_FBM(fbm3, 3)
		DEFINE_FBM(fbm5, 5)
		DEFINE_FBM(fbm6, 6)
		
		///////////////////////////////////////////////////////////////////////////////////
		
		// The red channel defines the height, but all channels
		// are used for color.
		#define elevationMap _ElevationMap
		#define colorMap _ColorMap
		
		#define verticalFieldOfView		(25.0 * degrees)
		
		// Directional light source
		#define w_i             (float3(1.0, 1.0, -0.8) / 1.6248076)
		const float3 B_i             = float3(4, 4, 4);
		
		const float3      planetCenter    = float3(0, 0, 0);
		
		// Including mountains
		const float       planetMaxRadius = 1.0;
		const float       maxMountain = 0.13;
		
		
		#define planetMinRadius (planetMaxRadius - maxMountain)
		
		float3x3 planetRotation;

		float4 tex(sampler2D samp, float2 pos)
		{
			return tex2D(samp, pos);
		}
		
		/** Returns color, coverage under world-space point wsPoint.
			e is the relative height of the surface. 
			k is the relative height of the ray
		*/
		float3 samplePlanet(float3 osPosition, out float e, out float k)
		{
			float3 s = normalize(osPosition);    
			
			// Cylindrical map coords
			float2 cylCoord = float2(atan2(s.z, -s.x) / pi, s.y * 0.5 + 0.5);
		
			// Length of osPosition = elevation
			float sampleElevation  = length(osPosition);//dot(osPosition, s);
			
			// Relative height of the sample point [0, 1]
			k = (sampleElevation - planetMinRadius) * (1.0 / maxMountain);
		
			// Use explicit MIPs, since derivatives
			// will be random based on the ray marching
			float lod = 1;
			
			// Relative height of the surface [0, 1]
			e = lerp(tex(elevationMap, cylCoord).r, tex(elevationMap, s.xz).r, abs(s.y));
			e = square((e - 0.2) / 0.8) * 2.1;
			
			// Soften glow at high elevations, using the mip chain
			// (also blurs 
			lod += k * 6.0;
			
			// Planar map for poles mixed into cylindrical map
			float3 material = lerp(tex(colorMap, cylCoord * float2(2.0, 2.0)).rgb,
								tex(colorMap, s.xz).rgb, abs(s.y));
		
			// Increase contrast
			material = pow3(material);
			
			
			// Object space height of the surface
			float surfaceElevation = lerp(planetMinRadius, planetMaxRadius, e);
		
			return material;
		}

		/** Relative to mountain range */
		float elevation(float3 osPoint) {
			float e, k;
			samplePlanet(osPoint, e, k);
			return e;
		}
		
		
		void mainImage(out float4 fragColor, in float3 dir, in float3 org) {
			// Rotate over time
			float yaw   = 0;
			float pitch = 0;
			planetRotation = 
				float3x3(cos(yaw), 0, -sin(yaw), 0, 1, 0, sin(yaw), 0, cos(yaw)) *
				float3x3(1, 0, 0, 0, cos(pitch), sin(pitch), 0, -sin(pitch), cos(pitch));
		
			// Outgoing light
			float3 L_o = 0;
			
			Surfel surfel;	
			
			Ray eyeRay;
			eyeRay.origin = org;
			eyeRay.direction = dir;
				
			float3 hitPoint;    
			float minDistanceToPlanet, maxDistanceToPlanet;
			
			bool hitBounds = intersectSphere(planetCenter, planetMaxRadius, eyeRay, minDistanceToPlanet, maxDistanceToPlanet);
			
			if (hitBounds) {
				float3 glow = float3(0, 0, 0);
				// Planet surface + atmospherics
				
				// March to surface
				const int NUM_STEPS = 250;
				
				// Total traversal should be either 25% of the thickness of the planet,
				// the distance between total, or the max mountain height
				float dt = (maxDistanceToPlanet - minDistanceToPlanet) / float(NUM_STEPS);
				float3 material = float3(0, 0, 0);
				float3 wsNormal = float3(0, 0, 0);
				float3 p;
				float coverage = 0.0;
				float e = 1.0, k = 0.0;
		
				// Take the ray to the planet's object space
				eyeRay.origin = mul((eyeRay.origin - planetCenter), planetRotation);
				eyeRay.direction = mul(eyeRay.direction, planetRotation);
				
				float3 X;
				for (int i = 0; (i < NUM_STEPS) && (coverage < 1.0); ++i) {
					// Point on the ray in object space
					X = eyeRay.origin + eyeRay.direction * (dt * float(i) + minDistanceToPlanet);
					
					// color, coverage
					p = samplePlanet(X, e, k);
					if (e > k) {
						// Hit the surface
						material = p;
						coverage = 1.0;
						
						// Surface emission
						glow += pow(p, p * 2.5 + 7.0) * 3e3;
					} else {
						// Passing through atmosphere above lava; accumulate glow
						glow += pow(p, p + 7.0) * square(square(1.0 - k)) * 25.0;
					}
				}
		
				// Planetary sphere normal
				float3 sphereNormal = normalize(mul(planetRotation, X));
					
				// Surface normal
				const float eps = 0.01;
				wsNormal = mul(planetRotation,
					normalize(float3(elevation(X + float3(eps, 0, 0)), 
									elevation(X + float3(0, eps, 0)), 
									elevation(X + float3(0, 0, eps))) - 
									e));
				
				
				wsNormal = normalize(lerp(wsNormal, sphereNormal, 0.95));
						
				// Lighting and compositing
				L_o =  lerp(L_o, material * 
					// Sun
					(max(dot(wsNormal, w_i) + 0.1, 0.0) * B_i + 
					// Rim light
					square(max(0.8 - sphereNormal.z, 0.0)) * float3(2.0, 1.5, 0.5)), coverage);
				L_o += glow;
				
				
				if (false && coverage > 0.0) {
					// Show normals
				 L_o = wsNormal * 0.5 + 0.5;
				 L_o = max(0.0, dot(wsNormal, w_i)) * float3(1, 1, 1);
				}
			}
			
			fragColor.xyz = sqrt(L_o);
			fragColor.a   = 1.0;//maxDistanceToPlanet;
		
		}
		
		void planetSurfaceFunc (Input i, inout SurfaceOutputStandard o)
		{
			float3	dir = normalize(i.position - _WorldSpaceCameraPos.xyz);
			float3	org = i.origin;
			float4	col = float4(1, 1, 1, 0);
			float	t = 0;

			o.Albedo = float3(0, 0, 0);
			o.Emission = float3(i.position);
			o.Alpha = 1;
			// return ;
			
			mainImage(col, dir, org);

			o.Albedo = col.rgb;
			o.Emission = o.Albedo;
			o.Alpha = 1;
			return ;

			for (int i = 0; i < ITER; i++)
			{
				float3 p = org + dir * t;

				float d = map(p);

				if (d < EPSY)
				{
					col = float4(0, 1, 1, 1);
					break ;
				}

				t += d;
			}


			o.Emission = col;
			o.Albedo = col;
			o.Alpha = 1;
			o.Normal = float3(0, 1, 0);
		}
		ENDCG
	}
}
