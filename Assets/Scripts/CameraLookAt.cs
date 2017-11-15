using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraLookAt : MonoBehaviour {

	public GameObject	lookat;
	public float		yOffset = 0;
	public float		yLookAtOffset = 0;
	public float		speed = 1;

	float length;

	// Use this for initialization
	void Start () {
		length = (transform.position - lookat.transform.position).magnitude;
	}
	
	// Update is called once per frame
	void FixedUpdate () {
		
		lookat.transform.position += Vector3.up * yLookAtOffset;
		transform.LookAt(lookat.transform);
		lookat.transform.position -= Vector3.up * yLookAtOffset;

		transform.position = lookat.transform.position + new Vector3(Mathf.Sin(Time.time * speed), yOffset, Mathf.Cos(Time.time * speed)) * length;

	}
}
