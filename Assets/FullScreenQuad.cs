using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FullScreenQuad : MonoBehaviour {

	Camera		camera;

	// Use this for initialization
	void Start () {
		camera = Camera.main;
	}
	
	// Update is called once per frame
	void Update () {
		float	pos = (camera.nearClipPlane + 0.01f);
		float h = Mathf.Tan(camera.fieldOfView * Mathf.Deg2Rad * .5f) * pos * 2f;
		transform.localScale = new Vector3(h * camera.aspect, h, 0);
	}
}
