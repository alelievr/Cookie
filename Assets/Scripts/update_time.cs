using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class update_time : MonoBehaviour 
{

	Material	mat;

	// Use this for initialization
	void Start () {
		mat = GetComponent<MeshRenderer>().sharedMaterial;
	}

	// Update is called once per frame
	void Update () {
		if (mat)
			mat.SetFloat("_Phase", Time.time);

	}
}
