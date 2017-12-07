using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Audio;

public class AudioManager : MonoBehaviour
{
	public static AudioManager		instance;

	public AudioMixer		mixer;

	public AnimationCurve	hyperspaceBackgroundFadeCurve;
	public AnimationCurve	hyperSpaceExitFadeCurve;
	public AnimationCurve	backgroundStartCurve;

	public AudioSource		hyperspaceBackground;
	public AudioSource		hyperspaceExit;
	public AudioSource		background;

	public float			startBackgroundMusicBefore = 6;

	bool					playingExit = false;

	float[]					audioSamples = new float[512];
	float					audioVolume;

	public float[]			frequencyBand = new float[8];
	public float[]			bandBuffer = new float[8];
	float[]				bufferDecrease = new float[8];

	void Awake()
	{
		instance = this;
	}

	void Start ()
	{
		StartCoroutine(startBackgroundMusic());
	}

	IEnumerator startBackgroundMusic()
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
			hyperspaceExit.Play();
			playingExit = true;
		}

		mixer.SetFloat("HyperSpaceBackground", LinearToDecibel(backgroundLevel));
		mixer.SetFloat("HyperSpaceExit", LinearToDecibel(exitLevel));

        AudioListener.GetSpectrumData(audioSamples, 0, FFTWindow.Blackman);
		GetFrequencyBand(audioSamples);
		GetBandBuffer();

		float m = 0;
		foreach (var f in bandBuffer)
			m += f / 8;

		audioVolume = m;
	}
	
	void GetFrequencyBand(float[] samples)
	{
		int	count = 0;

		for (int i = 0; i < frequencyBand.Length; i++)
		{
			float average = 0;
			int sampleCount = (int)Mathf.Pow(2, i) * 2;

			if (i == frequencyBand.Length - 1)
				sampleCount += 2;
			
			for (int j = 0; j < sampleCount; j++)
			{
				average += samples[count] * (count + 1);
				count++;
			}

			average /= count;
			frequencyBand[i] = average * 10;
		}
	}
	
	void GetBandBuffer()
	{
		for (int i = 0; i < bandBuffer.Length; i++)
		{
			if (frequencyBand[i] > bandBuffer[i])
			{
				bandBuffer[i] = frequencyBand[i];
				bufferDecrease[i] = 0.05f;
			}

			if (frequencyBand[i] < bandBuffer[i])
			{
				bandBuffer[i] -= bufferDecrease[i];
				bufferDecrease[i] *= 1.2f;
			}
		}
	}

	public float GetMainVolume()
	{
		return audioVolume;
	}
}
