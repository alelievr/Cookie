using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class RaymarchedPlanet : MonoBehaviour {

	MeshRenderer	meshRenderer;

	// Use this for initialization
	void Start () {
		meshRenderer = GetComponent< MeshRenderer >();
	}
	
	// Update is called once per frame
	void Update () {
		foreach (var material in meshRenderer.sharedMaterials)
		{
			material.SetVector("_ObjectCenter", transform.position);
			material.SetVector("_LocalScale", transform.localScale);
		}
	}
}
