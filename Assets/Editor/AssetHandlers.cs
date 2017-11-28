using UnityEditor;
using UnityEngine;
using System.Reflection;

public class AssetHandler
{
	static string surfaceTemplatePath = "Assets/Shaders/Planets/StandardPlanetSurfaceShaderTemplate.txt";
	static string underGroundTemplatePath = "Assets/Shaders/Planets/StandardPlanetUndergroundShaderTemplate.txt";

	[MenuItem("Assets/Create/Shader/Standard Planet Surface", false, -10)]
	public static void CreateStandardSurfacePlanetShader()
	{
		string path = "Assets/Shaders/Planets/Standard Surface.shader";

		MethodInfo methodInfo = typeof(ProjectWindowUtil).GetMethod("CreateScriptAsset", BindingFlags.Static | BindingFlags.NonPublic);

		methodInfo.Invoke(null, new object[]{surfaceTemplatePath, path});
	}
	
	[MenuItem("Assets/Create/Shader/Standard Planet Underground", false, -10)]
	public static void CreateStandardUndergroundPlanetShader()
	{
		string path = "Assets/Shaders/Planets/Standard Underground.shader";

		MethodInfo methodInfo = typeof(ProjectWindowUtil).GetMethod("CreateScriptAsset", BindingFlags.Static | BindingFlags.NonPublic);

		methodInfo.Invoke(null, new object[]{underGroundTemplatePath, path});
	}
}