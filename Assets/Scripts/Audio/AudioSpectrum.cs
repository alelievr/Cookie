using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(AudioSource))]
public class AudioSpectrum : MonoBehaviour
{
	public const int	fSamples = 8;

	AudioSource			audioSource;
	public float[]		samples = new float[1024];
	public float[]		frequencyBand = new float[fSamples];
	public float[]		bandBuffer = new float[fSamples];
	float[]				bufferDecrease = new float[fSamples];

	void Start()
	{
		audioSource = GetComponent< AudioSource >();
	}

	void Update()
	{
		GetSampleDatas();
		GetFrequencyBand();
		BandBuffer();
	}

	void GetSampleDatas()
	{
		audioSource.GetSpectrumData(samples, 0, FFTWindow.Blackman);
	}

	void GetFrequencyBand()
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

	void BandBuffer()
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

}
