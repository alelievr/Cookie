using UnityEditor;
using UnityEngine;
using System.Reflection;

public class AssetHandler
{
	static string shadertoy3DTemplate = "Assets/Shaders/Planets/Shadertoy3DShaderTemplate.txt";

	[MenuItem("Assets/Create/Shader/Shadertoy3D shader", false, -10)]
	public static void CreateStandardUndergroundPlanetShader()
	{
		string path = "Assets/Shaders/Planets/Shadertoy3DObject.shader";

		MethodInfo methodInfo = typeof(ProjectWindowUtil).GetMethod("CreateScriptAsset", BindingFlags.Static | BindingFlags.NonPublic);

		methodInfo.Invoke(null, new object[]{shadertoy3DTemplate, path});
	}
}