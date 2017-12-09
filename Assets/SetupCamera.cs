using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Cinemachine;

public class SetupCamera : MonoBehaviour
{
	CinemachineVirtualCamera	virtualCamera;
	CinemachinePath				path;

	void Start ()
	{
		virtualCamera = GetComponent< CinemachineVirtualCamera >();
		path = FindObjectOfType< CinemachinePath >();

	}
	
}
