using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class RaymarchedPlanet : MonoBehaviour {

	Material		material;

	// Use this for initialization
	void Start () {
		material = GetComponent< MeshRenderer >().sharedMaterial;
	}
	
	// Update is called once per frame
	void Update () {
		material.SetVector("_ObjectCenter", transform.position);
	}
}
