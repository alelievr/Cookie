using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class Explosion : MonoBehaviour
{
	public GameObject	explosionPrefab;
	public float		explosionPower = 10;
	public bool			explode = false;

	List< Rigidbody > objectsInsideExplosion = new List< Rigidbody >();

	void Start ()
	{
	}
	
	void Update ()
	{
		if (explode || Input.GetKeyDown(KeyCode.E))
			Explode();
		
		if (Input.GetKeyDown(KeyCode.R))
			SceneManager.LoadScene(SceneManager.GetActiveScene().name);
	}

	void OnTriggerEnter(Collider other)
	{
		if (other.tag == "Explodable")
			objectsInsideExplosion.Add(other.GetComponent< Rigidbody >());
	}

	void OnTriggerExit(Collider other)
	{
		if (other.tag == "Explodable")
			objectsInsideExplosion.Remove(other.GetComponent< Rigidbody >());
	}

	void Explode()
	{
		Vector3 explosionPosition = new Vector3(transform.position.x, transform.position.y, transform.position.z);
		GameObject explosion = GameObject.Instantiate(explosionPrefab, explosionPosition, Quaternion.identity) as GameObject;
		Destroy(explosion, 5);

		foreach (var obj in objectsInsideExplosion)
		{
			Vector3 direction = (obj.transform.position - transform.position);
			float dist = direction.magnitude;
			obj.AddForceAtPosition(direction * (1 / (dist * dist + .1f)) * explosionPower, transform.position, ForceMode.Impulse);
		}
		explode = false;
	}
}
