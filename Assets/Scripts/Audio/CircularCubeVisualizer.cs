using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CircularCubeVisualizer : MonoBehaviour
{
	public AudioSpectrum	audioSpectrum;
	public GameObject		visu;

	Transform		root;
	GameObject[]	vizs = new GameObject[512];

	void Start()
	{
		root = new GameObject("AudioVizRoot").transform;

		for (int i = 0; i < vizs.Length; i++)
		{
			var g = vizs[i] = GameObject.Instantiate(visu);
			g.transform.parent = root;
			g.transform.eulerAngles = new Vector3(0, (360f / vizs.Length) * i, 0);
			g.transform.position = g.transform.forward * 20;
		}
	}
	
	// Update is called once per frame
	void Update ()
	{
		for (int i = 0; i < 512; i++)
		{
			var viz = vizs[i];
			viz.transform.localScale = new Vector3(.2f, audioSpectrum.samples[i] * 50, .2f);
		}
	}
}
