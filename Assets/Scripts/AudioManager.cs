using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Audio;

public class AudioManager : MonoBehaviour
{
	public AudioMixer		mixer;

	public AnimationCurve	hyperspaceBackgroundFadeCurve;
	public AnimationCurve	hyperSpaceExitFadeCurve;
	public AnimationCurve	backgroundStartCurve;

	public AudioSource		hyperspaceBackground;
	public AudioSource		hyperspaceExit;
	public AudioSource		background;

	public float			startBackgroundMusicBefore = 6;

	bool					playingExit = false;

	void Start ()
	{
		StartCoroutine(startbackgroundMusic());
	}

	IEnumerator startbackgroundMusic()
	{
		yield return new WaitForSeconds(startBackgroundMusicBefore);

		background.Play();
		
		float t = Time.time;
		while (true)
		{
			float f = backgroundStartCurve.Evaluate(Time.time - t);

			if (f >= 1)
				yield break ;
			
			mixer.SetFloat("Background", LinearToDecibel(f));
			yield return new WaitForEndOfFrame();
		}
	}

    private float LinearToDecibel(float linear)
    {
        float dB;

        if (linear != 0)
            dB = 20.0f * Mathf.Log10(linear);
        else
            dB = -144.0f;

        return dB;
    }
	
	void Update ()
	{
		float backgroundLevel = hyperspaceBackgroundFadeCurve.Evaluate(Time.timeSinceLevelLoad);
		float exitLevel = hyperSpaceExitFadeCurve.Evaluate(Time.timeSinceLevelLoad);

		if (exitLevel > 0 && !playingExit)
		{
			Debug.Log("PLay");
			hyperspaceExit.Play();
			playingExit = true;
		}

		mixer.SetFloat("HyperSpaceBackground", LinearToDecibel(backgroundLevel));
		mixer.SetFloat("HyperSpaceExit", LinearToDecibel(exitLevel));
	}
}
