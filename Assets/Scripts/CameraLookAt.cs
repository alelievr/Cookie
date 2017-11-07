using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraLookAt : MonoBehaviour {

	public GameObject	lookat;
	public float		speed = 1;

	float length;

	// Use this for initialization
	void Start () {
		length = (transform.position - lookat.transform.position).magnitude;
	}
	
	// Update is called once per frame
	void FixedUpdate () {
		
		transform.LookAt(lookat.transform);

		transform.position = lookat.transform.position + new Vector3(Mathf.Sin(Time.time * speed), 0, Mathf.Cos(Time.time * speed)) * length;

	}
}
