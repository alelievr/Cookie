using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class RaymarchedPlanet : MonoBehaviour
{

	MeshRenderer	meshRenderer;

	void Start ()
	{
		meshRenderer = GetComponent< MeshRenderer >();
	}
	
	void Update ()
	{
		foreach (var material in meshRenderer.sharedMaterials)
		{
			material.SetVector("_ObjectCenter", transform.position);
			material.SetVector("_LocalScale", transform.localScale);
			if (AudioManager.instance != null)
				material.SetFloat("_SoundVolume", AudioManager.instance.GetMainVolume());
		}
	}
}
