using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Profiling;

[RequireComponent(typeof(ParticleSystem))]
public class PlexusParticle : MonoBehaviour
{

	public float				maxDistance = .1f;
	public int					maxConnections = 5;
	public int					maxLineRenderers = 100;
	public Gradient				colorDisatnceGradient;
	public LineRenderer			lineRenderer;

	new ParticleSystem			particleSystem;
	ParticleSystem.Particle[]	particles;

	ParticleSystem.MainModule	mainModule;

	List< LineRenderer >		lineRenderers = new List< LineRenderer >();

	void Start ()
	{
		particleSystem = GetComponent< ParticleSystem >();
		mainModule = particleSystem.main;
	}
	
	void LateUpdate ()
	{
		int	maxParticles = mainModule.maxParticles;

		if (particles == null || particles.Length != maxParticles)
			particles = new ParticleSystem.Particle[maxParticles];
			
		int	lrIndex = 0;

		if (maxConnections == 0 || maxLineRenderers == 0)
			return ;
		
		particleSystem.GetParticles(particles);

		int particleCount = particleSystem.particleCount;

		float maxDistanceSqrt = maxDistance  * maxDistance;

		int	lineRendererCout = lineRenderers.Count;

		Profiler.BeginSample("Plexus calcul");

		for (int i = 0; i < particleCount; i++)
		{

			Vector3	p1 = particles[i].position;
			int		connections = 0;
			
			for (int j = i + 1; j < particleCount; j++)
			{
				if (lrIndex > maxLineRenderers)
					break ;
				
				Vector3 p2 = particles[j].position;

				float distanceSqrt = Vector3.SqrMagnitude(p1 - p2);

				if (distanceSqrt <= maxDistanceSqrt)
				{
					LineRenderer lr;
					if (lrIndex == lineRendererCout)
					{
						lr = Instantiate(lineRenderer, transform, false);
						lineRenderers.Add(lr);
						lineRendererCout++;
					}

					lr = lineRenderers[lrIndex];

					Color col = colorDisatnceGradient.Evaluate(distanceSqrt / maxDistanceSqrt);

					lr.startColor = col;
					lr.endColor = col;

					lr.enabled = true;

					lr.SetPosition(0, p1);
					lr.SetPosition(1, p2);

					lrIndex++;
					connections++;
				}

				if (connections >= maxConnections)
					break ;
			}
		}

		for (int i = lrIndex; i < lineRenderers.Count; i++)
			lineRenderers[i].enabled = false;

		Profiler.EndSample();

	}
}
