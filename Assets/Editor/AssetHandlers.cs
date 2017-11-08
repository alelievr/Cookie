using UnityEditor;
using UnityEngine;
using System.Reflection;

public class AssetHandler
{
	static string shaderTemplatePath = "Assets/Shaders/Planets/StandardPlanetShaderTemplate.txt";

	[MenuItem("Assets/Create/Shader/Standard Planet", false, -10)]
	public static void CreateSTandardPlanetShader()
	{
		string path = "Assets/Shaders/Planets/Standard.shader";

		MethodInfo methodInfo = typeof(ProjectWindowUtil).GetMethod("CreateScriptAsset", BindingFlags.Static | BindingFlags.NonPublic);

		methodInfo.Invoke(null, new object[]{shaderTemplatePath, path});
	}
}