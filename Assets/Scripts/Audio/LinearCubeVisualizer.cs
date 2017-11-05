using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LinearCubeVisualizer : MonoBehaviour
{
	public AudioSpectrum		audioSpectrum;
	public GameObject			visu;

	GameObject[]				frequencyVisus = new GameObject[AudioSpectrum.fSamples];
	GameObject[]				bandVisus = new GameObject[AudioSpectrum.fSamples];

	void Start ()
	{
		for (int i = 0; i < frequencyVisus.Length; i++)
		{
			frequencyVisus[i] = GameObject.Instantiate(visu);
			frequencyVisus[i].transform.position = new Vector3(i * .4f, 0, 1);
			bandVisus[i] = GameObject.Instantiate(visu);
			bandVisus[i].transform.position = new Vector3(i * .4f, 0, 0);
		}
	}
	
	void Update ()
	{
		for (int i = 0; i < frequencyVisus.Length; i++)
		{
			frequencyVisus[i].transform.localScale = new Vector3(.2f, audioSpectrum.frequencyBand[i], .2f);
			bandVisus[i].transform.localScale = new Vector3(.2f, audioSpectrum.bandBuffer[i], .2f);
		}
	}
}
