using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class HyperSpaceTunnel : MonoBehaviour
{
	public Text				finalText;
	public ParticleSystem	outSystem;
	public Image			fadeImage;
	public AnimationCurve	fadeCurve;
	public GameObject		plexus;
	public float			outTime = 5.5f;
	public float			outFadeTime = .9f;
	public float			fadeTime = 1;

	ParticleSystem[]		mySystems;

	void Start()
	{
		mySystems = GetComponentsInChildren< ParticleSystem >();
		outSystem.gameObject.SetActive(false);
		StartCoroutine(HyperSpaceOut());
		StartCoroutine(FinalFade());
		StartCoroutine(DisplayPlexus());

		plexus.SetActive(false);
	}

	IEnumerator Fade(bool @in)
	{
		float t = Time.timeSinceLevelLoad;
		Color fadeColor = fadeImage.color;
		Color textColor = finalText.color;

		while (t + fadeTime > Time.timeSinceLevelLoad)
		{
			float d = Time.timeSinceLevelLoad - t;
			fadeColor.a = fadeCurve.Evaluate((@in) ? d : 1 - d);
			textColor.a = fadeColor.a;
			fadeImage.color = fadeColor;
			finalText.color = textColor;
			yield return new WaitForEndOfFrame();
		}
		fadeColor.a = (@in) ? 1 : 0;
		fadeImage.color = fadeColor;
	}

	IEnumerator FinalFade()
	{
		yield return new WaitForSeconds(250);

		finalText.enabled = true;
		finalText.color = new Color(0, 0, 0, 0);
		yield return Fade(true);
	}

	IEnumerator DisplayPlexus()
	{
		yield return new WaitForSeconds(200);

		plexus.SetActive(true);
	}

	IEnumerator HyperSpaceOut()
	{
		yield return new WaitForSeconds(outTime);

		//activate the hyperspace out particle system

		outSystem.gameObject.SetActive(true);

		yield return new WaitForSeconds(outFadeTime);

		//white fade screen
		yield return Fade(true);

		//disable hyperspace particles
		foreach (var p in mySystems)
			p.gameObject.SetActive(false);

		//set camera skybox:
		Camera.main.clearFlags = CameraClearFlags.Skybox;

		//screen back to normal
		yield return Fade(false);
	}
}
